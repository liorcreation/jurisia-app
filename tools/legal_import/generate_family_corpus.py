"""Build the family-law corpus from the seven supplied PDF references.

This generator deliberately keeps the source PDFs in assets/legal/family and
stores the extracted/structured text in docs/imports.  It is intended to be
rerun when the source PDFs are replaced.  The 2025 code already has a reviewed
article transcription in the repository; this script normalises its metadata
and includes those 901 articles in the generated Supabase migration.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any
import unicodedata

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[2]
ASSET_DIR = ROOT / "assets" / "legal" / "family"
IMPORT_DIR = ROOT / "docs" / "imports"
MIGRATION_PATH = ROOT / "server" / "supabase" / "migration_021_family_full_corpus.sql"


def clean_lines(raw: str) -> list[str]:
    raw = unicodedata.normalize("NFKC", raw).replace("\r\n", "\n")
    raw = raw.replace("\r", "\n").replace("\x0c", "\n")
    raw = raw.replace("\u00a0", " ").replace("\u200b", "")
    lines = [re.sub(r"[ \t]+", " ", line).strip() for line in raw.split("\n")]

    result: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Page numbers are not part of the source content and otherwise pollute
        # full-text search and the article bodies.
        if re.fullmatch(r"\d{1,4}", line):
            i += 1
            continue
        if line.endswith("-") and i + 1 < len(lines):
            next_line = lines[i + 1]
            if next_line and next_line[0].islower():
                result.append(line[:-1] + next_line)
                i += 2
                continue
        result.append(line)
        i += 1
    return result


def extract_pdf(path: Path) -> tuple[str, list[str]]:
    reader = PdfReader(str(path))
    lines: list[str] = []
    for page in reader.pages:
        lines.extend(clean_lines(page.extract_text() or ""))
        lines.append("")
    while lines and not lines[-1]:
        lines.pop()
    prose = "\n".join(lines)
    prose = re.sub(r"\n{3,}", "\n\n", prose).strip()
    return prose, lines


ARTICLE_RE = re.compile(
    r"^\s*(?:ARTICLE|ART\.?)\s+"
    r"([LRD]?\.?\s*[0-9]+(?:[-.–][0-9]+)*"
    r"(?:\s*(?:er|bis|ter|quater))?)"
    r"\s*[:.)—\-–]?\s*(.*)$",
    re.IGNORECASE,
)


def heading_for(line: str) -> tuple[int, str] | None:
    upper = line.upper().strip()
    patterns = (
        (1, r"(?:PREMI[ÈE]RE|DEUXI[ÈE]ME|TROISI[ÈE]ME|QUATRI[ÈE]ME)\s+PARTIE\b"),
        (1, r"PARTIE\s+[IVXLCDM0-9]+\b"),
        (1, r"LIVRE\s+[IVXLCDM0-9]+\b"),
        (2, r"TITRE\s+[IVXLCDM0-9]+\b"),
        (3, r"CHAPITRE\s+[IVXLCDM0-9]+\b"),
        (4, r"SECTION\s+[IVXLCDM0-9]+\b"),
        (5, r"SOUS[- ]SECTION\s+[IVXLCDM0-9]+\b"),
        (5, r"PARAGRAPHE\s+[IVXLCDM0-9]+\b"),
    )
    for depth, pattern in patterns:
        if re.match(r"^" + pattern, upper):
            return depth, line
    return None


def parse_code_articles(lines: list[str]) -> tuple[list[dict[str, Any]], list[str]]:
    articles: list[dict[str, Any]] = []
    path: list[str] = []
    current: dict[str, Any] | None = None
    body: list[str] = []
    outlines: list[str] = []

    def flush() -> None:
        nonlocal current, body
        if current is None:
            return
        text = " ".join(part.strip() for part in body if part.strip())
        text = re.sub(r"\s+", " ", text).strip()
        if text:
            current["body"] = text
            articles.append(current)
        current = None
        body = []

    for line in lines:
        if not line:
            continue
        division = heading_for(line)
        if division and not ARTICLE_RE.match(line):
            flush()
            depth, label = division
            path[:] = path[: depth - 1]
            path.append(label)
            if label not in outlines:
                outlines.append(label)
            continue

        match = ARTICLE_RE.match(line)
        if match:
            flush()
            number = re.sub(r"\s+", " ", match.group(1)).strip()
            rest = match.group(2).strip()
            current = {
                "number": number,
                "heading": "",
                "body": "",
                "path": list(path),
            }
            if rest:
                body.append(rest)
            continue

        if current is not None:
            body.append(line)
    flush()
    return articles, outlines


def read_existing_2025() -> dict[str, Any]:
    source = IMPORT_DIR / "doc-code-personnes-famille.json"
    data = json.loads(source.read_text(encoding="utf-8"))
    # The original hand-import used a provisional slug while migration_020
    # published the stable public id. Keep one canonical row in Supabase.
    data["id"] = "doc-code-personnes-famille"
    data["summary"] = (
        "Texte intégral structuré par article à partir du PDF fourni : loi "
        "n° 012-2025/ALT du 1er septembre 2025, promulguée par le décret "
        "n° 2025-1232/PF du 25 septembre 2025."
    )
    data["summary_only"] = False
    data["full_content"] = ""
    data.setdefault("outline", [])
    for article in data.get("articles", []):
        article.setdefault("heading", "")
        article.setdefault("path", [])
    return data


def document(
    *,
    pdf_name: str,
    output_name: str,
    id_: str,
    title: str,
    type_: str,
    reference: str,
    date: str,
    summary: str,
    source_name: str,
    tags: list[str],
    outline: list[str],
    related: list[str],
) -> dict[str, Any]:
    full_content, _ = extract_pdf(ASSET_DIR / pdf_name)
    data = {
        "id": id_,
        "title": title,
        "type": type_,
        "domain": "famille",
        "reference": reference,
        "date_publication": date,
        "status": "enVigueur",
        "summary": summary,
        "full_content": full_content,
        "outline": outline,
        "summary_only": False,
        "official_source_name": source_name,
        "source_url": None,
        "tags": tags,
        "related_ids": related,
        "articles": [],
    }
    Path(IMPORT_DIR / output_name).write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return data


def sql_quote(value: str | None) -> str:
    if value is None:
        return "null"
    return "'" + value.replace("'", "''") + "'"


def sql_array(values: list[str]) -> str:
    if not values:
        return "array[]::text[]"
    return "array[" + ", ".join(sql_quote(value) for value in values) + "]"


def generate_sql(documents: list[dict[str, Any]]) -> None:
    ids = [doc["id"] for doc in documents]
    lines = [
        "-- migration_021 — Corpus intégral fourni pour la bibliothèque famille.",
        "-- Les PDF originaux sont conservés dans assets/legal/family/.",
        "-- Les codes sont indexés article par article ; les études, thèses et le",
        "-- document ONU sont conservés dans full_content, sans badge Résumé.",
        "",
        "insert into public.legal_documents (",
        "  id, title, type, domain, reference, date_publication, status, summary,",
        "  full_content, outline, summary_only, official_source_name, source_url,",
        "  tags, related_ids, imported_at",
        ")",
        "values",
    ]
    rows: list[str] = []
    for doc in documents:
        rows.append(
            "(" + ",\n  ".join(
                [
                    sql_quote(doc["id"]),
                    sql_quote(doc["title"]),
                    sql_quote(doc["type"]),
                    sql_quote(doc["domain"]),
                    sql_quote(doc.get("reference", "")),
                    sql_quote(doc.get("date_publication")),
                    sql_quote(doc.get("status", "enVigueur")),
                    sql_quote(doc.get("summary", "")),
                    sql_quote(doc.get("full_content", "")),
                    sql_array(doc.get("outline", [])),
                    "false",
                    sql_quote(doc.get("official_source_name")),
                    sql_quote(doc.get("source_url")),
                    sql_array(doc.get("tags", [])),
                    sql_array(doc.get("related_ids", [])),
                    "now()",
                ]
            )
            + ")"
        )
    lines.append(",\n".join(rows))
    lines.extend(
        [
            "on conflict (id) do update set",
            "  title = excluded.title, type = excluded.type, domain = excluded.domain,",
            "  reference = excluded.reference, date_publication = excluded.date_publication,",
            "  status = excluded.status, summary = excluded.summary,",
            "  full_content = excluded.full_content, outline = excluded.outline,",
            "  summary_only = excluded.summary_only,",
            "  official_source_name = excluded.official_source_name,",
            "  source_url = excluded.source_url, tags = excluded.tags,",
            "  related_ids = excluded.related_ids, imported_at = excluded.imported_at;",
            "",
            "delete from public.legal_articles where document_id in ("
            + ", ".join(sql_quote(value) for value in ids)
            + ");",
            "",
        ]
    )

    article_values: list[str] = []
    for doc in documents:
        for ordinal, article in enumerate(doc.get("articles", [])):
            article_values.append(
                "(" + ", ".join(
                    [
                        sql_quote(doc["id"]),
                        str(ordinal),
                        sql_quote(article["number"]),
                        sql_quote(article.get("heading", "")),
                        sql_quote(article.get("body", "")),
                        sql_array(article.get("path", [])),
                    ]
                ) + ")"
            )
    for offset in range(0, len(article_values), 250):
        batch = article_values[offset : offset + 250]
        lines.extend(
            [
                "insert into public.legal_articles",
                "  (document_id, ord, number, heading, body, path)",
                "values",
                ",\n".join(batch) + ";",
                "",
            ]
        )

    MIGRATION_PATH.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    IMPORT_DIR.mkdir(parents=True, exist_ok=True)
    documents: list[dict[str, Any]] = []

    prose_specs = [
        dict(
            pdf_name="convention-relative-droits-enfant-crc-sp-50.pdf",
            output_name="doc-onu-crc-sp-50.json",
            id_="doc-onu-crc-sp-50",
            title="Document ONU — Comité des droits de l'enfant (CRC/SP/50)",
            type_="rapport",
            reference="CRC/SP/50 — 5 juin 2018",
            date="2018-06-05",
            summary="Document institutionnel complet relatif à la dix-septième réunion des États parties et à l'élection de membres du Comité des droits de l'enfant.",
            source_name="Nations Unies",
            tags=["droits de l'enfant", "Convention relative aux droits de l'enfant", "Comité des droits de l'enfant", "Nations Unies"],
            outline=["Réunion des États parties — New York, 29 juin 2018", "Élection de neuf membres du Comité des droits de l'enfant", "Personnes désignées par les États parties", "Membres continuant leur mandat", "Notices biographiques des personnes désignées"],
            related=["doc-code-personnes-famille"],
        ),
        dict(
            pdf_name="organisation-juridique-mariage-senegal.pdf",
            output_name="doc-doctrine-mariage-senegal.json",
            id_="doc-doctrine-mariage-senegal",
            title="L'organisation juridique du mariage au Sénégal",
            type_="doctrine",
            reference="Cheikh SENE — RAMReS, janvier 2020",
            date="2020-01-01",
            summary="Étude doctrinale complète consacrée à la formation et à l'organisation juridique du mariage au Sénégal.",
            source_name="RAMReS — Cheikh SENE",
            tags=["mariage", "fiançailles", "droit sénégalais", "coutume", "égalité des époux"],
            outline=["Introduction", "Les fiançailles", "Les conditions de fond et de forme", "Le mariage célébré", "Le mariage coutumier constaté", "Le mariage coutumier non constaté", "Les effets du mariage", "Conclusion"],
            related=["doc-code-personnes-famille"],
        ),
        dict(
            pdf_name="droit-famille-burkinabe.pdf",
            output_name="doc-doctrine-famille-burkina.json",
            id_="doc-doctrine-famille-burkina",
            title="Droit de la famille burkinabé — Le code et ses pratiques à Ouagadougou",
            type_="doctrine",
            reference="Anne-Claude Cavin — L'Harmattan, 1998, ISBN 2-7384-7397-0",
            date="1998-01-01",
            summary="Étude doctrinale et anthropologique complète des pratiques familiales et judiciaires à Ouagadougou.",
            source_name="Éditions L'Harmattan — Anne-Claude Cavin",
            tags=["famille burkinabè", "Ouagadougou", "mariage traditionnel", "filiation", "veuvage", "source historique"],
            outline=["Généralités : cadre historique, juridique et culturel", "Le dualisme juridique et juridictionnel", "Parenté, mariage et filiation", "Analyse des données de terrain", "Veuvage et résolution des conflits", "Filles-mères et litiges de filiation", "Problèmes conjugaux", "Synthèse doctrinale et pratique"],
            related=["doc-code-personnes-famille"],
        ),
        dict(
            pdf_name="these-aissata-dabo-egalite-mariage-afrique.pdf",
            output_name="doc-these-egalite-mariage-afrique.json",
            id_="doc-these-egalite-mariage-afrique",
            title="L'égalité de l'homme et de la femme dans le mariage en Afrique noire francophone",
            type_="doctrine",
            reference="Aïssata Dabo — Thèse de doctorat en cotutelle, Universités de Bordeaux et d'Abomey-Calavi, 15 décembre 2017",
            date="2017-12-15",
            summary="Thèse complète consacrée à l'égalité dans le mariage, au pluralisme juridique et à l'effectivité des droits des femmes.",
            source_name="Aïssata Dabo — Universités de Bordeaux et d'Abomey-Calavi",
            tags=["égalité femmes-hommes", "mariage", "droit comparé", "Bénin", "Burkina Faso", "Mali", "doctrine"],
            outline=["Introduction", "Partie I — Faiblesse des droits de la femme dans le mariage", "Formation, vie et dissolution du mariage", "Partie II — Négation des droits de la femme dans le mariage", "Polygynie, violences et droits de santé", "Conclusion générale"],
            related=["doc-code-personnes-famille", "doc-code-personnes-famille-1989"],
        ),
        dict(
            pdf_name="these-marie-eve-pare-pluralisme-justice.pdf",
            output_name="doc-these-pluralisme-justice-mossi.json",
            id_="doc-these-pluralisme-justice-mossi",
            title="Le pluralisme des systèmes juridiques et les perceptions de la justice",
            type_="doctrine",
            reference="Marie-Eve Paré — Thèse de doctorat en anthropologie, Université de Montréal, 22 décembre 2016",
            date="2016-12-22",
            summary="Thèse complète consacrée au pluralisme juridique, aux conflits matrimoniaux et aux perceptions de la justice chez les Mossi de Koudougou.",
            source_name="Marie-Eve Paré — Université de Montréal",
            tags=["pluralisme juridique", "Mossi", "Koudougou", "mariage", "justice coutumière", "anthropologie juridique", "doctrine"],
            outline=["Introduction", "Approche théorique et méthodologie ethnographique", "Parenté et organisation du mariage chez les Mossi", "Conjugalité et sources des conflits matrimoniaux", "Mariages forcés, polygynie, filiation et conflits successoraux", "Résolution coutumière, action sociale, tribunal et forum shopping", "Conclusion"],
            related=["doc-code-personnes-famille", "doc-code-personnes-famille-1989"],
        ),
    ]
    for spec in prose_specs:
        documents.append(document(**spec))

    code_1989, lines_1989 = extract_pdf(ASSET_DIR / "code-personnes-famille-1989.pdf")
    articles_1989, outline_1989 = parse_code_articles(lines_1989)
    documents.append(
        {
            "id": "doc-code-personnes-famille-1989",
            "title": "Code des personnes et de la famille — archive 1989",
            "type": "code",
            "domain": "famille",
            "reference": "Zatu n° AN VII-0013/FP/PRES du 16 novembre 1989",
            "date_publication": "1989-11-16",
            "status": "abroge",
            "summary": "Texte intégral structuré par article du Code historique des personnes et de la famille, conservé comme archive.",
            "full_content": "",
            "outline": outline_1989,
            "summary_only": False,
            "official_source_name": "Archive législative — texte transmis",
            "source_url": None,
            "tags": ["archive", "code abrogé", "famille", "mariage", "état civil", "Burkina Faso"],
            "related_ids": ["doc-code-personnes-famille"],
            "articles": articles_1989,
        }
    )

    current_2025 = read_existing_2025()
    current_2025["articles"] = current_2025.get("articles", [])
    documents.append(current_2025)

    for doc in documents:
        output = IMPORT_DIR / f"{doc['id']}.json"
        output.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    generate_sql(documents)

    print(f"Generated {len(documents)} documents")
    for doc in documents:
        content_length = len(doc.get("full_content", ""))
        print(f"{doc['id']}: full_content={content_length}, articles={len(doc.get('articles', []))}")
    print(f"Migration: {MIGRATION_PATH} ({MIGRATION_PATH.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
