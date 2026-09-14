"""Split the family corpus migration into SQL-editor-sized, idempotent parts."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
IMPORT_DIR = ROOT / "docs" / "imports"
PART_DIR = ROOT / "server" / "supabase" / "migration_021_parts"

DOC_IDS = [
    "doc-onu-crc-sp-50",
    "doc-doctrine-mariage-senegal",
    "doc-doctrine-famille-burkina",
    "doc-these-egalite-mariage-afrique",
    "doc-these-pluralisme-justice-mossi",
    "doc-code-personnes-famille-1989",
    "doc-code-personnes-famille",
]


def q(value: str | None) -> str:
    if value is None:
        return "null"
    return "'" + value.replace("'", "''") + "'"


def arr(values: list[str]) -> str:
    if not values:
        return "array[]::text[]"
    return "array[" + ", ".join(q(value) for value in values) + "]"


def docs() -> list[dict[str, Any]]:
    return [
        json.loads((IMPORT_DIR / f"{id_}.json").read_text(encoding="utf-8"))
        for id_ in DOC_IDS
    ]


def metadata_sql(documents: list[dict[str, Any]]) -> str:
    rows = []
    for doc in documents:
        rows.append(
            "(" + ", ".join(
                [
                    q(doc["id"]), q(doc["title"]), q(doc["type"]),
                    q(doc["domain"]), q(doc.get("reference", "")),
                    q(doc.get("date_publication")), q(doc.get("status", "enVigueur")),
                    q(doc.get("summary", "")), "''", arr(doc.get("outline", [])),
                    "false", q(doc.get("official_source_name")),
                    q(doc.get("source_url")), arr(doc.get("tags", [])),
                    arr(doc.get("related_ids", [])), "now()",
                ]
            ) + ")"
        )
    return """-- 021 parts: metadata (generated, idempotent)\ninsert into public.legal_documents (\n  id, title, type, domain, reference, date_publication, status, summary,\n  full_content, outline, summary_only, official_source_name, source_url,\n  tags, related_ids, imported_at\n) values\n""" + ",\n".join(rows) + """\non conflict (id) do update set\n  title = excluded.title, type = excluded.type, domain = excluded.domain,\n  reference = excluded.reference, date_publication = excluded.date_publication,\n  status = excluded.status, summary = excluded.summary, full_content = excluded.full_content,\n  outline = excluded.outline, summary_only = excluded.summary_only,\n  official_source_name = excluded.official_source_name, source_url = excluded.source_url,\n  tags = excluded.tags, related_ids = excluded.related_ids, imported_at = excluded.imported_at;\n"""


def prose_parts(documents: list[dict[str, Any]], max_chars: int = 150_000) -> list[str]:
    parts: list[str] = []
    for doc in documents:
        content = doc.get("full_content", "")
        for offset in range(0, len(content), max_chars):
            chunk = content[offset : offset + max_chars]
            parts.append(
                "-- 021 parts: full text\n"
                f"update public.legal_documents\n"
                f"set full_content = full_content || {q(chunk)}\n"
                f"where id = {q(doc['id'])};\n"
            )
    return parts


def article_parts(documents: list[dict[str, Any]], batch_size: int = 80) -> list[str]:
    rows: list[str] = []
    for doc in documents:
        for ordinal, article in enumerate(doc.get("articles", [])):
            rows.append(
                "(" + ", ".join(
                    [
                        q(doc["id"]), str(ordinal), q(article["number"]),
                        q(article.get("heading", "")), q(article.get("body", "")),
                        arr(article.get("path", [])),
                    ]
                ) + ")"
            )
    parts: list[str] = []
    for offset in range(0, len(rows), batch_size):
        batch = rows[offset : offset + batch_size]
        parts.append(
            "-- 021 parts: article batch\n"
            "insert into public.legal_articles\n"
            "  (document_id, ord, number, heading, body, path)\n"
            "values\n" + ",\n".join(batch) + "\n"
            "on conflict (document_id, ord) do update set\n"
            "  number = excluded.number, heading = excluded.heading,\n"
            "  body = excluded.body, path = excluded.path;\n"
        )
    return parts


def main() -> None:
    PART_DIR.mkdir(parents=True, exist_ok=True)
    for old in PART_DIR.glob("*.sql"):
        old.unlink()
    documents = docs()
    contents = [metadata_sql(documents)] + prose_parts(documents) + article_parts(documents)
    manifest = []
    for index, content in enumerate(contents):
        name = f"part_{index:03d}.sql"
        (PART_DIR / name).write_text(content, encoding="utf-8")
        manifest.append({"name": name, "chars": len(content), "bytes": len(content.encode())})
    (PART_DIR / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Generated {len(manifest)} parts")
    print(f"Largest part: {max(item['bytes'] for item in manifest)} bytes")


if __name__ == "__main__":
    main()
