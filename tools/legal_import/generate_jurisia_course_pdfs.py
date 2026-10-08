"""Render the existing original JurisIA course texts as accessible PDFs.

The body of each PDF is taken verbatim from the Dart raw-string source. This
script adds only document layout, a cover, and running page furniture.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from xml.sax.saxutils import escape

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Frame,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
)


ROOT = Path(__file__).resolve().parents[2]
SOURCES = {
    "obligations": (
        "lib/features/library/data/datasources/jurisia_obligations_course.dart",
        "jurisiaObligationsCourse",
        "Cours complet JurisIA - Droit des obligations",
        "course-obligations-jurisia.pdf",
    ),
    "penal-general": (
        "lib/features/library/data/datasources/jurisia_penal_pack_local_datasource.dart",
        "_generalPenalCourse",
        "Cours complet JurisIA - Droit pénal général",
        "course-penal-general-jurisia.pdf",
    ),
    "penal-special": (
        "lib/features/library/data/datasources/jurisia_penal_pack_local_datasource.dart",
        "_specialPenalCourse",
        "Cours complet JurisIA - Droit pénal spécial",
        "course-penal-special-jurisia.pdf",
    ),
    "procedure-penale": (
        "lib/features/library/data/datasources/jurisia_penal_pack_local_datasource.dart",
        "_criminalProcedureCourse",
        "Cours complet JurisIA - Procédure pénale",
        "course-procedure-penale-jurisia.pdf",
    ),
    "judiciaire-fondements": (
        "lib/features/library/data/datasources/jurisia_private_judicial_law_pack_local_datasource.dart",
        "_privateJudicialFoundations",
        "Cours complet JurisIA - Fondements du droit judiciaire privé",
        "course-droit-judiciaire-prive-jurisia.pdf",
    ),
    "procedure-civile": (
        "lib/features/library/data/datasources/jurisia_private_judicial_law_pack_local_datasource.dart",
        "_civilProcedureCourse",
        "Cours complet JurisIA - Procédure civile",
        "course-procedure-civile-jurisia.pdf",
    ),
    "execution-civile": (
        "lib/features/library/data/datasources/jurisia_private_judicial_law_pack_local_datasource.dart",
        "_jurisdictionsAndEnforcementCourse",
        "Cours complet JurisIA - Juridictions et exécution civile",
        "course-execution-civile-jurisia.pdf",
    ),
    "action-administrative": (
        "lib/features/library/data/datasources/jurisia_administrative_law_pack_local_datasource.dart",
        "_administrativeActionCourse",
        "Cours complet JurisIA - Action administrative",
        "course-action-administrative-jurisia.pdf",
    ),
    "contrats-administratifs": (
        "lib/features/library/data/datasources/jurisia_administrative_law_pack_local_datasource.dart",
        "_administrativeContractsCourse",
        "Cours complet JurisIA - Contrats administratifs",
        "course-contrats-administratifs-jurisia.pdf",
    ),
    "contentieux-administratif": (
        "lib/features/library/data/datasources/jurisia_administrative_law_pack_local_datasource.dart",
        "_administrativeLitigationCourse",
        "Cours complet JurisIA - Contentieux administratif et jurisprudence",
        "course-contentieux-administratif-jurisia.pdf",
    ),
    "droit-bancaire": (
        "lib/features/library/data/datasources/jurisia_banking_insurance_pack_local_datasource.dart",
        "_bankingLawCourse",
        "Cours complet JurisIA - Droit bancaire",
        "course-droit-bancaire-jurisia.pdf",
    ),
    "reglementation-umoa": (
        "lib/features/library/data/datasources/jurisia_banking_insurance_pack_local_datasource.dart",
        "_umoaBankingLawCourse",
        "Cours complet JurisIA - Réglementation bancaire UMOA",
        "course-reglementation-umoa-jurisia.pdf",
    ),
    "assurances-cima": (
        "lib/features/library/data/datasources/jurisia_banking_insurance_pack_local_datasource.dart",
        "_insuranceLawCourse",
        "Cours complet JurisIA - Droit des assurances et Code CIMA",
        "course-assurances-cima-jurisia.pdf",
    ),
    "modele-neutre": (
        "lib/features/library/data/datasources/legal_document_local_datasource.dart",
        "doc-modele-neutre-acte-juridique",
        "Modèle neutre d’acte juridique - JurisIA",
        "course-modele-neutre-acte-juridique-jurisia.pdf",
    ),
}


def extract_body(relative_path: str, constant: str) -> str:
    source = (ROOT / relative_path).read_text(encoding="utf-8")
    if constant == "doc-modele-neutre-acte-juridique":
        record = re.search(
            rf"id:\s*'{re.escape(constant)}'.*?fullContent:\s*((?:'(?:\\.|[^'\\])*'\s*)+),\s*outline:",
            source,
            re.DOTALL,
        )
        if not record:
            raise ValueError(f"Cannot locate fullContent for {constant}")
        import ast

        body = "".join(ast.literal_eval(part) for part in re.findall(
            r"'(?:\\.|[^'\\])*'", record.group(1)
        )).strip()
        if len(body) < 500:
            raise ValueError(f"Refusing to render unexpectedly short source: {constant}")
        return body
    pattern = rf"const\s+{re.escape(constant)}\s*=\s*r'''(.*?)''';"
    match = re.search(pattern, source, re.DOTALL)
    if not match:
        raise ValueError(f"Cannot locate {constant} in {relative_path}")
    body = match.group(1).strip()
    if len(body) < 500:
        raise ValueError(f"Refusing to render unexpectedly short source: {constant}")
    return body


def normalize_punctuation(value: str) -> str:
    return value.translate(str.maketrans({"–": "-", "—": "-", "‑": "-"}))


def register_fonts() -> tuple[str, str]:
    font_dir = Path(r"C:\Windows\Fonts")
    regular = font_dir / "georgia.ttf"
    bold = font_dir / "georgiab.ttf"
    if regular.exists() and bold.exists():
        pdfmetrics.registerFont(TTFont("JurisGeorgia", str(regular)))
        pdfmetrics.registerFont(TTFont("JurisGeorgia-Bold", str(bold)))
        return "JurisGeorgia", "JurisGeorgia-Bold"
    return "Times-Roman", "Times-Bold"


def make_pdf(key: str, output_dir: Path, regular_font: str, bold_font: str) -> Path:
    relative_path, constant, title, filename = SOURCES[key]
    body = normalize_punctuation(extract_body(relative_path, constant))
    output = output_dir / filename

    navy = colors.HexColor("#0B1423")
    gold = colors.HexColor("#C89B2C")
    ink = colors.HexColor("#182231")
    muted = colors.HexColor("#607086")
    styles = getSampleStyleSheet()
    cover_kicker = ParagraphStyle(
        "CoverKicker", parent=styles["Normal"], fontName=bold_font,
        fontSize=9, leading=14, textColor=gold, alignment=TA_CENTER,
        spaceAfter=20,
    )
    cover_title = ParagraphStyle(
        "CoverTitle", parent=styles["Title"], fontName=bold_font,
        fontSize=25, leading=32, textColor=navy, alignment=TA_CENTER,
        spaceAfter=16,
    )
    cover_subtitle = ParagraphStyle(
        "CoverSubtitle", parent=styles["Normal"], fontName=regular_font,
        fontSize=12, leading=18, textColor=muted, alignment=TA_CENTER,
    )
    body_style = ParagraphStyle(
        "CourseBody", parent=styles["BodyText"], fontName=regular_font,
        fontSize=10.4, leading=16, textColor=ink, alignment=TA_LEFT,
        spaceAfter=10, allowWidows=0, allowOrphans=0,
    )
    heading_style = ParagraphStyle(
        "CourseHeading", parent=body_style, fontName=bold_font,
        fontSize=12.2, leading=17, textColor=navy, spaceBefore=8,
        spaceAfter=7, keepWithNext=True,
    )
    subheading_style = ParagraphStyle(
        "CourseSubheading", parent=body_style, fontName=bold_font,
        fontSize=10.6, leading=15, textColor=gold, spaceBefore=5,
        spaceAfter=5, keepWithNext=True,
    )

    doc = BaseDocTemplate(
        str(output), pagesize=A4, title=title, author="JurisIA",
        subject="Contenu pédagogique original JurisIA, rendu en PDF",
        leftMargin=24 * mm, rightMargin=24 * mm,
        topMargin=22 * mm, bottomMargin=20 * mm,
    )
    frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height,
                  id="course", leftPadding=0, rightPadding=0,
                  topPadding=0, bottomPadding=0)

    def page_furniture(canvas, document):
        canvas.saveState()
        width, height = A4
        canvas.setStrokeColor(colors.HexColor("#E5EAF0"))
        canvas.setLineWidth(0.6)
        canvas.line(doc.leftMargin, height - 15 * mm,
                    width - doc.rightMargin, height - 15 * mm)
        canvas.setFont(regular_font, 8)
        canvas.setFillColor(muted)
        canvas.drawString(doc.leftMargin, height - 11 * mm,
                          "BIBLIOTHÈQUE JURISIA  /  COURS ORIGINAL")
        canvas.line(doc.leftMargin, 14 * mm, width - doc.rightMargin, 14 * mm)
        canvas.drawString(doc.leftMargin, 9 * mm, "JurisIA - Contenu pédagogique original")
        canvas.drawRightString(width - doc.rightMargin, 9 * mm,
                               f"Page {document.page}")
        canvas.restoreState()

    doc.addPageTemplates([PageTemplate(id="course", frames=[frame], onPage=page_furniture)])
    story = [
        Spacer(1, 47 * mm),
        Paragraph("BIBLIOTHÈQUE JURISIA  ·  SUPPORT PÉDAGOGIQUE ORIGINAL", cover_kicker),
        Paragraph(escape(normalize_punctuation(title)), cover_title),
        Paragraph("Contenu intégral du cours tel qu’il est rédigé dans JurisIA", cover_subtitle),
        Spacer(1, 16 * mm),
        Paragraph("Édition pédagogique originale JurisIA", cover_subtitle),
        PageBreak(),
    ]

    for paragraph in re.split(r"\n\s*\n", body):
        text = paragraph.strip()
        if not text:
            continue
        normalized = normalize_punctuation(text)
        is_heading = bool(re.match(
            r"^(COURS COMPLET|PARTIE\s+[IVX0-9]+|LIVRE\s+[IVX0-9]+|"
            r"TITRE\s+[IVX0-9]+|ORIENTATION|PRÉSENTATION|MÉTHODE|"
            r"CONCLUSION|FICHES\s+OPÉRATIONNELLES)", normalized, re.IGNORECASE
        ))
        is_subheading = bool(re.match(r"^\d+\.\s+\S", normalized))
        style = heading_style if is_heading else subheading_style if is_subheading else body_style
        story.append(Paragraph(escape(normalized).replace("\n", "<br/>"), style))

    doc.build(story)
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=ROOT / "output" / "pdf")
    parser.add_argument("--keys", nargs="*", choices=SOURCES.keys(), default=list(SOURCES))
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    regular_font, bold_font = register_fonts()
    for key in args.keys:
        path = make_pdf(key, args.output_dir, regular_font, bold_font)
        print(f"{key}\t{path}\t{path.stat().st_size}")


if __name__ == "__main__":
    main()
