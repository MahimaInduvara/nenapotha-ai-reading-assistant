from __future__ import annotations

import os
import re
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageOps
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Inches, Pt, RGBColor
from docx.table import Table
from docx.text.paragraph import Paragraph

import generate_updated_interim_thesis_ch1_3 as base
from generate_thesis_breakdown import (
    ASSETS,
    BLACK,
    BLUE,
    CORAL,
    LIGHT,
    MID_GREY,
    NAVY,
    ORANGE,
    PALE_ORANGE,
    PALE_TEAL,
    TEAL,
    add_body,
    add_bullets,
    add_callout,
    add_caption,
    add_numbered,
    add_page_number,
    add_table,
    arrow,
    font,
    rounded_box,
)


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "deliverables"
DOCX = OUT / os.environ.get(
    "NENAPOTHA_THESIS_DOCX",
    "NenaPotha_AI_Final_Thesis_28277.docx",
)
SCREENSHOT_COMPOSITE = ASSETS / "nenapotha_ai_app_execution_screens.png"
SCREENSHOT_APPENDIX_COMPOSITE = ASSETS / "nenapotha_ai_app_execution_screens_portrait.png"
SCREENSHOTS_DIR = Path(r"C:\Users\DELL\Pictures\Screenshots\research")
SCREENSHOT_MANIFEST = [
    ("Screenshot 2026-10-04 102217.png", "Parent and teacher authentication screen"),
    ("Screenshot 2026-10-04 102118.png", "Independent Sinhala and English interface-language selection"),
    ("Screenshot 2026-10-04 102317.png", "Child-facing home dashboard and recommended activity"),
    ("Screenshot 2026-10-04 102348.png", "Grade 1 picture-supported letter-learning interface"),
    ("Screenshot 2026-10-04 102621.png", "On-device Sinhala letter-tracing interface"),
    ("Screenshot 2026-10-04 102707.png", "Grade 2 picture-supported pillam exploration"),
    ("Screenshot 2026-10-04 102742.png", "Grade 2 pillam-completion learning task"),
    ("Screenshot 2026-10-04 102410.png", "Evidence-based My Coach learning plan"),
    ("Screenshot 2026-10-04 102527.png", "Learner progress dashboard and skill evidence"),
    ("Screenshot 2026-10-04 102549.png", "Learner profile and application preferences"),
    ("Screenshot 2026-10-04 101921.png", "Teacher dashboard and grade-filtered student list"),
    ("Screenshot 2026-10-04 101956.png", "Teacher workflow for linking a learner by student code"),
    ("Screenshot 2026-10-04 102032.png", "Individual student analysis available to the linked teacher"),
]
MEETING_DIR = Path(r"C:\Users\DELL\Pictures\lecture")
MEETING_MANIFEST = [
    ("WhatsApp Image 2026-10-04 at 00.16.16 (3).jpeg", "Student progression report with signed meeting register"),
    ("WhatsApp Image 2026-10-04 at 00.16.14.jpeg", "Supervisory meeting minutes — Meeting 01"),
    ("WhatsApp Image 2026-10-04 at 00.16.15.jpeg", "Supervisory meeting minutes — Meeting 02"),
    ("WhatsApp Image 2026-10-04 at 00.16.15 (1).jpeg", "Supervisory meeting minutes — Meeting 03"),
    ("WhatsApp Image 2026-10-04 at 00.16.15 (2).jpeg", "Supervisory meeting minutes — Meeting 04"),
    ("WhatsApp Image 2026-10-04 at 00.16.16.jpeg", "Supervisory meeting minutes — Meeting 05"),
    ("WhatsApp Image 2026-10-04 at 00.16.16 (1).jpeg", "Supervisory meeting minutes — Meeting 06"),
    ("WhatsApp Image 2026-10-04 at 00.16.16 (2).jpeg", "Supervisory meeting minutes — Meeting 07"),
]


def add_field(paragraph, instruction: str, placeholder: str) -> None:
    run = paragraph.add_run()
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = instruction
    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    text = OxmlElement("w:t")
    text.text = placeholder
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    for node in (begin, instr, separate, text, end):
        run._r.append(node)


def set_cell_text(cell, text: str, bold: bool = False) -> None:
    cell.text = ""
    p = cell.paragraphs[0]
    r = p.add_run(text)
    r.bold = bold
    r.font.name = "Times New Roman"
    r.font.size = Pt(8.5)


def add_equation(doc: Document, text: str) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after = Pt(6)
    r = p.add_run(text)
    r.font.name = "Cambria Math"
    r.font.size = Pt(11)
    r.italic = True


def add_code(doc: Document, code: str) -> None:
    table = doc.add_table(rows=1, cols=1)
    table.autofit = True
    cell = table.cell(0, 0)
    cell._tc.get_or_add_tcPr().append(_shading("F3F4F6"))
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(0)
    for index, line in enumerate(code.strip().splitlines()):
        if index:
            p.add_run("\n")
        r = p.add_run(line)
        r.font.name = "Consolas"
        r.font.size = Pt(8)


def _shading(fill: str):
    node = OxmlElement("w:shd")
    node.set(qn("w:fill"), fill)
    return node


def _center_last_picture(doc: Document) -> None:
    if doc.paragraphs:
        doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER


def _new_canvas(title: str, width: int = 1900, height: int = 1120):
    img = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(img)
    draw.text((width // 2, 45), title, font=font(42, True), fill=f"#{NAVY}", anchor="ma")
    return img, draw


def make_complete_thesis_figures() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    base.make_diagrams()
    base.make_additional_diagrams()

    # Final registered open-set evaluation of the deployed model family.
    img, d = _new_canvas("Registered Open-set CNN Evaluation", 1750, 970)
    metrics = [
        ("Overall accuracy", 98.46, CORAL),
        ("Letter-only accuracy", 98.51, ORANGE),
        ("Macro F1-score", 98.73, TEAL),
        ("Top-3 accuracy", 99.43, BLUE),
        ("Unknown recall", 97.00, "8E44AD"),
        ("Known-letter acceptance", 99.39, "5C6BC0"),
    ]
    y = 155
    for label, value, color in metrics:
        d.text((65, y + 30), label, font=font(25, True), fill=f"#{BLACK}", anchor="lm")
        d.rounded_rectangle((560, y, 1560, y + 62), radius=18, fill="#E5E7EB")
        d.rounded_rectangle((560, y, 560 + 1000 * value / 100, y + 62), radius=18, fill=f"#{color}")
        d.text((1660, y + 30), f"{value:.2f}%", font=font(25, True), fill=f"#{color}", anchor="mm")
        y += 115
    d.text((875, 885), "Test n = 11,296; 454 known classes + Unknown/Invalid; invalid false acceptance = 3.00%",
           font=font(24, True), fill=f"#{NAVY}", anchor="ma")
    img.save(ASSETS / "cnn_protected_test_metrics.png", quality=96)

    # Use case diagram.
    img, d = _new_canvas("NenaPotha AI — Principal Use Cases")
    rounded_box(d, (550, 120, 1370, 1030), "#F8FAFC", f"#{BLUE}", "System Boundary", "", 35, 22)
    actors = [(100, 320, "Learner"), (100, 760, "Parent / Teacher"), (1530, 550, "Firebase Services")]
    for x, y, label in actors:
        d.ellipse((x, y - 75, x + 100, y + 25), outline=f"#{NAVY}", width=6)
        d.line((x + 50, y + 25, x + 50, y + 165), fill=f"#{NAVY}", width=6)
        d.line((x - 5, y + 80, x + 105, y + 80), fill=f"#{NAVY}", width=6)
        d.line((x + 50, y + 165, x - 5, y + 240), fill=f"#{NAVY}", width=6)
        d.line((x + 50, y + 165, x + 105, y + 240), fill=f"#{NAVY}", width=6)
        d.text((x + 50, y + 270), label, font=font(25, True), fill=f"#{NAVY}", anchor="ma")
    cases = [
        ("Select Grade 1/2", 720, 210), ("Learn letters and words", 1050, 210),
        ("Trace a Sinhala letter", 720, 405), ("Read graded stories", 1050, 405),
        ("Answer comprehension tasks", 720, 600), ("Use My Coach plan", 1050, 600),
        ("Review progress evidence", 720, 795), ("Manage learner profile", 1050, 795),
    ]
    for label, x, y in cases:
        d.ellipse((x - 180, y - 62, x + 180, y + 62), fill="#EEF2FF", outline=f"#{BLUE}", width=4)
        d.text((x, y), label, font=font(22, True), fill=f"#{BLACK}", anchor="mm")
    for target in [(720, 210), (1050, 210), (720, 405), (1050, 405), (720, 600)]:
        d.line((205, 500, target[0] - 180, target[1]), fill=f"#{MID_GREY}", width=3)
    for target in [(1050, 600), (720, 795), (1050, 795)]:
        d.line((205, 930, target[0] - 180, target[1]), fill=f"#{MID_GREY}", width=3)
    d.line((1530, 680, 1230, 600), fill=f"#{MID_GREY}", width=3)
    d.line((1530, 680, 1230, 795), fill=f"#{MID_GREY}", width=3)
    img.save(ASSETS / "use_case_diagram.png", quality=96)

    # Class/domain model diagram.
    img, d = _new_canvas("Core Domain and Service Class Model", 2000, 1250)
    classes = [
        (70, 170, 560, 430, "Student", "studentId\nname\ngrade\nlanguage", "updateProfile()"),
        (750, 150, 1260, 440, "TaskAttempt", "taskId\nscore\ntimestamp\nmodelEvidence", "toMap()"),
        (1440, 170, 1930, 430, "Story", "title\ngrade\ntext\nquestions", "difficultyCheck()"),
        (70, 700, 560, 1030, "LetterClassifierService", "modelVersion\nlabels[455]\nopen-set gate", "loadModel()\npredict()"),
        (750, 690, 1260, 1040, "SmartLearningCoachService", "attempt history\npriority rules", "buildPlan()\nnextActivity()"),
        (1440, 700, 1930, 1040, "ProgressAnalyticsService", "daily activity\nskill evidence", "aggregate()\nshareWithTeacher()"),
    ]
    for x1, y1, x2, y2, name, attrs, methods in classes:
        d.rounded_rectangle((x1, y1, x2, y2), radius=18, fill="#F8FAFC", outline=f"#{BLUE}", width=4)
        d.rectangle((x1, y1, x2, y1 + 60), fill=f"#{BLUE}")
        d.text(((x1 + x2)//2, y1 + 30), name, font=font(25, True), fill="white", anchor="mm")
        d.text((x1 + 20, y1 + 82), attrs, font=font(20), fill=f"#{BLACK}", anchor="la", spacing=7)
        d.line((x1, y2 - 92, x2, y2 - 92), fill=f"#{MID_GREY}", width=2)
        d.text((x1 + 20, y2 - 73), methods, font=font(20, True), fill=f"#{TEAL}", anchor="la", spacing=7)
    arrow(d, (560, 300), (750, 300), BLUE, 5)
    arrow(d, (1260, 300), (1440, 300), BLUE, 5)
    arrow(d, (315, 700), (905, 440), TEAL, 5)
    arrow(d, (1005, 690), (1005, 440), TEAL, 5)
    arrow(d, (1260, 855), (1440, 855), "8E44AD", 5)
    d.text((1000, 1170), "Presentation widgets depend on services; service outputs are stored as typed, auditable task evidence.",
           font=font(24, True), fill=f"#{NAVY}", anchor="ma")
    img.save(ASSETS / "class_model_diagram.png", quality=96)

    # Activity flow.
    img, d = _new_canvas("Letter-Tracing Evaluation Activity", 1500, 1450)
    stages = [
        ("Select supported Sinhala letter", "#EEF2FF", BLUE),
        ("Draw on the tracing canvas", "#FFF2CC", "C9A227"),
        ("Capture PNG and normalize to 64×64 grayscale", "#DFF2EF", TEAL),
        ("Run the bundled TFLite CNN", "#F3E5F5", "8E44AD"),
        ("Map output index → class ID → verified Unicode", "#FCE4D6", CORAL),
        ("Apply expected-letter and confidence gate", "#EEF2FF", BLUE),
        ("Show supportive feedback and store scalar evidence", "#DFF2EF", TEAL),
    ]
    y = 140
    prev = None
    for label, fill, outline in stages:
        box = (330, y, 1170, y + 130)
        d.rounded_rectangle(box, radius=45, fill=fill, outline=f"#{outline}", width=5)
        d.text((750, y + 65), label, font=font(24, True), fill=f"#{BLACK}", anchor="mm")
        if prev:
            arrow(d, (750, prev), (750, y), NAVY, 5)
        prev = y + 130
        y += 175
    d.text((750, 1380), "Failures remain unscored; no geometric fallback is permitted to masquerade as CNN evidence.",
           font=font(23, True), fill=f"#{CORAL}", anchor="ma")
    img.save(ASSETS / "trace_activity_diagram.png", quality=96)

    # Two compact sequence diagrams.
    for filename, title, actors, messages in [
        ("trace_sequence_diagram.png", "Sequence — On-device Trace Classification",
         ["Learner", "Tracing UI", "Classifier", "TFLite", "Progress Store"],
         [(0,1,"tap Check"),(1,2,"predict(PNG)"),(2,3,"run [1,64,64,1]"),(3,2,"455 scores"),(2,1,"typed prediction"),(1,4,"save scalar evidence"),(1,0,"feedback / retry")]),
        ("chat_sequence_diagram.png", "Sequence — Evidence-based My Coach",
         ["Learner", "Coach UI", "Coach Service", "Progress Store", "Task Screen"],
         [(0,1,"open My Coach"),(1,2,"request plan"),(2,3,"load recent evidence"),(3,2,"attempt summaries"),(2,1,"ranked practice plan"),(0,1,"select activity"),(1,4,"open chosen task"),(4,3,"save completed attempt")]),
    ]:
        img, d = _new_canvas(title, 1900, 1050)
        xs = [180, 560, 950, 1330, 1710]
        for x, actor in zip(xs, actors):
            d.rounded_rectangle((x-145, 120, x+145, 205), radius=16, fill="#EEF2FF", outline=f"#{BLUE}", width=4)
            d.text((x, 162), actor, font=font(22, True), fill=f"#{BLACK}", anchor="mm")
            d.line((x, 205, x, 990), fill="#94A3B8", width=3)
        y = 275
        for start, end, label in messages:
            x1, x2 = xs[start], xs[end]
            arrow(d, (x1, y), (x2, y), TEAL if end > start else CORAL, 4)
            d.text(((x1+x2)//2, y-13), label, font=font(19, True), fill=f"#{BLACK}", anchor="ms")
            y += 90
        img.save(ASSETS / filename, quality=96)

    # Deployment/hybrid architecture.
    img, d = _new_canvas("Deployment and Trust Boundaries", 1950, 1160)
    rounded_box(d, (70, 150, 1040, 1000), "#EEF2FF", f"#{BLUE}", "Android Device / Flutter Application",
                "Child-facing learning and reading UI\n\nDeterministic My Coach rules\n\nTFLite CNN (455 outputs)\n\nDart Grade 1/2 text classifier\n\nCached learning content and task state", 34, 25)
    rounded_box(d, (1230, 155, 1870, 480), "#DFF2EF", f"#{TEAL}", "Firebase Project",
                "Authentication\nFirestore progress records\nRole-aware teacher links", 32, 25)
    rounded_box(d, (1230, 650, 1870, 995), "#F3E5F5", "#8E44AD", "Teacher / Guardian Analytics",
                "Linked-student access\nDaily activity summaries\nTask and skill evidence", 32, 25)
    arrow(d, (1040, 340), (1230, 340), TEAL, 6)
    arrow(d, (1040, 820), (1230, 820), "8E44AD", 6)
    d.text((1135, 300), "authenticated data", font=font(20, True), fill=f"#{TEAL}", anchor="ms")
    d.text((1135, 780), "authorized evidence", font=font(20, True), fill="#8E44AD", anchor="ms")
    d.text((975, 1090), "Raw trace images stay on-device; only task results and progress evidence are synchronized.",
           font=font(24, True), fill=f"#{CORAL}", anchor="ma")
    img.save(ASSETS / "deployment_trust_boundary.png", quality=96)

    # Final-build execution evidence selected from the student's dated
    # screenshot set. The four panels cover the learner, learning-content,
    # progress and teacher-facing paths without inventing UI state.
    selected = [
        ("Screenshot 2026-10-04 102317.png", "(a) Learner home"),
        ("Screenshot 2026-10-04 102707.png", "(b) Grade 2 pillam"),
        ("Screenshot 2026-10-04 102527.png", "(c) Learner progress"),
        ("Screenshot 2026-10-04 101921.png", "(d) Teacher dashboard"),
    ]
    panels = []
    for filename, label in selected:
        path = SCREENSHOTS_DIR / filename
        if path.exists():
            shot = Image.open(path).convert("RGB")
            shot.thumbnail((520, 1040), Image.Resampling.LANCZOS)
            panels.append((shot, label))
    if panels:
        canvas = Image.new("RGB", (2350, 1320), "white")
        draw = ImageDraw.Draw(canvas)
        draw.text(
            (1175, 55),
            "NenaPotha AI — Final Android Implementation Evidence",
            font=font(42, True),
            fill=f"#{NAVY}",
            anchor="ma",
        )
        xs = [310, 885, 1460, 2035]
        for (shot, label), x in zip(panels, xs):
            framed = ImageOps.expand(shot, border=7, fill=f"#{BLUE}")
            canvas.paste(framed, (x - framed.width // 2, 140))
            draw.text(
                (x, 1240),
                label,
                font=font(25, True),
                fill=f"#{BLACK}",
                anchor="ma",
            )
        canvas.save(SCREENSHOT_COMPOSITE, quality=96)

        portrait = Image.new("RGB", (1250, 2200), "white")
        portrait_draw = ImageDraw.Draw(portrait)
        portrait_draw.text(
            (625, 55),
            "Final Workflow Overview",
            font=font(38, True),
            fill=f"#{NAVY}",
            anchor="ma",
        )
        positions = [(315, 150), (935, 150), (315, 1160), (935, 1160)]
        for (shot, label), (x, y) in zip(panels, positions):
            panel = shot.copy()
            panel.thumbnail((500, 880), Image.Resampling.LANCZOS)
            framed = ImageOps.expand(panel, border=7, fill=f"#{BLUE}")
            portrait.paste(framed, (x - framed.width // 2, y))
            portrait_draw.text(
                (x, y + 920),
                label,
                font=font(22, True),
                fill=f"#{BLACK}",
                anchor="ma",
            )
        portrait.save(SCREENSHOT_APPENDIX_COMPOSITE, quality=96)


def setup_document() -> Document:
    doc = Document()
    sec = doc.sections[0]
    sec.page_height = Cm(29.7)
    sec.page_width = Cm(21)
    sec.top_margin = Cm(2.54)
    sec.bottom_margin = Cm(2.54)
    sec.left_margin = Cm(3.175)
    sec.right_margin = Cm(2.54)
    normal = doc.styles["Normal"]
    normal.font.name = "Times New Roman"
    normal.font.size = Pt(12)
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Noto Sans Sinhala")
    normal.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    normal.paragraph_format.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
    normal.paragraph_format.space_after = Pt(6)
    for name, bold in [("Title", True), ("Heading 1", True), ("Heading 2", True), ("Heading 3", False)]:
        s = doc.styles[name]
        s.font.name = "Times New Roman"
        s.font.size = Pt(12)
        s.font.bold = bold
        s.font.color.rgb = RGBColor(0, 0, 0)
        s.paragraph_format.space_before = Pt(10)
        s.paragraph_format.space_after = Pt(6)
        s.paragraph_format.keep_with_next = True
    for style_name, alignment in [
        ("Figure Caption", WD_ALIGN_PARAGRAPH.CENTER),
        ("Table Caption", WD_ALIGN_PARAGRAPH.LEFT),
    ]:
        if style_name not in [style.name for style in doc.styles]:
            style = doc.styles.add_style(style_name, WD_STYLE_TYPE.PARAGRAPH)
        else:
            style = doc.styles[style_name]
        style.font.name = "Times New Roman"
        style.font.size = Pt(12)
        style.font.italic = False
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.paragraph_format.alignment = alignment
        style.paragraph_format.space_after = Pt(6)
        style.paragraph_format.keep_with_next = True
    sec.header.paragraphs[0].clear()
    sec.footer.paragraphs[0].clear()
    doc.core_properties.title = "NenaPotha AI — Senate-Compliant Final Thesis"
    doc.core_properties.author = "L. M. I. Silva (28277)"
    doc.core_properties.subject = "BSc (Hons) in Software Engineering Final Year Research"
    update = OxmlElement("w:updateFields")
    update.set(qn("w:val"), "true")
    doc.settings._element.append(update)
    return doc


def _configure_section(section, *, number_format: str, start: int, hide_first: bool = False) -> None:
    section.page_height = Cm(29.7)
    section.page_width = Cm(21)
    section.top_margin = Cm(2.54)
    section.bottom_margin = Cm(2.54)
    section.left_margin = Cm(3.175)
    section.right_margin = Cm(2.54)
    section.header.is_linked_to_previous = False
    section.footer.is_linked_to_previous = False
    section.header.paragraphs[0].clear()
    section.footer.paragraphs[0].clear()
    section.different_first_page_header_footer = hide_first
    if hide_first:
        section.first_page_header.is_linked_to_previous = False
        section.first_page_footer.is_linked_to_previous = False
        section.first_page_header.paragraphs[0].clear()
        section.first_page_footer.paragraphs[0].clear()
    add_page_number(section.footer.paragraphs[0])
    pg_num_type = section._sectPr.find(qn("w:pgNumType"))
    if pg_num_type is None:
        pg_num_type = OxmlElement("w:pgNumType")
        section._sectPr.append(pg_num_type)
    pg_num_type.set(qn("w:fmt"), number_format)
    pg_num_type.set(qn("w:start"), str(start))


def start_main_text_section(doc: Document) -> None:
    section = doc.add_section(WD_SECTION.NEW_PAGE)
    _configure_section(section, number_format="decimal", start=1)


def chapter_two_objectives(doc: Document) -> None:
    doc.add_heading("2 OBJECTIVES", level=1)
    add_body(
        doc,
        "This section states the general and specific objectives used to direct the design, implementation and technical evaluation of the NenaPotha AI research artifact.",
    )
    doc.add_heading("2.1 General objective", level=2)
    add_body(
        doc,
        "To design, develop and technically evaluate an AI-enhanced bilingual mobile reading and comprehension assistant for Grade 1 and Grade 2 learners by integrating on-device Sinhala handwritten-letter recognition with an interpretable Grade 1/2 text-difficulty classifier.",
    )
    doc.add_heading("2.2 Specific objectives", level=2)
    add_numbered(
        doc,
        [
            "To identify the educational, application and evidence gaps affecting automated Sinhala letter-tracing feedback and grade-appropriate reading-content selection for Grade 1 and Grade 2 learners.",
            "To analyze suitable handwritten-character recognition, text-difficulty classification, mobile-learning and privacy-aware integration approaches for the defined low-resource context.",
            "To develop and integrate a custom Sinhala handwritten-letter CNN, a lightweight Grade 1/2 text-difficulty proof of concept, deterministic bilingual learning routes and evidence-aware progress support within the Flutter application.",
            "To evaluate the artifact using a protected held-out CNN test set, conversion parity, static analysis, automated functional tests and Android runtime evidence while explicitly documenting field-evaluation and validity limitations.",
        ],
    )
    doc.add_page_break()


def title_page(doc: Document) -> None:
    thesis_title = (
        "DESIGN AND DEVELOPMENT OF AN AI-ENHANCED BILINGUAL READING AND "
        "COMPREHENSION ASSISTANT FOR GRADE 1 AND GRADE 2 PRIMARY SCHOOL STUDENTS"
    )

    # Appendix I — hardbound cover-page layout. This page has no number.
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(48)
    r = p.add_run(thesis_title)
    r.bold = True
    r.font.name = "Times New Roman"
    r.font.size = Pt(16)
    for text, gap in [
        ("L. M. I. SILVA", 155),
        ("Bachelor of Science (Honours) in Software Engineering", 14),
        ("Department of Software Engineering", 115),
        ("NSBM Green University", 8),
        ("Sri Lanka", 8),
        ("October 2026", 30),
    ]:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(gap)
        rr = p.add_run(text)
        rr.font.name = "Times New Roman"
        rr.font.size = Pt(14)

    # Appendix II — inner title page. It counts as roman page i but is hidden.
    inner_section = doc.add_section(WD_SECTION.NEW_PAGE)
    _configure_section(inner_section, number_format="lowerRoman", start=1, hide_first=True)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(45)
    r = p.add_run(thesis_title)
    r.bold = True
    r.font.name = "Times New Roman"
    r.font.size = Pt(16)
    for text, gap in [
        ("A thesis submitted to NSBM Green University for the degree of\nBachelor of Science (Honours) in Software Engineering", 90),
        ("By", 45),
        ("L. M. I. SILVA", 24),
        ("Department of Software Engineering", 95),
        ("Faculty of Computing", 8),
        ("NSBM Green University", 8),
        ("Sri Lanka", 8),
        ("October 2026", 30),
    ]:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(gap)
        rr = p.add_run(text)
        rr.font.name = "Times New Roman"
        rr.font.size = Pt(14)
    doc.add_page_break()


def front_matter(doc: Document) -> None:
    doc.add_heading("DECLARATION", level=1)
    add_body(doc, "I declare that the content of this undergraduate thesis titled ‘Design and Development of an AI-Enhanced Bilingual Reading and Comprehension Assistant for Grade 1 and Grade 2 Primary School Students’ is my own work and this thesis does not incorporate, without acknowledgement, any material previously submitted for any other degree in any university or institution of higher learning.")
    p = doc.add_paragraph("Student name: L. M. I. Silva                                      Date: 04 October 2026")
    p.paragraph_format.space_before = Pt(30)
    p = doc.add_paragraph("Student signature: ______________________________________________")
    p.paragraph_format.space_before = Pt(12)
    p = doc.add_paragraph("Signature of the Principal Supervisor: __________________________")
    p.paragraph_format.space_before = Pt(30)
    add_body(doc, "Mr. Anton Jayakody\nPrincipal Supervisor\nDepartment of Software Engineering\nNSBM Green University")
    doc.add_page_break()

    doc.add_heading("ACKNOWLEDGEMENT", level=1)
    add_body(doc, "I sincerely thank my principal supervisor, Mr. Anton Jayakody, for his direction, critical feedback and insistence on defensible research evidence throughout this project. I am grateful to the Faculty of Computing and the Department of Software Engineering at NSBM Green University for the academic environment and resources required to complete the study. I also thank the teachers whose preliminary observations helped clarify practical challenges in early Sinhala literacy instruction; their input is treated as exploratory requirements evidence because the sample was small. My appreciation extends to my family and friends for their encouragement during design, development, model training, evaluation and thesis preparation. Finally, I acknowledge the researchers, dataset contributors and open-source communities behind Flutter, Firebase, TensorFlow Lite, scikit-learn and the Sinhala handwriting resources used in this work.")
    doc.add_page_break()

    doc.add_heading("ABSTRACT", level=1)
    add_body(doc, "Foundational literacy remains a concern in Sri Lanka, while Sinhala-focused educational applications provide limited integrated support for handwriting, grade-appropriate reading, picture-supported vocabulary and adult guidance. This study designed and technically evaluated NenaPotha AI, a bilingual mobile reading and comprehension assistant for Grade 1 and Grade 2 learners. A pragmatist design-science process connected educational requirements with two machine-learning components and a deterministic learning coach. The principal component is a 64 × 64 grayscale convolutional neural network extended from 454 Sinhala character classes to a 455-output open-set model with an explicit Unknown/Invalid class. On 11,296 test samples, it achieved 98.46% overall accuracy, 98.51% letter-only accuracy, 98.73% macro-F1 and 97.00% unknown recall, with 3.00% invalid false acceptance. One-writer adaptation raised captured-sample training fit from 16.95% to 72.88% while retaining 95.85% accuracy on 1,108 held-out replay samples; these captures are not an independent child test set. The deployed TensorFlow Lite model preserved 100% top-1 parity over 100 registered samples and averaged 81.24 ms native latency across 30 Android 14 emulator runs. An interpretable logistic-regression component supplies a Grade 1/2 text-difficulty quality-control signal, although its 69.2% resubstitution accuracy on 26 authored texts is not generalization evidence. The application also provides picture-supported learning, stories, comprehension tasks, synchronized progress, teacher-linked analysis and deterministic coaching without a chatbot or paid API. Static analysis and 130 Flutter tests passed. As no ethics-approved child effectiveness trial was completed, the contribution is a reproducible technical artifact and evaluation protocol rather than evidence of improved learning outcomes.")
    p = doc.add_paragraph()
    p.add_run("Keywords—").bold = True
    p.add_run(" Sinhala handwriting recognition, early literacy, open-set classification, convolutional neural network, TensorFlow Lite, readability assessment, learning analytics, bilingual mobile learning")
    doc.add_page_break()

    for index, (title, field, placeholder) in enumerate([
        ("TABLE OF CONTENTS", 'TOC \\o "1-3" \\h \\z \\u', "Update the field to generate the Table of Contents."),
        ("LIST OF FIGURES", 'TOC \\h \\z \\t "Figure Caption,1"', "Update the field to generate the List of Figures."),
        ("LIST OF TABLES", 'TOC \\h \\z \\t "Table Caption,1"', "Update the field to generate the List of Tables."),
    ]):
        heading = doc.add_heading(title, level=1)
        if index > 0:
            heading.paragraph_format.page_break_before = True
        p = doc.add_paragraph()
        add_field(p, field, placeholder)
    heading = doc.add_heading("LIST OF ABBREVIATIONS", level=1)
    heading.paragraph_format.page_break_before = True
    add_table(doc, ["Abbreviation", "Meaning"], [
        ("AI", "Artificial Intelligence"), ("API", "Application Programming Interface"),
        ("ARA", "Automatic Readability Assessment"), ("CNN", "Convolutional Neural Network"),
        ("DSR/DSRM", "Design Science Research / Design Science Research Methodology"),
        ("ECE", "Expected Calibration Error"), ("HCR", "Handwritten Character Recognition"),
        ("NLP", "Natural Language Processing"), ("SRS", "System Requirements Specification"),
        ("FAR", "False Acceptance Rate"), ("TFLite", "TensorFlow Lite"),
        ("UI/UX", "User Interface / User Experience"), ("UAT", "User Acceptance Testing"),
    ])
    # A new section starts the main text at Arabic page 1.


def correct_legacy_chapter_claims(doc: Document) -> None:
    replacements = {
        "the accuracy, class-level behaviour and confidence calibration of the Sinhala letter CNN on reference validation data;":
            "the accuracy, class-level behaviour and confidence calibration of the Sinhala letter CNN on the protected held-out test data;",
        "No reviewed work combines a Grade 1–2 Sinhala/English literacy application with an on-device Sinhala letter classifier and an offline Sinhala Grade 1/2 text-difficulty checker. ReadBuddy AI addresses that integration gap. It does not yet close the evidence gap: numeric label mapping, representative child traces, exact training provenance and an expert-labelled readability corpus remain necessary. This distinction between artifact contribution and validated educational effectiveness is the central critical position of this thesis.":
            "No reviewed work combines a Grade 1–2 Sinhala/English literacy application with an on-device open-set Sinhala letter classifier, an offline Sinhala Grade 1/2 text-difficulty checker and deterministic evidence-based coaching. NenaPotha AI addresses that integration gap. The 455-label contract and reproducible training provenance are verified, but representative child traces, writer-independent adaptation and an expert-labelled readability corpus remain necessary. This distinction between an evaluated artifact and demonstrated educational effectiveness is the central critical position of this thesis.",
        "Source code, model assets, emulator execution, static-analysis output and test output provide engineering evidence. At the current audit, flutter analyze reports ten findings, and the only widget test is an obsolete counter template that fails against the current app. These outcomes do not invalidate the research models, but they show that software-quality evidence is not yet submission-complete.":
            "Source code, model assets, emulator execution, static-analysis output and automated-test output provide engineering evidence. The final audit reports no Flutter analyzer issues, all current Flutter tests passing, Python pipeline tests passing and the on-device CNN integration benchmark passing. These results support software correctness within the tested scenarios, but do not replace field usability or educational-effectiveness evaluation.",
        "The shipped research component is described as a custom three-block CNN. Each block applies convolution and max pooling, followed by dense classification layers, dropout and a 454-way softmax output. Training used 64×64 grayscale inputs, Adam optimization, sparse categorical cross-entropy, batch size 32 and 15 epochs. Two recorded runs produced approximately 94.10% and 94.04% validation accuracy, suggesting run-level stability.":
            "The final research component is a 64×64 grayscale convolutional network with 454 known Sinhala classes and an explicit Unknown/Invalid output. On the registered 11,296-sample open-set test it achieved 98.46% overall accuracy, 98.51% letter-only accuracy, 98.73% macro-F1 and 97.00% unknown recall.",
        "The component is accepted as end-to-end functional only when the class mapping is complete, all five prototype letters have deterministic mapping tests, the UI verdict and persisted attempt agree, the application identifies whether CNN or geometric fallback produced the verdict, and physical-device inference succeeds within a supervisor-approved latency threshold. The current implementation does not yet meet all these criteria.":
            "The component is accepted as technically integrated because the 455-output model and label contracts are validated, the UI and stored verdict use the same typed prediction, invalid and failed inference paths remain unscored, and emulator inference satisfies the functional runtime path. A physical-device benchmark and representative child-trace validation remain pending and are not implied by this acceptance.",
        "The repository notebook currently describes a different 128×128 MobileNetV2/TFJS pipeline, whereas the app ships a 64×64 custom-CNN TFLite model. The exact notebook that generated the shipped model must be recovered and archived with environment versions, dataset manifest, seed and SHA-256 hashes before final submission.":
            "The original repository notebook described an obsolete 128×128 MobileNetV2/TFJS path. A reproducible 64×64 custom-CNN pipeline was therefore rebuilt from the final architecture, and now archives environment versions, seed 42, the frozen manifest and SHA-256 identities for the protected experiment and deployed TFLite artifact.",
    }
    token_replacements = {
        "Wasalthilake and Thangathurai": "Wasalthilake and Kartheeswaran",
        "94.04% reference validation accuracy; macro-F1 0.940": "98.46% open-set accuracy; macro-F1 0.9873",
        "Adds local mobile integration, but Unicode mapping and child-field validity remain open.": "Adds open-set mobile integration; representative child-field validity remains open.",
        "94.04% on n=10,896 validation images": "98.46% on n=11,296 registered open-set test samples",
        "ECE 0.084 on reference validation data": "ECE 0.0031 on registered open-set test data",
        "Physical-device median and p95 pending": "Emulator mean 81.24 ms and p95 92.92 ms; physical device pending",
        "Held-out/reference validation images": "Protected held-out test images",
        "Implement numeric-ID-to-Unicode mapping and tests for five letters": "Completed: versioned numeric-ID-to-Unicode mapping and tests for five exposed letters",
        "Completed: versioned numeric-ID-to-Unicode mapping and tests for five exposed letters": "Completed: verified 455-label model contract and Unknown/Invalid output",
        "Firebase remains responsible for authenticated persistence, and the adult-facing Gemini feature is separated from child trace classification.": "Firebase remains responsible for authenticated persistence and authorized progress synchronization, while child trace classification stays on-device.",
        "Cloud Functions / Gemini": "Firestore synchronization / rules",
        "The project summary records approximately 87,141 training and 10,896 validation images across 454 numeric classes. Before the final thesis, the exact downloaded version, total directory counts, class distribution, license, writer metadata, random seed and checksums must be archived because public descriptions of the dataset contain differing total counts.": "The final open-set package registers 454 known Sinhala character classes plus an Unknown/Invalid class. Its 11,296-sample test set includes 400 unknown examples. Model and label hashes, test metrics and adapter evidence are archived with the repository; writer metadata remains unavailable and is treated as a validity limitation.",
        "454-class custom CNN; 64×64 grayscale; TFLite; five-letter UI": "455-output open-set CNN; 64×64 grayscale; TFLite; curriculum tracing UI",
        "Treat all 454 classes equally": "Treat known classes consistently and evaluate Unknown/Invalid separately",
        "the accuracy, class-level behaviour and confidence calibration of the Sinhala letter CNN on the protected held-out test data;": "the known-class accuracy, unknown rejection, class-level behaviour and confidence calibration of the Sinhala letter CNN on the registered open-set test data;",
        "a protected held-out CNN test set": "a registered open-set CNN test set",
        "Fix analyzer warnings/deprecation and replace stale widget test": "Completed: analyzer cleanup and replacement of the stale template test with project-specific tests",
        "Shipped model cannot currently be regenerated from the visible notebook.": "Final model can be regenerated from the registered Stage 3 pipeline; the obsolete MobileNet notebook is retained only as historical evidence.",
        "The repository notebook currently describes a different 128×128 MobileNetV2/TFJS pipeline, whereas the app ships a 64×64 custom-CNN TFLite model. The exact notebook that generated the shipped model must be recovered and archived with environment versions, dataset manifest, seed and SHA-256 hashes before final submission.": "The original repository notebook described an obsolete 128×128 MobileNetV2/TFJS path. A reproducible 64×64 custom-CNN pipeline was rebuilt from the final architecture and now archives environment versions, seed 42, the frozen manifest and SHA-256 identities for the protected experiment and deployed TFLite artifact.",
    }
    all_paragraphs = list(doc.paragraphs)
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                all_paragraphs.extend(cell.paragraphs)
    for p in all_paragraphs:
        text = p.text.strip()
        if text in replacements:
            p.clear()
            p.add_run(replacements[text])
            continue
        new = p.text
        for old, replacement in token_replacements.items():
            new = new.replace(old, replacement)
        if new != p.text:
            p.clear()
            p.add_run(new)


def chapter_four(doc: Document) -> None:
    doc.add_heading("Chapter 04 — System Requirements Specification", level=1)
    doc.add_heading("4.1 Chapter Overview", level=2)
    add_body(doc, "This chapter converts the research problem and methodology into a verifiable System Requirements Specification (SRS). It identifies stakeholders, operationalizes research constructs, defines the system boundary, records principal use cases and models the software and deployment structure. Requirements are prioritized according to their contribution to the research question: trustworthy Sinhala trace feedback, grade-aware reading support, bilingual access, privacy, and evidence generation receive priority over generic account features.")

    doc.add_heading("4.2 Stakeholder Analysis", level=2)
    add_table(doc, ["Stakeholder", "Need / responsibility", "Influence", "Design response"], [
        ("Grade 1 learner", "Large, simple controls; letter/word learning; supportive retry feedback", "High user impact", "Picture-supported choices, tracing practice and minimal text"),
        ("Grade 2 learner", "Word construction, pillam practice, short stories and comprehension", "High user impact", "Separate Grade 2 tasks and grade-filtered content"),
        ("Parent / teacher", "Understand activity, progress and areas needing practice", "High decision influence", "Authenticated dashboard, scalar trace evidence and non-diagnostic wording"),
        ("Researcher/developer", "Reproducible models, measurable tests and traceable claims", "High technical influence", "Frozen manifests, model hashes, automated tests and reports"),
        ("Supervisor / university", "Methodological validity, ethics and assessable contribution", "High governance influence", "Evidence boundaries, IEEE citations, documented limitations and approval gates"),
        ("Firebase platform", "Secure identity and synchronized evidence", "Infrastructure dependency", "Authentication, Firestore rules, role-aware links and local fallback"),
    ], font_size=7.9)

    doc.add_heading("4.3 Operationalization of the Research Objectives", level=2)
    add_table(doc, ["Objective", "Question / evidence source", "Operational requirement", "Measure"], [
        ("RO1 Identify", "Literature and two-teacher exploratory input", "Capture early-literacy difficulties without claiming prevalence", "Traceable themes and requirement rationale"),
        ("RO2 Analyze", "HCR, readability, mobile and child-design literature", "Compare candidate algorithms and architectures", "Suitability matrix and explicit trade-offs"),
        ("RO3 Develop", "Flutter repository and model assets", "Implement separated CNN, classifier, deterministic coach and progress services", "Passing functional and integration tests"),
        ("RO4 Evaluate", "Frozen test split, parity data and emulator logs", "Quantify model and deployment performance", "Accuracy, macro-F1, top-k, ECE, parity and latency"),
    ], font_size=8.1)

    doc.add_heading("4.4 Requirement Elicitation and Validation", level=2)
    add_body(doc, "Requirements were triangulated from the supplied interim documents, the two-teacher exploratory responses, recent literature, the Grade 1/2 boundary, and direct inspection of the implemented repository. A requirement was retained only when it had a user need, research rationale and feasible verification method. For example, handwriting feedback was retained because letter recognition and formation were reported by both exploratory respondents and because the HCR literature establishes technical feasibility. Conversely, diagnosis of dyslexia and automated pronunciation grading were excluded because the system lacks validated constructs, labels and clinical evidence.")
    add_callout(doc, "Validity rule", "The two-teacher input is design evidence, not a representative survey. Percentages are therefore expressed as respondent counts (2/2 or 1/2), and no population prevalence or causal inference is made.", PALE_ORANGE)

    doc.add_heading("4.5 System and Model Analysis", level=2)
    add_body(doc, "NenaPotha AI separates prediction, content review, coaching and evidence synchronization. The CNN performs isolated Sinhala handwriting classification with an explicit Unknown/Invalid output. The logistic model provides only a Grade 1/2 text-difficulty cross-check. The deterministic My Coach service ranks available practice activities from recorded attempts and recent activity; it does not generate conversation. Progress services synchronize task summaries for authorized guardians and linked teachers. This separation prevents a recommendation from being mistaken for model evidence and allows each component to be tested against a task-appropriate contract.")
    add_table(doc, ["Component", "Input", "Output", "Primary failure handling"], [
        ("CNN", "64×64 grayscale trace", "Class ID, optional verified Unicode and confidence", "Unscored attempt with retry guidance"),
        ("Text classifier", "Authored Sinhala text features", "Grade 1/2 review flag", "Keep authored grade and request human review"),
        ("Smart learning coach", "Recent attempts and skill evidence", "Ranked practice plan", "Use a safe default activity when evidence is sparse"),
        ("Progress analytics", "Task, quiz, tracing and daily activity records", "Learner/adult summaries", "Show an explicit no-data state"),
    ])

    doc.add_heading("4.6 Use Cases and Specifications", level=2)
    doc.add_picture(str(ASSETS / "use_case_diagram.png"), width=Inches(6.3))
    _center_last_picture(doc)
    add_caption(doc, "Figure 4.1. Principal learner, adult and synchronized-evidence use cases within the NenaPotha AI boundary.")
    add_table(doc, ["Use case", "Precondition", "Main success flow", "Alternative / postcondition"], [
        ("UC-01 Trace letter", "Grade 1 profile; model loaded; supported letter", "Learner draws → taps Check → CNN predicts → mapping and threshold evaluated", "Failure remains unscored; typed evidence is stored only for successful inference"),
        ("UC-02 Read story", "Profile and grade selected", "System filters story → displays text → learner completes comprehension task", "Classifier disagreement flags author review; content is not silently relabelled"),
        ("UC-03 Follow coach plan", "At least a learner profile exists", "Coach reads evidence → prioritizes suitable activity → learner opens task", "Sparse evidence produces a grade-appropriate default plan"),
        ("UC-04 Link student", "Authenticated teacher and valid student code", "Teacher submits code → relationship is validated → student appears by grade", "Invalid or expired code produces a clear error without exposing learner data"),
        ("UC-05 Review progress", "Authenticated parent/teacher access", "Load task attempts → aggregate scores and trace evidence → display guidance", "No diagnostic label; empty state explains how to collect evidence"),
    ], font_size=7.5)

    doc.add_heading("4.7 Class Model", level=2)
    doc.add_picture(str(ASSETS / "class_model_diagram.png"), width=Inches(6.4))
    _center_last_picture(doc)
    add_caption(doc, "Figure 4.2. Core domain and service class model for evidence-aware learning activities.")
    add_body(doc, "The model separates mutable learner records from service contracts. TaskAttempt is the evidence boundary: it can retain a score, timestamp and optional model metadata without retaining a raw trace image. LetterClassifierService owns tensor validation and prediction identity, SmartLearningCoachService converts evidence into a deterministic practice plan, and ProgressAnalyticsService produces learner and authorized-adult summaries.")

    doc.add_heading("4.8 Activity Diagram", level=2)
    doc.add_picture(str(ASSETS / "trace_activity_diagram.png"), width=Inches(5.45))
    _center_last_picture(doc)
    add_caption(doc, "Figure 4.3. Grade 1 letter-tracing evaluation activity and honest failure path.")

    doc.add_heading("4.9 Sequence Diagrams", level=2)
    doc.add_picture(str(ASSETS / "trace_sequence_diagram.png"), width=Inches(6.45))
    _center_last_picture(doc)
    add_caption(doc, "Figure 4.4. Sequence of local CNN inference, typed mapping and scalar evidence storage.")
    doc.add_picture(str(ASSETS / "chat_sequence_diagram.png"), width=Inches(6.45))
    _center_last_picture(doc)
    add_caption(doc, "Figure 4.5. Sequence of deterministic evidence-based coaching and activity selection.")

    doc.add_heading("4.10 Deployment and Proposed Architecture", level=2)
    doc.add_picture(str(ASSETS / "deployment_trust_boundary.png"), width=Inches(6.35))
    _center_last_picture(doc)
    add_caption(doc, "Figure 4.6. Deployment structure and privacy/trust boundaries.")
    add_body(doc, "Child-facing classification, content review and coaching decisions run on the Android device. Firebase Authentication establishes the adult identity, while Firestore synchronizes progress and validates guardian–teacher relationships. Raw trace images are not required for the synchronized record. Core learning remains available from bundled content even when the network is unavailable; cloud-backed dashboards refresh when connectivity returns.")

    doc.add_heading("4.11 Functional and Non-functional Requirements", level=2)
    add_table(doc, ["ID", "Functional requirement", "Priority", "Verification"], [
        ("FR-01", "Support only Grade 1 and Grade 2 content and profiles", "Must", "Widget and scope tests"),
        ("FR-02", "Provide independent interface-language and learning-language controls", "Must", "Localization and language-independence tests"),
        ("FR-03", "Classify supported Sinhala traces using bundled TFLite", "Must", "Model contract and integration benchmark"),
        ("FR-04", "Map model class IDs through the versioned 455-label contract", "Must", "Label and model-contract tests"),
        ("FR-05", "Provide grade-filtered reading and comprehension", "Must", "Functional reading tests"),
        ("FR-06", "Generate an evidence-based practice plan in My Coach", "Must", "Coach prioritization tests"),
        ("FR-07", "Allow teachers to link students by code and review authorized evidence", "Must", "Linking and dashboard tests"),
        ("FR-08", "Store progress and scalar trace evidence", "Must", "Serialization and aggregation tests"),
        ("FR-09", "Show adult progress without diagnostic wording", "Must", "UI/content inspection"),
        ("FR-10", "Classify authored text as a Grade 1/2 review signal", "Could", "Classifier unit tests and limitation audit"),
    ], font_size=7.5)
    add_table(doc, ["ID", "Non-functional requirement", "Target / rationale", "Evidence"], [
        ("NFR-01", "Usability", "Large touch targets, consistent navigation and child-friendly feedback", "Theme and widget tests; screenshot review"),
        ("NFR-02", "Performance", "Interactive on-device inference; report mean and p95 rather than hide tails", "Android emulator benchmark"),
        ("NFR-03", "Reliability", "Reject invalid tensor/label contracts; provide explicit fallbacks", "Negative-path tests"),
        ("NFR-04", "Privacy", "No raw trace upload; synchronize only necessary task evidence", "Architecture and code inspection"),
        ("NFR-05", "Security", "Authenticated role-aware access for guardians and linked teachers", "Configuration, rules and code inspection"),
        ("NFR-06", "Maintainability", "Central theme, typed services, versioned mapping and model card", "Repository structure and analyzer"),
        ("NFR-07", "Accessibility", "Contrast, target size and labels suitable for mobile use", "Flutter accessibility guidance [27] and future device audit"),
        ("NFR-08", "Cost", "Core system and development path use free/open-source tooling", "Technology and service-plan review"),
    ], font_size=7.6)

    doc.add_heading("4.12 Chapter Summary", level=2)
    add_body(doc, "Chapter 4 translated the research objectives into a bounded SRS. Stakeholder needs, operational measures, principal use cases, class relationships, workflows and trust boundaries were defined. The resulting specification makes model responsibility explicit and establishes the functional and quality criteria used to justify the implementation in Chapter 5 and the evaluation in Chapter 6.")
    doc.add_page_break()


def chapter_five(doc: Document) -> None:
    doc.add_heading("Chapter 05 — Implementation and Design", level=1)
    doc.add_heading("5.1 Chapter Overview", level=2)
    add_body(doc, "This chapter explains how NenaPotha AI was implemented and why each significant design decision supports the research. Generic account screens are mentioned only where they enforce a trust boundary; emphasis is placed on the two research models, deterministic evidence-based coaching, synchronized progress, child-facing interaction and deployment controls.")

    doc.add_heading("5.2 Technology Selection and Justification", level=2)
    add_table(doc, ["Technology", "Purpose", "Reason for selection", "Trade-off"], [
        ("Dart / Flutter", "Cross-platform mobile UI and local logic", "One codebase, Material components, strong test tooling and Firebase integration", "Plugin/native build dependencies"),
        ("Python / TensorFlow", "CNN audit, training and evaluation", "Reproducible numerical ecosystem and TFLite export", "Training is separate from the mobile runtime"),
        ("scikit-learn", "Interpretable Grade 1/2 logistic model", "Transparent coefficients and small deployment footprint", "Insufficient evidence at n=26 [21]"),
        ("TensorFlow Lite", "Offline CNN inference", "Low-latency mobile execution and no trace upload", "Operator/device differences require parity and runtime testing"),
        ("Firebase Auth/Firestore", "Identity and progress persistence", "Existing Flutter support and role-aware cloud synchronization", "Network dependency for synchronized data"),
        ("Deterministic coach rules", "Prioritized practice guidance", "No paid API, reproducible outputs and direct traceability to attempts", "Quality depends on the recorded evidence and rule design"),
        ("Git and model hashes", "Version and evidence control", "Links claims to exact source/model artifacts", "Requires disciplined artifact registration"),
    ], font_size=7.7)

    doc.add_heading("5.3 Component 1 — Sinhala Letter CNN", level=2)
    add_body(doc, "The training pipeline begins by hashing source images so exact duplicates cannot cross data partitions. The original 454-class model was extended with an explicit Unknown/Invalid output and invalid scribble examples. The registered open-set evaluation contains 11,296 test samples, including 400 unknown examples. A later one-writer captured adapter was accepted only after its replay-data accuracy loss remained within the deployment gate; captured-sample fit is reported separately and is not treated as independent child-test accuracy.")
    add_equation(doc, "x′ = grayscale(resize(compositeWhite(PNG), 64, 64)) / 255")
    add_body(doc, "The network uses three convolutional stages followed by a dense representation, dropout and a 455-way softmax. Adam and sparse categorical cross-entropy optimize the known-letter and invalid classes. The deployed asset accepts float32 [1,64,64,1] grayscale input and emits 455 probabilities. The additional output makes an invalid scribble a learnable alternative instead of forcing every input into one of the 454 known Sinhala character classes.")
    add_code(doc, "ALGORITHM 1 — OPEN-SET CNN PIPELINE\nvalidate image and class identity; compute SHA-256\nkeep duplicate groups inside one data partition\ntrain 454 known outputs plus Unknown/Invalid\nselect checkpoint on validation evidence\nevaluate once on registered open-set test\nadapt with consented captured samples only behind replay gate\nconvert to TFLite; verify output count, parity and runtime")
    add_body(doc, "The Flutter service validates model and label contracts before accepting inference: one 64 × 64 grayscale channel, 455 output scores and 455 ordered class labels. Prediction evidence contains model version, expected target, predicted class, confidence and latency. The UI combines open-set identity evidence with shape-overlap checks; an unsupported, low-quality or wrong-letter prediction therefore receives a retry state instead of a misleading similarity percentage. The final model file is 2,528,104 bytes with SHA-256 6D3303F14329E72ADA074C1A5C2974506778EA2681E1F4F3704655A44973565C.")

    doc.add_heading("5.4 Component 2 — Grade 1/2 Text-Difficulty Proof of Concept", level=2)
    add_body(doc, "The text component extracts word count, mean word length and mean sentence length from authored content. A binary logistic-regression equation estimates a Grade 2 score; the coefficients are ported to Dart so classification is offline and deterministic. This model does not replace the authored grade label. It acts as a quality-control signal: agreement increases confidence in content selection, while disagreement requests human review.")
    add_equation(doc, "P(Grade 2 | x) = 1 / (1 + exp(−(β₀ + β₁words + β₂meanWordLength + β₃meanSentenceLength)))")
    add_callout(doc, "Proof-of-concept boundary", "The corpus contains only 26 authored texts (9 Grade 1 and 17 Grade 2). Its 69.2% resubstitution accuracy is only 3.8 percentage points above the 65.4% majority training baseline and cannot support a production-grade generalization claim.", PALE_ORANGE)

    doc.add_heading("5.5 Evidence-based Smart Learning Coach", level=2)
    add_body(doc, "My Coach replaces the earlier conversational concept with a smaller and more defensible feature. It reads the learner's recorded completion, recent attempts and skill-level summaries, then applies deterministic priority rules to choose a short practice plan. Weak or repeatedly missed skills receive priority; mastered activities are not repeatedly promoted; and a new learner receives a grade-appropriate starter activity. Every recommendation can therefore be explained by the stored evidence that caused it.")
    add_code(doc, "ALGORITHM 2 — DETERMINISTIC COACH PLAN\nload recent task, quiz and tracing summaries\nif evidence is empty: return grade-appropriate starter activity\ncompute priority from low score, repeated errors and recency\nremove unavailable or already-mastered activities\nrank remaining activities with stable tie-breaking\nshow the reason and navigate to the selected task")
    add_body(doc, "This design avoids a paid service, unpredictable generated advice and a second child-facing dialogue interface. It also preserves offline usefulness because recommendation logic runs locally from cached evidence. The coach is not presented as a clinical, psychological or intelligence assessment. It is a transparent study-plan helper whose output remains bounded by the activities already available in NenaPotha AI.")

    doc.add_heading("5.6 Reading, Comprehension and Learning Modules", level=2)
    add_body(doc, "The Grade 1 path emphasizes letter exploration, example words, picture-supported initial-letter selection, letter matching and tracing. The Grade 2 path introduces picture-supported pillam exploration, explicit consonant-plus-sign construction, word building, pillam recognition/fill tasks, longer texts and inferential questions. Reading content is filtered by the stored grade and followed by comprehension questions. This design follows the research boundary: the CNN evaluates isolated tracing input, while authored stories and tasks remain curriculum-controlled content.")

    doc.add_heading("5.7 Progress and Evidence Design", level=2)
    add_body(doc, "Task results record the task identity, score and timestamp. Successfully inferred tracing attempts additionally store expected letter, numeric class ID, optional mapped letter, confidence, inference latency, correctness and model version. Daily activity synchronization distinguishes active learning days from app-open-only days. The learner progress service aggregates attempts, accuracy, tracing evidence and skill history, while the authenticated teacher dashboard groups linked learners by grade and exposes individual activity, task and coaching summaries. Evidence-based coaching identifies repeatedly weak items, mastered skills and recent improvement without producing a diagnostic label. Raw tracing images and direct student identifiers are excluded from the sanitized research export.")

    doc.add_heading("5.8 User-interface Design and Execution Evidence", level=2)
    add_body(doc, "The app-wide visual system uses a consistent indigo identity with semantic accents for learning, coaching and progress. Material 3 cards, rounded surfaces, minimum 48-pixel primary controls, bilingual labels and predictable five-area navigation reduce interaction cost for young learners and adults. Interface language is independent from learning language, so an English-medium learner may study Sinhala without changing every navigation label. The home story follows the selected grade rather than always displaying Grade 2 content. These choices still require accessibility scanning and supervised user testing rather than being assumed effective [27].")
    if SCREENSHOT_COMPOSITE.exists():
        doc.add_picture(str(SCREENSHOT_COMPOSITE), width=Inches(5.6))
        _center_last_picture(doc)
        add_caption(doc, "Figure 5.1. NenaPotha AI final Android implementation evidence across learner, Grade 2, progress and teacher workflows.")
    add_body(doc, "Figure 5.1 demonstrates that the final Flutter application renders the principal learner and teacher workflows on Android. The complete dated screenshot set is reproduced in Appendix I and covers language selection, authentication, learner-profile creation, the home dashboard, Grade 2 learning, progress evidence, the learner profile and teacher–student linking. These screenshots establish implementation and navigation evidence; they do not by themselves prove usability, accessibility or learning effectiveness.")

    doc.add_heading("5.9 Security, Privacy and Failure-state Implementation", level=2)
    add_bullets(doc, [
        "No chatbot, speech-recognition service or paid generative API is required by the final child workflow.",
        "Firebase Authentication and Firestore rules restrict guardian and linked-teacher access.",
        "The CNN runs locally and raw traces do not need to leave the device.",
        "A classifier loading/inference failure cannot be marked correct through a geometric fallback.",
        "Network-backed evidence screens expose loading, empty, retry and permission-denied states.",
        "Progress language uses practice indicators rather than diagnostic or clinical labels.",
        "Model version and SHA-256 identity connect app evidence to the evaluated artifact.",
    ])
    add_body(doc, "These controls operationalize the reliability, privacy, transparency and safety concerns emphasized by the NIST AI Risk Management Framework [28]. They do not eliminate all risks; they make known risks measurable and prevent unsupported output from being silently presented as evidence.")

    doc.add_heading("5.10 Chapter Summary", level=2)
    add_body(doc, "Chapter 5 described the implemented mobile, machine-learning, coaching and evidence layers. The most important engineering contribution is not any single model: it is the separation of responsibilities, leakage-aware data handling, explicit label identity, honest abstention and evidence-aware integration. Chapter 6 tests these claims quantitatively and functionally.")
    doc.add_page_break()


def chapter_six(doc: Document) -> None:
    doc.add_heading("Chapter 06 — Testing, Results and Evaluation", level=1)
    doc.add_heading("6.1 Chapter Overview", level=2)
    add_body(doc, "This chapter explains why the selected tests are appropriate, reports functional and non-functional evidence, and interprets the results against the research objectives. It distinguishes four levels of evidence: protected dataset performance, conversion parity, Android runtime integration and future participant outcomes. Only the first three are currently available.")

    doc.add_heading("6.2 Testing and Evaluation Workflow", level=2)
    add_numbered(doc, [
        "Audit source images and freeze a leakage-aware train/validation/test manifest.",
        "Train the custom CNN and low-capacity control using the same manifest.",
        "Select the checkpoint using validation data and evaluate once on protected test data.",
        "Convert the selected network and verify Keras–TFLite prediction parity.",
        "Run service, mapping, coaching, persistence and widget tests.",
        "Benchmark the exact bundled model through the Android integration path.",
        "Interpret technical evidence separately from unperformed child usability and learning studies.",
    ])

    doc.add_heading("6.3 Test Plan and Principal Test Cases", level=2)
    add_table(doc, ["ID", "Test and eligibility rationale", "Expected result", "Observed status"], [
        ("TC-01", "Analyzer — detects source-level type/lint issues", "No issues", "Pass"),
        ("TC-02", "Dataset integrity — prevents exact duplicate leakage", "All hash groups remain in one split; conflicts quarantined", "Pass"),
        ("TC-03", "Model tensor contract — prevents incompatible assets", "[1,64,64,1] input and [1,455] output accepted", "Pass"),
        ("TC-04", "Label contract — prevents output identity errors", "455 ordered labels including Unknown/Invalid", "Pass"),
        ("TC-05", "Trace decision — protects stored/UI agreement", "Expected identity, open-set and shape gates agree", "Pass"),
        ("TC-06", "Failure path — avoids false success", "Unavailable inference remains unscored", "Pass"),
        ("TC-07", "Coach prioritization — low-performing skill", "Weak available activity is ranked first with reason", "Pass"),
        ("TC-08", "Language independence — interface versus learning", "Either interface language can access Sinhala or English learning", "Pass"),
        ("TC-09", "Teacher link and empty states", "Authorized learner evidence or clear no-data/error state", "Pass"),
        ("TC-10", "Android integration benchmark — real mobile runtime path", "Load exact bundled model and complete repeated inference", "Pass on Android 14 emulator"),
    ], font_size=7.2)

    doc.add_heading("6.4 Functional Testing Results", level=2)
    add_body(doc, "All 130 current Flutter tests pass. The suite exercises language selection, five-area navigation, Grade 1/2 learning paths, verified pillam names and picture coverage, pillam detail navigation, story comprehension, progress analytics, deterministic coaching, daily activity evidence, model-contract validation, trace decisions, evidence serialization and aggregation, privacy-preserving exports, teacher linking and friendly empty/error states. Python checks validate deterministic preparation, duplicate containment, open-set evaluation and deployment registration. Static analysis reports no issues. The Android integration test loads the exact bundled model and executes native inference.")
    add_table(doc, ["Verification layer", "Latest recorded result", "Interpretation"], [
        ("Flutter static analysis", "No issues found", "Source-level quality gate passed"),
        ("Flutter unit/widget tests", "130/130 tests passed", "Specified decision, evidence and UI behaviours passed"),
        ("Python pipeline tests", "Dataset/split integrity tests pass", "Reproducibility controls behave as designed"),
        ("Android CNN integration", "Model load and 30 measured inference runs pass", "On-device path is technically feasible on emulator"),
        ("Physical-device pilot", "Workflow implemented; phone result pending", "No physical-device claim is made"),
        ("Child usability/effectiveness", "Not conducted", "No learning-gain or child-usability claim is made"),
    ])

    doc.add_heading("6.5 Non-functional Testing", level=2)
    add_table(doc, ["Quality attribute", "Method", "Result", "Limitation"], [
        ("Performance", "5 warm-ups + 30 native emulator runs", "Mean 81.24 ms; p95 92.92 ms", "Android 14 emulator, not a physical ARM phone"),
        ("Portability", "Flutter Android build/install/launch", "Pass on Android 14 emulator", "iOS and low-end phones not benchmarked"),
        ("Reliability", "Invalid labels/tensors and inference failures", "Rejected or unscored", "Long-duration stress testing pending"),
        ("Security", "Authentication, role and data-flow inspection", "Role-aware guardian and linked-teacher boundary", "Firestore rules require deployment review"),
        ("Privacy", "Data-flow and sanitized export inspection", "Raw traces and direct identifiers excluded", "Firestore rules require periodic review"),
        ("Maintainability", "Analyzer, modular services, versioned artifacts", "No analyzer issues; typed boundaries", "Test coverage percentage not claimed"),
        ("Accessibility", "Theme/widget checks and minimum target design", "Implemented design baseline", "Formal scanner and child observation pending"),
    ], font_size=7.5)

    doc.add_heading("6.6 CNN Results", level=2)
    doc.add_picture(str(ASSETS / "cnn_protected_test_metrics.png"), width=Inches(6.35))
    _center_last_picture(doc)
    add_caption(doc, "Figure 6.1. Registered open-set CNN performance on 11,296 test samples.")
    add_table(doc, ["Measure", "Registered result", "Research interpretation", "Boundary"], [
        ("Overall accuracy", "98.46%", "High aggregate performance over known and invalid inputs", "Reference test distribution"),
        ("Letter-only accuracy", "98.51%", "Known Sinhala classes are usually identified correctly", "Not child-touchscreen accuracy"),
        ("Macro-F1", "98.73%", "Strong class-balanced precision/recall", "Class support still varies"),
        ("Top-3 accuracy", "99.43%", "Correct known class is rarely outside three candidates", "UI still applies expected-target gate"),
        ("Unknown recall", "97.00%", "Most registered invalid samples are rejected", "400 unknown test samples"),
        ("Invalid false acceptance", "3.00%", "A small residual risk of invalid-as-letter prediction remains", "Requires UI shape and identity gates"),
        ("Calibration error", "0.0031", "Probabilities are well aligned on the registered test", "Distribution shift remains possible"),
    ], font_size=7.4)
    for path, caption in [
        (ROOT / "deliverables" / "stage6_evaluation" / "custom_cnn_training_history.png", "Figure 6.2. Custom CNN training and validation history."),
        (ROOT / "deliverables" / "stage6_evaluation" / "per_class_recall_analysis.png", "Figure 6.3. Distribution of per-class recall and weakest classes."),
        (ROOT / "deliverables" / "stage6_evaluation" / "top_confusion_pairs.png", "Figure 6.4. Most frequent directed class confusions on protected test data."),
        (ROOT / "deliverables" / "stage6_evaluation" / "deployment_latency_and_parity.png", "Figure 6.5. TensorFlow Lite conversion parity and Android emulator latency."),
    ]:
        if path.exists():
            doc.add_picture(str(path), width=Inches(6.2))
            _center_last_picture(doc)
            add_caption(doc, caption)
    add_body(doc, "The registered open-set result is the headline CNN evidence because it evaluates both known letters and invalid inputs under one 455-output contract. It directly addresses the earlier failure mode in which a scribble had to be classified as some valid letter. The one-writer adaptation improved fit to the author's captured traces from 16.95% to 72.88%, while held-out replay accuracy changed from 97.02% to 95.85%, a 1.17 percentage-point drop that passed the deployment gate. The 59 mapped captured samples used for fitting are not an independent evaluation set, and the result cannot be generalized to children or other writers.")

    doc.add_heading("6.7 Conversion and Deployment Results", level=2)
    add_table(doc, ["Evidence", "Result"], [
        ("Evaluated TFLite size", "2,528,104 bytes (approximately 2.41 MiB)"),
        ("TFLite SHA-256", "6D3303F14329E72ADA074C1A5C2974506778EA2681E1F4F3704655A44973565C"),
        ("Output labels", "455 lines; SHA-256 7A4E0269FB58F039EBDC247C0A6EEC76764D82351467DA4D98F93D3378935B91"),
        ("Parity sample count", "100 registered samples"),
        ("TFLite top-1 parity", "100.00%"),
        ("Android 14 emulator native inference", "Mean 81.24 ms; p50 78.60 ms; p95 92.92 ms over 30 measured runs"),
        ("End-to-end inference", "Mean 85.38 ms; p95 96.90 ms"),
    ])
    add_body(doc, "The exact TFLite hash and 455-line label hash identify the artifacts bundled in the Flutter application. This identity check matters because a benchmark of a different model or reordered labels would not validate the deployed behavior. The 100-sample parity check preserved every top-1 class, and the Android test confirmed the expected input and output tensors before measuring latency. The benchmark supports interactive emulator feasibility, not performance on every physical device.")

    doc.add_heading("6.8 Text-classifier Results", level=2)
    add_body(doc, "The logistic text classifier obtained 69.2% training accuracy on 26 samples. The majority-class rule would obtain 65.4% on the same labels, so the observed advantage is small and measured on the data used for fitting. A random split would produce too few cases for a stable conclusion, while standard cross-validation would still reuse nearly identical authored patterns. The result supports only the feasibility of implementing an interpretable pipeline. It does not demonstrate that the model can grade unseen Sinhala school texts.")
    add_table(doc, ["Property", "Current evidence", "Required final evidence"], [
        ("Corpus", "26 authored samples: 9 Grade 1, 17 Grade 2", "Substantially larger, balanced, teacher-labelled corpus"),
        ("Features", "Word count, mean word length, mean sentence length", "Sinhala morphology, vocabulary, syllable/akshara and cohesion features"),
        ("Performance", "69.2% resubstitution accuracy", "Nested/grouped cross-validation with macro-F1 and uncertainty"),
        ("Use", "Human-review flag", "Remain advisory until independently validated"),
    ])

    doc.add_heading("6.9 Discussion", level=2)
    add_body(doc, "The results answer the technical part of the research question. A leakage-aware CNN can provide fast offline class predictions within a Flutter Grade 1 tracing workflow, and explicit numeric-to-Unicode mapping prevents a high model score from hiding an application-level identity error. Compared with prior Sinhala HCR studies [6]–[8], direct numerical superiority cannot be claimed because class sets, writers and split protocols differ. The main contribution is the auditable split, protected test, conversion identity and integrated failure semantics.")
    add_body(doc, "The text component illustrates the opposite evidence condition. Its transparent equation is attractive for teachers and mobile deployment, consistent with interpretable low-resource readability work [9]–[15] and word-level decoding research [30], yet the sample is too small for credible generalization. Retaining it as a content-review signal is more defensible than presenting 69.2% as test accuracy. This contrast demonstrates why each AI component must be evaluated on its own data and construct.")
    add_body(doc, "The deterministic coach improves functional coverage without introducing a third predictive model. Its plan is reproducible from task evidence, available offline and bounded to implemented activities. This makes the rationale inspectable by a teacher and prevents generated language from determining grades, diagnoses or stored outcomes. The design is intentionally simpler than a chatbot because the research contribution concerns handwriting recognition, content difficulty and learning evidence rather than open-domain conversation.")
    add_body(doc, "The broader educational question remains open. Reviews and controlled literacy-training evidence show promise but also heterogeneity and context-dependent effects [4], [29]. NenaPotha AI's technical success therefore cannot be translated into literacy gain without an ethics-approved field design. Future evaluation must measure usability and learning separately from recognition accuracy, retain children by writer group during analysis, and compare against an active conventional-practice condition.")

    doc.add_heading("6.10 Threats to Validity", level=2)
    add_table(doc, ["Validity", "Threat", "Consequence", "Mitigation / future action"], [
        ("Internal", "Unknown writer overlap and near duplicates", "Test result may be optimistic", "Obtain writer IDs or perceptual/grouped audit"),
        ("Construct", "Isolated glyph class ≠ stroke formation quality", "Feedback may not measure intended writing skill", "Add stroke/path rubric and expert judgement"),
        ("External", "Reference images differ from child touchscreen traces", "Field accuracy unknown", "Approved multi-device child/adult pilot"),
        ("Conclusion", "Single seeded CNN run", "Variation across initialization unknown", "Repeat registered experiment with multiple seeds"),
        ("Text model", "Tiny authored and imbalanced corpus", "69.2% cannot generalize", "Expanded independent annotation and grouped validation"),
        ("Deployment", "Emulator rather than physical low-end ARM devices", "Latency/thermal/memory behaviour unknown", "Run provided physical-device protocol"),
        ("Human factors", "No completed UAT or learning trial", "Usability/effectiveness unproven", "Supervisor/ethics-approved staged field study"),
    ], font_size=7.5)

    doc.add_heading("6.11 Chapter Summary", level=2)
    add_body(doc, "Chapter 6 reported the verified testing and evaluation outcomes. The open-set CNN test result, adaptation gate, TensorFlow Lite parity, artifact identity, 130 automated tests and emulator benchmark support the technical feasibility of NenaPotha AI. The text classifier remains a transparent proof of concept, and participant outcomes remain unmeasured. These evidence boundaries guide the objective assessment and future recommendations in Chapter 7.")
    doc.add_page_break()


def chapter_seven(doc: Document) -> None:
    doc.add_heading("Chapter 07 — Concluding Remarks", level=1)
    doc.add_heading("7.1 Research Conclusion", level=2)
    add_body(doc, "This research designed, developed and technically evaluated NenaPotha AI, a bilingual Grade 1–2 mobile reading and comprehension assistant that integrates offline Sinhala letter recognition, grade-aware content review, deterministic coaching and synchronized learning evidence. The study demonstrates that trustworthy integration requires more than model accuracy: duplicate-aware data management, explicit label identity, open-set rejection, conversion parity, failure-state design, privacy boundaries and claim discipline are equally important.")

    doc.add_heading("7.2 Accomplishment of the Research Objectives", level=2)
    add_table(doc, ["Objective", "Triangulated evidence", "Achievement"], [
        ("RO1 — Identify gaps", "Recent literature, official Sri Lankan context, exploratory teacher input and repository audit", "Achieved: defined bounded HCR, readability and integration gaps"),
        ("RO2 — Analyze approaches", "Comparative HCR/readability/mobile/architecture review and suitability decisions", "Achieved: justified open-set CNN, logistic proof of concept and hybrid local/cloud deployment"),
        ("RO3 — Develop artifact", "Flutter modules, 455-output TFLite CNN, Dart classifier, deterministic coach and evidence services", "Achieved within the Grade 1/2 learning scope"),
        ("RO4 — Evaluate", "11,296-sample open-set test, adaptation gate, parity, automated tests and emulator benchmark", "Technically achieved; child field effectiveness remains future work"),
    ], font_size=8.0)

    doc.add_heading("7.3 Problems Encountered and Resolutions", level=2)
    add_table(doc, ["Problem", "Why it mattered", "Resolution / lesson"], [
        ("Publisher split leakage", "Duplicated images could inflate evaluation", "SHA-256 audit, conflict quarantine and deterministic regrouping"),
        ("Numeric labels compared with Unicode", "Could mark correct traces as wrong or guess identities", "Versioned mapping for five independently verified letters"),
        ("Invalid scribbles forced into known classes", "A closed-set model could return confident but wrong letters", "Added an Unknown/Invalid output and combined identity with shape gates"),
        ("Tiny Grade 1/2 text corpus", "No credible hold-out or cross-validation conclusion", "Downgraded to proof-of-concept human-review signal"),
        ("Captured-writer distribution shift", "Reference-image accuracy did not ensure touchscreen performance", "One-writer adaptation admitted only after a replay-retention gate"),
        ("Feature complexity and reliability", "Voice and chat features expanded the failure surface beyond the research components", "Removed them and retained deterministic My Coach guidance"),
        ("Physical phone connection/build delay", "Final device performance could not be recorded", "Reproducible benchmark script retained; claim limited to emulator"),
    ], font_size=7.7)

    doc.add_heading("7.4 Self-reflection and Research Ideology", level=2)
    add_body(doc, "The strongest learning from this study was that a result is valuable only when its evidence boundary is clear. The open-set evaluation addresses invalid-input behavior that closed-set accuracy could not describe. The one-writer adapter is therefore reported as captured-sample fit plus replay retention, not as child accuracy. The same principle changed the treatment of the text classifier: instead of calling 69.2% 'accuracy' without qualification, the final design labels it resubstitution performance and restricts its role.")
    add_body(doc, "The project also changed my view of AI integration. A system does not become more useful by adding every available AI interface. NenaPotha works more responsibly when deterministic learning tasks, the handwriting CNN, the text classifier, coaching rules and evidence synchronization remain separate. This architecture improves reproducibility, cost control, privacy and the ability to explain failures to a supervisor, teacher and parent.")

    doc.add_heading("7.5 Benefits and Learning Curve", level=2)
    add_bullets(doc, [
        "Applied design-science reasoning to connect a social need, an artifact and measurable evaluation.",
        "Learned to audit datasets with hashes and distinguish validation selection from protected testing.",
        "Implemented and verified model conversion rather than assuming desktop/mobile equivalence.",
        "Developed Flutter service boundaries, tests, Firebase integration and bilingual interaction design.",
        "Improved research writing through IEEE citation, evidence traceability and explicit limitations.",
        "Gained practical understanding of child data ethics, App Check, credential protection and non-diagnostic language.",
    ])

    doc.add_heading("7.6 Business Insight and Real-world Application", level=2)
    add_body(doc, "ReadBuddy AI could support homework practice, learning-recovery programmes, teacher-created reading libraries and low-connectivity community learning. A sustainable deployment should prioritize institutional or school partnerships rather than behavioural advertising or sale of child data. Core offline activities can remain free, while optional organizational services could include curriculum content management, anonymized cohort reporting, deployment support and educator training. Any commercialization must preserve guardian control, data minimization and human oversight.")
    add_body(doc, "The architecture also generalizes beyond the immediate application. Other low-resource scripts can adopt the same pattern: a task-specific on-device model with explicit label identity, an interpretable content-quality check, deterministic coaching and role-aware evidence synchronization. The research value lies in the pattern and evidence contract, not only the current Sinhala classes.")

    doc.add_heading("7.7 Future Recommendations", level=2)
    add_numbered(doc, [
        "Complete an authoritative numeric-class-to-Unicode mapping for all curriculum-relevant classes, independently reviewed by Sinhala language experts.",
        "Repeat the registered CNN experiment across multiple seeds and add writer-grouped or perceptual-near-duplicate evaluation where metadata permits.",
        "Run the provided benchmark on low-, mid- and high-range physical Android devices and report release APK size, load time, p50/p95 latency, memory and offline behaviour.",
        "Conduct an adult/synthetic tracing pilot first; involve children only after institutional ethics, school permission, guardian consent and child assent.",
        "Collect representative Grade 1/2 touchscreen traces, preserve writer groups and evaluate per-letter recall, calibration and abstention.",
        "Create a larger balanced Sinhala readability corpus with independent teacher labels and inter-rater agreement; add akshara, morphology, vocabulary and cohesion features.",
        "Evaluate deterministic coaching priorities with teachers and compare recommended activities against expert-selected practice plans.",
        "Perform formal Flutter accessibility checks, teacher/parent UAT and a preregistered active-control learning study before claiming educational impact.",
        "Use versioned remote configuration only for controlled curriculum and rule updates, with rollback and review before release.",
        "Publish the de-identified split manifest, code, model card and evaluation protocol where dataset licensing permits, improving reproducibility for Sinhala HCR research.",
    ])

    doc.add_heading("7.8 Final Statement", level=2)
    add_body(doc, "ReadBuddy AI is a technically functional and research-grounded prototype for Grade 1 and Grade 2 early literacy. Its custom CNN performs strongly on a protected reference test set and runs through the Android on-device path; the remaining components broaden learning support without overstating their evidence. The project is ready for supervisor-guided physical-device and ethical pilot work. Its most defensible contribution is a transparent route from low-resource data to accountable mobile feedback, with clear boundaries around what has—and has not—been proven.")
    doc.add_page_break()


def references(doc: Document) -> None:
    doc.add_heading("References — IEEE Style", level=1)
    refs = [
        '[1] UNICEF Sri Lanka, “MOE and UNICEF spearhead national initiative to recover lost learning for 1.6 million primary school children across Sri Lanka,” Aug. 16, 2023. [Online]. Available: https://www.unicef.org/srilanka/press-releases/moe-and-unicef-spearhead-national-initiative-recover-lost-learning-16-million. [Accessed: Sep. 4, 2026].',
        '[2] World Bank, “Sri Lanka Learning Poverty Brief,” version 2, Apr. 2024. [Online]. Available: https://documents1.worldbank.org/curated/en/099090524113181787/pdf/P1792091cc4ce70d01bda7185ee313a94c7.pdf. [Accessed: Sep. 4, 2026].',
        '[3] Ministry of Education, Higher Education and Vocational Education, Sri Lanka, “Transform Education: Transform Sri Lanka,” 2025. [Online]. Available: https://moe.gov.lk/wp-content/uploads/2025/07/Education-Reforms-Sri-Lanka-PPT.pdf. [Accessed: Sep. 4, 2026].',
        '[4] G. F. Bautista, P. Ghesquière, and J. Torbeyns, “Stimulating preschoolers’ early literacy development using educational technology: A systematic literature review,” Int. J. Child-Comput. Interact., vol. 39, Art. no. 100620, Mar. 2024, doi: 10.1016/j.ijcci.2023.100620.',
        '[5] P. B. Gough and W. E. Tunmer, “Decoding, reading, and reading disability,” Remedial Spec. Educ., vol. 7, no. 1, pp. 6–10, 1986, doi: 10.1177/074193258600700104.',
        '[6] J. Mariyathas, V. Shanmuganathan, and B. Kuhaneswaran, “Sinhala handwritten character recognition using convolutional neural network,” in Proc. 5th Int. Conf. Inf. Technol. Res. (ICITR), 2020, pp. 1–6, doi: 10.1109/ICITR51448.2020.9310914.',
        '[7] W. V. S. K. Wasalthilake and T. Kartheeswaran, “Improved handwritten character recognition for Sinhala language based on convolutional neural networks,” in Proc. IEEE 7th Int. Conf. Convergence Technol. (I2CT), Mumbai, India, 2022, pp. 1–6, doi: 10.1109/I2CT54291.2022.9824233.',
        '[8] M. L. Karunarathne, C. P. Wijesiriwardana, K. M. I. Nishantha, and W. G. C. W. Kumara, “Efficiency and accuracy in Sinhala handwritten character recognition: A Gabor-initialized CNN perspective,” Sri Lankan J. Technol., vol. 5, no. 1, pp. 13–24, 2024.',
        '[9] J. M. Imperial and E. Kochmar, “BasahaCorpus: An expanded linguistic resource for readability assessment in Central Philippine languages,” in Proc. EMNLP, 2023, pp. 6302–6309, doi: 10.18653/v1/2023.emnlp-main.388.',
        '[10] J. M. Imperial and E. Kochmar, “Automatic readability assessment for closely related languages,” in Findings ACL, 2023, pp. 5371–5386, doi: 10.18653/v1/2023.findings-acl.331.',
        '[11] T. Naous, M. J. Ryan, A. Lavrouk, M. Chandra, and W. Xu, “ReadMe++: Benchmarking multilingual language models for multi-domain readability assessment,” in Proc. EMNLP, 2024, pp. 12230–12266, doi: 10.18653/v1/2024.emnlp-main.682.',
        '[12] F. Liu, T. Jin, and J. S. Y. Lee, “Automatic readability assessment for sentences: Neural, hybrid and large language models,” Lang. Resources Eval., vol. 59, pp. 2265–2296, 2025, doi: 10.1007/s10579-024-09800-5.',
        '[13] D. Kazakov, S. Minkov, R. Margova, I. Temnikova, and I. Emanuilov, “Towards creating a Bulgarian readability index,” in Proc. 1st Workshop Advancing NLP for Low-Resource Languages, Varna, Bulgaria, 2025, pp. 192–200, doi: 10.26615/978-954-452-100-4-018.',
        '[14] X. Yang, J. Yang, and X. Li, “Chinese automatic readability assessment using adaptive pre-training and linguistic feature fusion,” in Proc. 31st Int. Conf. Comput. Linguistics (COLING), Abu Dhabi, UAE, 2025, pp. 9013–9024. [Online]. Available: https://aclanthology.org/2025.coling-main.605/.',
        '[15] I. Pilán, S. Vajjala, and E. Volodina, “A readable read: Automatic assessment of language learning materials based on linguistic complexity,” Int. J. Comput. Linguistics Appl., vol. 7, no. 1, pp. 143–159, 2016.',
        '[16] J. Lee et al., “On-device neural net inference with mobile GPUs,” in Workshop Efficient Deep Learning for Computer Vision, CVPR, 2019. [Online]. Available: https://arxiv.org/abs/1907.01989.',
        '[17] C. Guo, G. Pleiss, Y. Sun, and K. Q. Weinberger, “On calibration of modern neural networks,” in Proc. 34th Int. Conf. Mach. Learn., vol. 70, 2017, pp. 1321–1330.',
        '[18] R. R. Selvaraju et al., “Grad-CAM: Visual explanations from deep networks via gradient-based localization,” in Proc. IEEE Int. Conf. Comput. Vis. (ICCV), 2017, pp. 618–626.',
        '[19] K. Peffers, T. Tuunanen, M. A. Rothenberger, and S. Chatterjee, “A design science research methodology for information systems research,” J. Manage. Inf. Syst., vol. 24, no. 3, pp. 45–77, 2007, doi: 10.2753/MIS0742-1222240302.',
        '[20] J. W. Creswell and J. D. Creswell, Research Design: Qualitative, Quantitative, and Mixed Methods Approaches, 5th ed. Thousand Oaks, CA, USA: SAGE, 2018.',
        '[21] F. Pedregosa et al., “Scikit-learn: Machine learning in Python,” J. Mach. Learn. Res., vol. 12, pp. 2825–2830, 2011.',
        '[22] S. L. Amal, “Sinhala Letter 454,” Kaggle dataset, 2022. [Online]. Available: https://www.kaggle.com/datasets/sathiralamal/sinhala-letter-454. [Accessed: Sep. 4, 2026].',
        '[23] P. Ramos, R. Ramos, and N. Garcia, “Data leakage in visual datasets,” in Proc. IEEE/CVF Int. Conf. Comput. Vis. Workshops, 2025, pp. 6368–6378.',
        '[24] Y. K. Adimoolam, C. Poullis, and M. Averkiou, “Data leakage detection and de-duplication in large scale geospatial image datasets,” in Proc. IEEE/CVF Conf. Comput. Vis. Pattern Recognit., 2026.',
        '[25] Google, “Firebase Authentication,” Firebase Documentation, 2026. [Online]. Available: https://firebase.google.com/docs/auth. [Accessed: Oct. 4, 2026].',
        '[26] Google, “Securely validate data in Cloud Firestore,” Firebase Documentation, 2026. [Online]. Available: https://firebase.google.com/docs/firestore/security/rules-conditions. [Accessed: Oct. 4, 2026].',
        '[27] Flutter, “Accessibility testing,” Flutter Documentation, 2026. [Online]. Available: https://docs.flutter.dev/ui/accessibility/accessibility-testing. [Accessed: Sep. 29, 2026].',
        '[28] E. Tabassi, Artificial Intelligence Risk Management Framework (AI RMF 1.0), NIST AI 100-1. Gaithersburg, MD, USA: National Institute of Standards and Technology, 2023, doi: 10.6028/NIST.AI.100-1.',
        '[29] T. Glatz et al., “Dynamic assessment of the effectiveness of digital game-based literacy training in beginning readers: A cluster randomised controlled trial,” PeerJ, vol. 11, e15499, 2023, doi: 10.7717/peerj.15499.',
        '[30] C. Pinney, C. Kennington, M. S. Pera, K. L. Wright, and J. A. Fails, “Incorporating word-level phonemic decoding into readability assessment,” in Proc. LREC-COLING, 2024, pp. 8998–9009.',
    ]
    for ref in refs:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Cm(0.8)
        p.paragraph_format.first_line_indent = Cm(-0.8)
        p.paragraph_format.line_spacing = 1.0
        p.paragraph_format.space_after = Pt(5)
        p.add_run(ref)
    doc.add_page_break()


def appendices(doc: Document) -> None:
    doc.add_heading("Appendix A — Literature Review Summary Matrix", level=1)
    add_body(doc, "This matrix records the evidence used to derive the research gap in Section 3. It is a condensed audit trail rather than a substitute for the critical synthesis in the main text.")
    add_table(doc, ["Study", "Data / method", "Relevant finding", "Limitation and resulting gap"], [
        ("Dorris et al. (2024) [4]", "Systematic review of mobile-device use in primary education", "Small positive average literacy/numeracy effect with substantial heterogeneity", "Does not validate this Sinhala Grade 1/2 artifact or its handwriting feedback"),
        ("Mariyathas et al. (2020) [6]", "CNN-based Sinhala handwriting recognition", "Demonstrates feasibility of learned Sinhala character features", "Different data and deployment conditions; no evidence contract for the present mobile tracing flow"),
        ("Wasalthilake and Kartheeswaran (2022) [7]", "Pixel-length and CNN approaches", "CNN improves over hand-engineered recognition assumptions", "Does not resolve mobile label identity, leakage control or child-trace validity"),
        ("Karunarathne et al. (2024) [8]", "Gabor-initialized CNN", "Shows continued value of CNN feature learning for Sinhala HCR", "Reported evaluation cannot be transferred directly to this 454-class artifact"),
        ("Imperial and Kochmar (2023) [9], [10]", "Low-resource and cross-lingual readability assessment", "Language-specific resources and validation matter", "No expert-labelled Sinhala Grade 1/2 corpus matching this project"),
        ("Naous et al. (2024) [11]", "9,757 human-labelled sentences across five languages and domains", "Multilingual readability performance varies by language and domain", "Sinhala and early-primary curriculum text are absent"),
        ("Liu et al. (2025) [12]", "Neural, hybrid and large-language-model readability comparison", "Model choice depends on data, features and validation context", "Large-model performance does not justify an unvalidated Sinhala classifier"),
        ("Ramos et al. (2025) [23]; Adimoolam et al. (2026) [24]", "Visual-dataset leakage and duplicate-detection studies", "Duplicate contamination can invalidate apparently strong results", "Motivates exact-hash grouping and protected testing in this study"),
        ("Glatz et al. (2023) [29]", "Cluster-randomised digital literacy-training evaluation", "Demonstrates that learning impact requires controlled learner-level evidence", "Technical model accuracy alone cannot establish educational effectiveness"),
        ("Pinney et al. (2024) [30]", "Word-level phonemic-decoding features for readability", "Connects decoding evidence with readability assessment", "Requires language- and learner-appropriate validation before Sinhala use"),
    ], font_size=7.7)

    doc.add_page_break()
    doc.add_heading("Appendix B — Requirements Gathering Instruments", level=1)
    add_body(doc, "The two-teacher preliminary discussion was used only as exploratory requirements input. It was not treated as a representative survey and no inferential claim is based on two respondents. The following semi-structured guide records the topics that should be discussed and verified with the supervisor.")
    add_numbered(doc, [
        "Which Grade 1 and Grade 2 Sinhala reading, letter and word activities create the greatest need for additional practice?",
        "What errors should a tracing activity detect, and what feedback is suitable for a young learner?",
        "How should Grade 1 and Grade 2 content differ in vocabulary, sentence length and task complexity?",
        "Which learner-progress indicators are genuinely useful to a parent or teacher?",
        "Which interface-language and learning-language combinations are required for Sinhala- and English-medium families?",
        "What safeguards are required before learner progress is shared with a guardian or linked teacher?",
        "Which teacher actions are needed: student linking, activity review, weak-skill identification and coaching notes?",
        "Which functions should continue offline when an internet connection is unavailable?",
    ])

    doc.add_page_break()
    doc.add_heading("Appendix C — Data Collection Instruments", level=1)
    add_body(doc, "Technical evaluation used registered machine-readable records rather than human-participant outcome data. The following fields define the evidence captured for reproducibility and software evaluation.")
    add_table(doc, ["Instrument", "Recorded fields", "Purpose"], [
        ("Dataset manifest", "relative path, numeric class, SHA-256, split, conflict status", "Prevent duplicate leakage and reproduce the protected split"),
        ("Training history", "epoch, training/validation loss, top-1 accuracy, top-k accuracy", "Select the checkpoint using validation evidence"),
        ("Protected evaluation", "accuracy, macro precision/recall/F1, top-2/top-3, ECE, per-class recall", "Measure generalization on the untouched test split"),
        ("Conversion parity record", "sample ID, Keras class, TFLite class, confidence, agreement", "Verify deployment-format consistency"),
        ("Task-attempt record", "student ID, grade, task type, item, correct/total, timestamp, model evidence", "Support local/teacher-facing progress summaries"),
        ("Runtime benchmark", "device, OS, model hash, load time, mean/p50/p95 inference", "Document deployment performance under a defined environment"),
    ], font_size=8.0)

    doc.add_page_break()
    doc.add_heading("Appendix D — Participant Information, Consent and Ethical Gate", level=1)
    add_callout(doc, "Current status", "No ethics-approved child usability or learning-effectiveness study was completed. This appendix is a gate and template for future work, not evidence of participant approval or consent.")
    add_bullets(doc, [
        "Obtain supervisor approval, institutional ethical clearance and school authorization before recruitment.",
        "Provide a plain-language guardian information sheet, guardian consent form and age-appropriate child assent form.",
        "State participation, withdrawal, recording, storage, retention and deletion arrangements before data collection.",
        "Pseudonymize learner identity and retain raw handwriting only when scientifically necessary and approved.",
        "Separate recognition, usability and learning outcomes; never label intelligence, disability or clinical status.",
        "Begin with adult or synthetic traces and predefined technical stopping rules before any child pilot.",
    ])

    doc.add_page_break()
    doc.add_heading("Appendix E — Dataset and Supplementary Evidence", level=1)
    add_table(doc, ["Dataset characteristic", "Registered value"], [
        ("Publisher image paths audited", "108,933"),
        ("Usable unique samples after validation and conflict handling", "79,788"),
        ("Open-set class count", "454 known Sinhala classes + one Unknown/Invalid output"),
        ("Registered open-set test", "11,296 samples, including 400 unknown/invalid examples"),
        ("Split policy", "Exact SHA-256 groups retained within one deterministic partition"),
        ("Input format", "64 × 64 single-channel grayscale"),
        ("Deployment contract", "455 ordered labels; explicit Unknown/Invalid class"),
        ("Text proof-of-concept corpus", "26 authored Grade 1/2 texts; no held-out generalization claim"),
    ])
    add_body(doc, "Large raw image collections are not printed in the thesis. The frozen manifest, hashes, model card and evaluation JSON files in the project repository provide the auditable supplementary record.")

    doc.add_page_break()
    doc.add_heading("Appendix F — Software Requirements Specification", level=1)
    add_table(doc, ["ID", "Functional requirement", "Verification"], [
        ("FR-01", "Allow a guardian to create/select a Grade 1 or Grade 2 learner profile", "Authentication/profile widget and Firestore tests"),
        ("FR-02", "Teach Sinhala and English literacy independently of interface language", "Language-independence widget tests"),
        ("FR-03", "Provide curriculum-bounded letters, words, pillam, stories and progressive tasks", "Content and learning-path tests"),
        ("FR-04", "Evaluate supported Sinhala traces using CNN identity and shape evidence", "Mapping, threshold and similarity tests"),
        ("FR-05", "Persist task, quiz, reading and daily-activity evidence", "Service and serialization tests"),
        ("FR-06", "Allow a teacher to link a student by code and review evidence", "Firestore rule/service and dashboard workflow"),
        ("FR-07", "Generate deterministic evidence-based practice guidance", "Coach prioritization and navigation tests"),
        ("FR-08", "Present friendly loading, no-data, offline and failure states", "Service and widget tests"),
    ], font_size=8.0)
    add_table(doc, ["ID", "Non-functional requirement", "Target / evidence"], [
        ("NFR-01", "Usability", "Large touch targets, predictable navigation, child-friendly feedback"),
        ("NFR-02", "Privacy", "No raw trace upload; role-aware access to synchronized evidence"),
        ("NFR-03", "Reliability", "Model failure abstains rather than awarding a correct score"),
        ("NFR-04", "Performance", "Recorded emulator mean 81.24 ms and p95 92.92 ms CNN inference"),
        ("NFR-05", "Maintainability", "Separated CNN, text classifier, coach and progress services"),
        ("NFR-06", "Testability", "No analyzer issues and 130/130 Flutter tests passing"),
    ], font_size=8.0)

    doc.add_page_break()
    doc.add_heading("Appendix G — System Design and Modelling Diagrams", level=1)
    add_body(doc, "Figures G.1 and G.2 reproduce the system and deployment views at appendix scale. They document component responsibility and the boundary between on-device educational processing and protected Firebase services.")
    for path, caption in [
        (ASSETS / "system_architecture.png", "Figure G.1. Detailed NenaPotha AI system architecture and information flow."),
        (ASSETS / "deployment_trust_boundary.png", "Figure G.2. Deployment architecture and privacy trust boundaries."),
    ]:
        if path.exists():
            doc.add_picture(str(path), width=Inches(5.7))
            _center_last_picture(doc)
            add_caption(doc, caption)

    doc.add_page_break()
    doc.add_heading("Appendix H — UI/UX Design and Prototype Rationale", level=1)
    add_body(doc, "The final interface follows a child-facing design system while retaining separate adult authentication and teacher views. The design was iterated from dense text-led screens to colour-coded cards, picture-supported activities, larger labels and predictable bottom navigation.")
    add_table(doc, ["Design decision", "Reason", "Implemented evidence"], [
        ("Separate interface and learning language", "An English-medium family may still need to learn Sinhala, and vice versa", "Independent language controls and language-independence tests"),
        ("Grade-specific learning paths", "Grade 2 should extend rather than duplicate Grade 1", "Five Grade 1 and six Grade 2 sequential levels"),
        ("Pictures with early vocabulary", "Reduces dependence on reading the instruction itself", "Offline TaskPicture assets for Grade 1, Grade 2 and Sinhala clues"),
        ("Colour and large touch surfaces", "Supports recognition and motor accessibility for young users", "Rounded cards, high-contrast state and primary controls ≥48 px"),
        ("Supportive feedback", "Avoids discouraging or diagnostic wording", "Retry, encouragement and evidence-aware scoring states"),
        ("Adult/teacher separation", "Children should not manage administrative data", "Role-aware login, student linking and teacher dashboard"),
    ], font_size=8.0)

    doc.add_page_break()
    doc.add_heading("Appendix I — Implemented System Screenshots", level=1)
    add_body(doc, "Figures I.1–I.14 are dated Android-emulator captures from the final application workflow supplied on 4 October 2026. They are ordered from authentication and language selection through learner activities, progress and teacher analysis. Demonstration identities and join codes are test data. The figures document implementation state; they are not participant-study evidence.")
    screenshot_items = []
    for index, (filename, caption) in enumerate(SCREENSHOT_MANIFEST, start=1):
        path = SCREENSHOTS_DIR / filename
        if path.exists():
            screenshot_items.append((path, f"Figure I.{index}. {caption}."))
    if SCREENSHOT_APPENDIX_COMPOSITE.exists():
        screenshot_items.append((SCREENSHOT_APPENDIX_COMPOSITE, "Figure I.14. Composite overview of the final learner, Grade 2, progress and teacher workflows."))
    for pair_start in range(0, len(screenshot_items), 2):
        pair = screenshot_items[pair_start:pair_start + 2]
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        for item_index, (path, _) in enumerate(pair):
            if item_index:
                p.add_run("    ")
            p.add_run().add_picture(str(path), width=Inches(2.65))
        for _, caption in pair:
            add_caption(doc, caption)
        if pair_start + 2 < len(screenshot_items):
            doc.add_page_break()

    doc.add_page_break()
    doc.add_heading("Appendix J — Algorithm, Model and Technical Configuration", level=1)
    add_table(doc, ["CNN configuration", "Registered value"], [
        ("Input / output", "float32 [1,64,64,1] → float32 [1,455]"),
        ("Architecture", "Three convolution stages; dense representation; dropout; softmax 455"),
        ("Optimization", "Adam, learning rate 0.001, sparse categorical cross-entropy"),
        ("Training", "Batch 64; maximum 40 epochs; validation-loss early stopping"),
        ("Preprocessing", "Decode, grayscale, crop-normalize, resize 64 × 64, normalize intensity"),
        ("Decision gate", "Expected target identity, Unknown/Invalid output and shape evidence; otherwise abstain/retry"),
        ("Deployment", "2,528,104-byte TensorFlow Lite model; SHA-256 6D3303F14329E72ADA074C1A5C2974506778EA2681E1F4F3704655A44973565C"),
    ])
    add_table(doc, ["Text-difficulty configuration", "Registered value"], [
        ("Purpose", "Grade 1/2 authored-content quality-control signal only"),
        ("Features", "Word count, mean word length and mean sentence length"),
        ("Model", "Binary logistic-regression equation ported deterministically to Dart"),
        ("Observed fit", "69.2% resubstitution accuracy on 26 texts"),
        ("Evidence boundary", "No held-out performance or production-grade claim"),
    ])

    doc.add_page_break()
    doc.add_heading("Appendix K — Software Testing Documentation", level=1)
    add_table(doc, ["Test area", "Expected result", "Final result"], [
        ("Flutter static analysis", "No type, compile or lint issue", "Pass — no issues found"),
        ("Flutter unit/widget suite", "All specified services and UI behaviours pass", "Pass — 130/130"),
        ("Pillam selection navigation", "Selected detail panel scrolls into view", "Pass — regression test included"),
        ("Dataset integrity", "Hash groups stay in one split; conflicts quarantined", "Pass"),
        ("Tensor contract", "Bundled asset exposes [1,64,64,1] and [1,455]", "Pass"),
        ("Label contract", "455 output labels retain registered order", "Pass"),
        ("TFLite parity", "Registered adapter predictions remain stable after conversion", "Pass — 100/100 top-1"),
        ("Android integration", "Load bundled model and complete native inference", "Pass on Android 14 emulator"),
        ("Coach and progress failures", "Sparse/offline/no-data conditions remain understandable", "Pass in deterministic service tests"),
        ("Physical-device benchmark", "Defined low/mid/high-device results", "Pending; no physical-device performance claim"),
    ], font_size=8.0)

    doc.add_page_break()
    doc.add_heading("Appendix L — User Acceptance and Expert Evaluation Instrument", level=1)
    add_callout(doc, "Administration condition", "No human UAT result is claimed. This completed protocol defines the instrument to be administered only after supervisor and ethics authorization; uncollected scores must never be fabricated.")
    add_table(doc, ["Evaluation criterion", "Planned question", "Evidence and decision rule"], [
        ("Navigation", "Can the intended user locate Home, Learn, My Coach, Progress and Profile?", "Observation plus 1–5 rating; report task success and median rating"),
        ("Child-facing presentation", "Are text size, colour, pictures and touch targets suitable for the intended grade?", "Expert review plus accessibility scan; record each required correction"),
        ("Grade separation", "Do Grade 1 and Grade 2 activities show an appropriate progression?", "Teacher judgement with reasons; no automated claim"),
        ("Tracing feedback", "Is correct, incorrect and invalid-input feedback understandable and cautious?", "Scripted examples; any misleading success is a release blocker"),
        ("Progress evidence", "Can a guardian or teacher understand activity, strengths and practice needs?", "Scenario walkthrough and 1–5 usefulness rating"),
        ("Language controls", "Can either interface language access Sinhala and English learning content?", "Four-combination task check; every combination must pass"),
        ("Failure states", "Are offline, loading, no-data and permission errors recoverable?", "Scripted negative paths; no crash or data disclosure permitted"),
        ("Pilot readiness", "Is supervised use acceptable after recorded corrections?", "Explicit yes/no recommendation with reviewer role and date"),
    ], font_size=7.4)
    add_body(doc, "Planned rating scale: 1 = strongly disagree, 2 = disagree, 3 = neutral, 4 = agree and 5 = strongly agree. Future administration must record role, date, consent and sampling method in a new dated evidence artifact.")

    doc.add_page_break()
    doc.add_heading("Appendix M — Evaluation Results and Supplementary Analysis", level=1)
    add_table(doc, ["Metric", "Custom CNN result", "Interpretation boundary"], [
        ("Open-set overall accuracy", "98.46%", "Registered test performance, not child touchscreen accuracy"),
        ("Letter-only accuracy", "98.51%", "Known-class reference performance"),
        ("Macro F1", "98.73%", "Class-balanced precision/recall summary"),
        ("Top-3 accuracy", "99.43%", "Candidate coverage; app still requires expected-target gating"),
        ("Unknown recall / invalid FAR", "97.00% / 3.00%", "Open-set rejection evidence on 400 unknown samples"),
        ("Expected calibration error", "0.0031", "Confidence calibration on the registered open-set test"),
        ("Adapter replay retention", "95.85% after adaptation", "One-writer adapter; captured fit is not independent accuracy"),
        ("TFLite agreement", "100.00% on 100 samples", "Conversion parity sample, not new accuracy evidence"),
        ("Emulator inference", "Mean 81.24 ms; p95 92.92 ms", "Android 14 emulator only"),
    ])
    for path, caption in [
        (ASSETS / "cnn_protected_test_metrics.png", "Figure M.1. Registered open-set CNN performance metrics."),
        (ROOT / "deliverables" / "stage6_evaluation" / "per_class_recall_analysis.png", "Figure M.2. Supplementary per-class recall analysis."),
        (ROOT / "deliverables" / "stage6_evaluation" / "top_confusion_pairs.png", "Figure M.3. Most frequent protected-test confusion pairs."),
    ]:
        if path.exists():
            doc.add_picture(str(path), width=Inches(5.7))
            _center_last_picture(doc)
            add_caption(doc, caption)

    doc.add_page_break()
    doc.add_heading("Appendix N — User Manual", level=1)
    add_numbered(doc, [
        "Open NenaPotha AI and choose the interface language. This changes navigation text, not the language the child is allowed to learn.",
        "A parent signs in or registers, creates/selects a learner profile, chooses Grade 1 or Grade 2 and may select an avatar or profile image.",
        "Use Home for the recommended next activity, stories and the current summary.",
        "Use Learn to study Sinhala or English letters, words, Grade 2 pillam, tracing and progressive tasks.",
        "In tracing, draw over the guide and select Check. Treat the percentage as formative model/shape evidence, not a clinical or intelligence score.",
        "Use Progress to review completed practice, recent activity, strengths and areas requiring further practice.",
        "A teacher registers with the Teacher role, opens Students, selects Add Student and enters the learner's guardian-generated join code.",
        "The teacher selects a linked learner to review task, quiz, reading, daily-activity and coaching evidence.",
        "If cloud synchronization is unavailable, continue with bundled learning activities and retry the adult evidence view later.",
        "Use the profile/logout controls to end the adult session on a shared device.",
    ])

    doc.add_page_break()
    doc.add_heading("Appendix O — Installation and Deployment Guide", level=1)
    add_code(doc, "flutter pub get\nflutter analyze\nflutter test\nflutter run")
    add_bullets(doc, [
        "Install the stable Flutter SDK, Android Studio/SDK and a supported Android emulator or device.",
        "Configure the authorized Firebase Android application using google-services.json and restrict configuration files to the intended project.",
        "Enable Firebase Authentication and Firestore, then deploy the tested role-aware security rules.",
        "Verify guardian ownership, teacher links and no-data/error states before a release build.",
        "Confirm that the bundled TFLite model and verified label asset retain their registered hashes before reporting research results.",
        "Build a release artifact only after analyzer, tests, Firestore rules and production App Check are verified.",
    ])

    doc.add_page_break()
    doc.add_heading("Appendix P — Supervisor Meeting Record", level=1)
    add_body(doc, "The following scanned records are reproduced as supplied. They preserve the handwritten dates and signatures and are included as administrative evidence rather than reconstructed summaries.")
    for index, (filename, caption) in enumerate(MEETING_MANIFEST, start=1):
        path = MEETING_DIR / filename
        if not path.exists():
            continue
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.add_run().add_picture(str(path), height=Inches(7.5))
        add_caption(doc, f"Figure P.{index}. {caption}.")
        if index != len(MEETING_MANIFEST):
            doc.add_page_break()

    doc.add_page_break()
    doc.add_heading("Appendix Q — Project Progress and Management Evidence", level=1)
    add_table(doc, ["Stage", "Principal output", "Evidence status"], [
        ("1", "Project audit, scope and baseline research components", "Completed and documented"),
        ("2", "Dataset preparation and leakage controls", "Completed and documented"),
        ("3", "Custom CNN training, protected evaluation and model registration", "Completed and documented"),
        ("4", "Flutter model integration and verified 455-label contract", "Completed and runtime-tested"),
        ("5", "Deterministic coaching, progress and teacher-linked evidence integration", "Implemented and tested"),
        ("6", "Technical evaluation package, parity, tests and emulator benchmark", "Completed; child field trial pending ethics"),
        ("7", "Physical-device protocol and final deployment evidence", "Protocol ready; physical-device benchmark pending"),
    ])

    doc.add_page_break()
    doc.add_heading("Appendix R — Source Code and Repository Information", level=1)
    add_table(doc, ["Repository item", "Verified value"], [
        ("Public repository", "https://github.com/MahimaInduvara/nenapotha-ai-reading-assistant"),
        ("Submission branch", "main"),
        ("Application source tag", "application-submission-v1.0.0"),
        ("Application source commit", "1f4f2aeea5a07008738fd73d6395065ab42ecee8"),
        ("Access", "Public read access; the repository can be browsed, downloaded or cloned"),
    ])
    add_table(doc, ["Repository area", "Purpose"], [
        ("lib/screens", "Learner, learning, tracing, reading, progress, profile and teacher interfaces"),
        ("lib/services", "CNN inference, progress, activity, deterministic coaching, authentication and persistence boundaries"),
        ("assets/models", "Bundled TensorFlow Lite model and label/mapping assets"),
        ("training", "Leakage-aware preparation, training, protected evaluation and deployment registration"),
        ("test", "Flutter unit and widget regression tests"),
        ("integration_test", "Android model-loading and native-inference integration path"),
        ("deliverables/stage6_evaluation", "Registered metrics, figures, summaries and pilot protocol"),
        ("tools", "Reproducible document and evaluation-report generation"),
    ])
    add_body(doc, "The complete source snapshot is publicly available at the repository URL above. It can be reproduced with ''git clone https://github.com/MahimaInduvara/nenapotha-ai-reading-assistant.git'' followed by ''git checkout application-submission-v1.0.0''. The application-source tag is fixed to the full commit identifier shown above, while later documentation-only commits do not alter that submitted source snapshot.")
    add_body(doc, "After installing the Flutter toolchain, the principal verification commands are ''flutter pub get'', ''flutter analyze'' and ''flutter test''. Hundreds of source-code pages are intentionally not printed; this appendix identifies the auditable locations, version and reproducible access path instead.")

    doc.add_page_break()
    doc.add_heading("Appendix S — Database, AI and Integration Documentation", level=1)
    add_table(doc, ["Path / service", "Stored or processed evidence", "Access boundary"], [
        ("users/{uid}", "Adult role and account metadata", "Authenticated owner"),
        ("students/{studentId}", "Learner profile, grade, language and owner reference", "Guardian owner; linked teacher read access"),
        ("students/{studentId}/teacherLinks", "Teacher linkage", "Rule-controlled teacher relationship"),
        ("students/{studentId}/taskAttempts", "Learning-task scores and typed model evidence", "Owner and authorized linked teacher"),
        ("students/{studentId}/readingSessions", "Reading completion and duration evidence", "Owner and authorized linked teacher"),
        ("students/{studentId}/quizAttempts", "Comprehension-question evidence", "Owner and authorized linked teacher"),
        ("students/{studentId}/dailyActivity", "Dated engagement summary", "Owner and authorized linked teacher"),
        ("joinCodes", "Short-lived learner-linking code", "Validated linking workflow"),
        ("Smart Learning Coach", "Recent attempts and ranked practice suggestions", "Local deterministic rules; no generative prompt or child dialogue"),
    ], font_size=7.6)
    add_body(doc, "CNN inference, shape comparison, the Grade 1/2 text-difficulty check and coaching rules run locally. Firestore receives only the records needed for progress and authorized teacher analysis; raw trace images are not required. Production deployment must retain tested Authentication and Firestore rule boundaries.")

    doc.add_page_break()
    doc.add_heading("Appendix T — Supporting Evidence and Claim Register", level=1)
    add_table(doc, ["Claim", "Supporting artifact", "Permitted conclusion"], [
        ("Open-set CNN performance", "open_set_metrics.json", "98.46% overall accuracy under the registered 455-output evaluation"),
        ("Captured adapter", "captured_adapter_report.json", "Replay gate passed; no claim of writer-independent or child accuracy"),
        ("Deployment parity", "captured_adapter_report.json", "100% top-1 parity on the registered 100-sample set"),
        ("Android execution", "Final integration benchmark plus Figures 5.1 and I.1–I.14", "The app and bundled model execute on the recorded emulator path"),
        ("Software correctness", "Analyzer output and 130 automated tests", "Specified tested behaviours pass; exhaustive correctness is not implied"),
        ("Text-difficulty component", "26-text proof-of-concept record", "Deterministic integration exists; generalization is unproven"),
        ("Educational effectiveness", "No ethics-approved child trial", "No claim of improved literacy, usability or classroom effectiveness"),
    ], font_size=8.0)
    add_body(doc, "This claim register is the final interpretation boundary for examination. Any future physical-device, expert, parent, teacher or child result must be added as a new dated artifact with its sampling, instrument, ethics status and analysis method.")


def style_figure_captions(doc: Document) -> None:
    style = doc.styles["Figure Caption"]
    for paragraph in doc.paragraphs:
        if paragraph.text.strip().startswith("Figure "):
            updated = re.sub(r"^(Figure\s+[A-Z0-9]+\.[0-9]+)\.\s*", r"\1: ", paragraph.text.strip())
            if updated != paragraph.text:
                paragraph.clear()
                paragraph.add_run(updated)
            paragraph.style = style
            for run in paragraph.runs:
                run.font.name = "Times New Roman"
                run.font.size = Pt(12)
                run.font.italic = False
                run.font.color.rgb = RGBColor(0, 0, 0)


def _set_heading(paragraph: Paragraph, text: str, level: int) -> None:
    paragraph.clear()
    paragraph.add_run(text)
    paragraph.style = f"Heading {level}"


def restructure_senate_sections(doc: Document) -> None:
    # Objectives are mandatory as a standalone section in the Senate structure.
    # Remove the duplicated aim/objective block from the Introduction while
    # retaining the same verified content in Section 2.
    removing = False
    for paragraph in list(doc.paragraphs):
        text = paragraph.text.strip()
        if text == "1.6 Research Aim":
            removing = True
        if removing and text == "1.8 Rich Picture of the Proposed Solution":
            removing = False
        if removing:
            paragraph._element.getparent().remove(paragraph._element)

    state = ""
    for paragraph in list(doc.paragraphs):
        text = paragraph.text.strip()
        if text.startswith("Chapter 01"):
            state = "introduction"
            _set_heading(paragraph, "1 INTRODUCTION", 1)
            continue
        if text == "2 OBJECTIVES":
            state = "objectives"
            _set_heading(paragraph, text, 1)
            continue
        if text.startswith("Chapter 02"):
            state = "literature"
            _set_heading(paragraph, "3 LITERATURE REVIEW", 1)
            continue
        if text.startswith("Chapter 03"):
            state = "methodology"
            _set_heading(paragraph, "4 METHODOLOGY", 1)
            continue
        if text.startswith("Chapter 04"):
            state = "srs"
            _set_heading(paragraph, "4.16 System requirements specification", 2)
            continue
        if text.startswith("Chapter 05"):
            state = "implementation"
            _set_heading(paragraph, "4.17 Implementation and design", 2)
            continue
        if text.startswith("Chapter 06"):
            state = "results"
            _set_heading(paragraph, "5 RESULTS", 1)
            continue
        if text == "6.9 Discussion":
            state = "discussion"
            _set_heading(paragraph, "6 DISCUSSION AND CONCLUSIONS", 1)
            new_xml = OxmlElement("w:p")
            paragraph._p.addnext(new_xml)
            inserted = Paragraph(new_xml, paragraph._parent)
            _set_heading(inserted, "6.1 Discussion of results", 2)
            continue
        if text.startswith("Chapter 07"):
            state = "conclusion"
            _set_heading(paragraph, "6.4 Conclusions", 2)
            continue
        if text.startswith("References"):
            state = "references"
            _set_heading(paragraph, "REFERENCES", 1)
            continue
        appendix_match = re.match(r"^Appendix ([A-T])\s+[—:-]\s+(.+)$", text)
        if appendix_match:
            letter, title = appendix_match.groups()
            state = f"appendix_{letter.lower()}"
            _set_heading(paragraph, f"APPENDIX {letter}: {title.upper()}", 1)
            continue

        if not paragraph.style or not paragraph.style.name.startswith("Heading"):
            continue
        if state == "introduction" and text == "1.1 Chapter Overview":
            _set_heading(paragraph, "1.1 Section overview", 2)
        elif state == "introduction" and text.startswith("1.8 "):
            _set_heading(paragraph, text.replace("1.8 ", "1.6 ", 1), 2)
        elif state == "introduction" and text.startswith("1.9.1 "):
            _set_heading(paragraph, text.replace("1.9.1 ", "1.7.1 ", 1), 3)
        elif state == "introduction" and text.startswith("1.9.2 "):
            _set_heading(paragraph, text.replace("1.9.2 ", "1.7.2 ", 1), 3)
        elif state == "introduction" and text.startswith("1.9 "):
            _set_heading(paragraph, text.replace("1.9 ", "1.7 ", 1), 2)
        elif state == "introduction" and text.startswith("1.10 "):
            _set_heading(paragraph, text.replace("1.10 ", "1.8 ", 1), 2)
        elif state == "introduction" and text.startswith("1.11 "):
            _set_heading(paragraph, "1.9 Section summary", 2)
        elif state == "literature" and re.match(r"^2\.", text):
            updated = re.sub(r"^2\.", "3.", text)
            updated = updated.replace("Chapter Overview", "Section overview").replace("Chapter Summary", "Section summary")
            _set_heading(paragraph, updated, 2 if text.count(".") == 1 else 3)
        elif state == "methodology" and re.match(r"^3\.", text):
            updated = re.sub(r"^3\.", "4.", text)
            updated = updated.replace("Chapter Overview", "Section overview").replace("Chapter Summary", "Section summary")
            _set_heading(paragraph, updated, 2 if text.count(".") == 1 else 3)
        elif state == "srs" and re.match(r"^4\.", text):
            suffix = re.sub(r"^4\.[0-9]+\s*", "", text)
            old_number = re.match(r"^4\.([0-9]+)", text).group(1)
            if old_number == "1":
                suffix = "Overview"
            elif old_number == "12":
                suffix = "Subsection summary"
            _set_heading(paragraph, f"4.16.{old_number} {suffix}", 3)
        elif state == "implementation" and re.match(r"^5\.", text):
            suffix = re.sub(r"^5\.[0-9]+\s*", "", text)
            old_number = re.match(r"^5\.([0-9]+)", text).group(1)
            if old_number == "1":
                suffix = "Overview"
            elif old_number == "10":
                suffix = "Subsection summary"
            _set_heading(paragraph, f"4.17.{old_number} {suffix}", 3)
        elif state == "results" and re.match(r"^6\.[1-8]\b", text):
            updated = re.sub(r"^6\.", "5.", text)
            updated = updated.replace("Chapter Overview", "Section overview")
            _set_heading(paragraph, updated, 2)
        elif state == "discussion" and text.startswith("6.10 "):
            _set_heading(paragraph, "6.2 Limitations and threats to validity", 2)
        elif state == "discussion" and text.startswith("6.11 "):
            _set_heading(paragraph, "6.3 Discussion summary", 2)
        elif state == "conclusion" and re.match(r"^7\.", text):
            _set_heading(paragraph, re.sub(r"^7\.([0-9]+)", r"6.4.\1", text), 3)


def correct_senate_cross_references(doc: Document) -> None:
    chapter_map = {
        "Chapters 4–5": "Sections 4.16–4.17",
        "Chapter 7": "Section 6",
        "Chapter 6": "Sections 5–6",
        "Chapter 5": "Section 4.17",
        "Chapter 4": "Section 4.16",
        "Chapter 3": "Section 4",
        "Chapter 2": "Section 3",
    }
    figure_map = {
        "Figure 2.1": "Figure 3.1",
        "Figure 2.2": "Figure 3.2",
        "Figure 2.3": "Figure 3.3",
        "Figure 3.1": "Figure 4.1",
        "Figure 3.2": "Figure 4.2",
        "Figure 4.1": "Figure 4.3",
        "Figure 4.2": "Figure 4.4",
        "Figure 4.3": "Figure 4.5",
        "Figure 4.4": "Figure 4.6",
        "Figure 4.5": "Figure 4.7",
        "Figure 4.6": "Figure 4.8",
        "Figure 5.1": "Figure 4.9",
        "Figure 6.1": "Figure 5.1",
        "Figure 6.2": "Figure 5.2",
        "Figure 6.3": "Figure 5.3",
        "Figure 6.4": "Figure 5.4",
        "Figure 6.5": "Figure 5.5",
    }

    def replace_map(text: str, values: dict[str, str], marker: str) -> str:
        placeholders = {}
        for index, (old, new) in enumerate(values.items()):
            token = f"__{marker}_{index}__"
            if old in text:
                text = text.replace(old, token)
                placeholders[token] = new
        for token, new in placeholders.items():
            text = text.replace(token, new)
        return text

    def update_paragraph(paragraph: Paragraph) -> None:
        for run in paragraph.runs:
            original = run.text
            updated = replace_map(original, chapter_map, "CH")
            updated = replace_map(updated, figure_map, "FIG")
            updated = updated.replace(
                "The following administrative progress section records readiness for future Results and Discussion chapters without adding those chapters to this submission.",
                "The following sections document the implemented artifact, verified results and evidence limitations.",
            )
            updated = updated.replace(
                "states the research question, motivation, aim and objectives",
                "states the research question and motivation, then links them to the standalone objectives in Section 2",
            )
            updated = updated.replace(
                "The next chapter critically evaluates whether prior educational, handwriting-recognition and readability research supports the selected contribution and design decisions.",
                "Section 2 states the research objectives, after which Section 3 critically evaluates the literature supporting the selected contribution and design decisions.",
            )
            updated = updated.replace(
                "reports functional and non-functional evidence, and interprets the results against the research objectives.",
                "reports functional and non-functional evidence against the research objectives; interpretation is deferred to Section 6.",
            )
            updated = updated.replace("This chapter", "This section")
            updated = updated.replace("this chapter", "this section")
            updated = updated.replace("The chapter", "The section")
            updated = updated.replace("the chapter", "the section")
            if updated != original:
                run.text = updated

    for paragraph in doc.paragraphs:
        update_paragraph(paragraph)
    for table in doc.tables:
        for row in table.rows:
            for cell in row.cells:
                for paragraph in cell.paragraphs:
                    update_paragraph(paragraph)


def apply_senate_table_formatting(doc: Document) -> None:
    counters: dict[str, int] = {}
    current_section: str | None = None
    nearest_heading = "Research evidence"
    for child in list(doc.element.body.iterchildren()):
        if child.tag == qn("w:p"):
            paragraph = Paragraph(child, doc._body)
            text = paragraph.text.strip()
            match = re.match(r"^([1-6])\s", text)
            if match and paragraph.style.name == "Heading 1":
                current_section = match.group(1)
                nearest_heading = re.sub(r"^[1-6]\s+", "", text).title()
            elif text == "REFERENCES":
                current_section = None
            elif text.startswith("APPENDIX "):
                current_section = text.split()[1].rstrip(":")
                nearest_heading = text.split(":", 1)[-1].strip().title()
            elif paragraph.style.name in {"Heading 2", "Heading 3"}:
                nearest_heading = re.sub(r"^[0-9]+(?:\.[0-9]+)*\s+", "", text).strip()
            continue
        if child.tag != qn("w:tbl"):
            continue
        table = Table(child, doc._body)
        for shading in table._tbl.xpath(".//w:shd"):
            shading.getparent().remove(shading)
        for row in table.rows:
            for cell in row.cells:
                for paragraph in cell.paragraphs:
                    paragraph.paragraph_format.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
                    for run in paragraph.runs:
                        run.font.name = "Times New Roman"
                        run.font.size = Pt(12)
                        run.font.color.rgb = RGBColor(0, 0, 0)
        if current_section is None or len(table.columns) < 2:
            continue
        counters[current_section] = counters.get(current_section, 0) + 1
        number = counters[current_section]
        caption_xml = OxmlElement("w:p")
        child.addprevious(caption_xml)
        caption = Paragraph(caption_xml, doc._body)
        caption.style = doc.styles["Table Caption"]
        caption.add_run(
            f"Table {current_section}.{number}: {nearest_heading} — evidence summary"
        )


def enforce_senate_typography(doc: Document) -> None:
    started = False
    for paragraph in doc.paragraphs:
        if paragraph.text.strip() == "DECLARATION":
            started = True
        if not started:
            continue
        paragraph.paragraph_format.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
        for run in paragraph.runs:
            run.font.name = "Times New Roman"
            run.font.size = Pt(12)
            run.font.color.rgb = RGBColor(0, 0, 0)
    for section in doc.sections:
        section.header.is_linked_to_previous = False
        section.header.paragraphs[0].clear()


def standardize_current_brand(doc: Document) -> None:
    """Keep the final thesis consistent with the shipped application brand."""

    def replace_in_paragraph(paragraph) -> None:
        for run in paragraph.runs:
            if "ReadBuddy" not in run.text:
                continue
            run.text = run.text.replace("ReadBuddy AI", "NenaPotha AI")
            run.text = run.text.replace("ReadBuddy's", "NenaPotha's")
            run.text = run.text.replace("ReadBuddy", "NenaPotha")

    def replace_in_table(table) -> None:
        for row in table.rows:
            for cell in row.cells:
                for paragraph in cell.paragraphs:
                    replace_in_paragraph(paragraph)
                for nested_table in cell.tables:
                    replace_in_table(nested_table)

    for paragraph in doc.paragraphs:
        replace_in_paragraph(paragraph)
    for table in doc.tables:
        replace_in_table(table)
    for section in doc.sections:
        for paragraph in section.header.paragraphs:
            replace_in_paragraph(paragraph)
        for paragraph in section.footer.paragraphs:
            replace_in_paragraph(paragraph)


def build() -> Path:
    OUT.mkdir(parents=True, exist_ok=True)
    make_complete_thesis_figures()
    doc = setup_document()
    title_page(doc)
    front_matter(doc)
    start_main_text_section(doc)
    base.chapter_one(doc)
    chapter_two_objectives(doc)
    base.chapter_two(doc)
    base.chapter_three(doc)
    correct_legacy_chapter_claims(doc)
    chapter_four(doc)
    chapter_five(doc)
    chapter_six(doc)
    chapter_seven(doc)
    references(doc)
    appendices(doc)
    restructure_senate_sections(doc)
    correct_senate_cross_references(doc)
    style_figure_captions(doc)
    apply_senate_table_formatting(doc)
    enforce_senate_typography(doc)
    standardize_current_brand(doc)
    doc.save(DOCX)
    print(DOCX)
    return DOCX


if __name__ == "__main__":
    build()
