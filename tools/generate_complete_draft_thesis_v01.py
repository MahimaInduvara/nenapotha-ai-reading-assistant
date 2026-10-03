from __future__ import annotations

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
DOCX = OUT / "NenaPotha_AI_Final_Thesis_Screenshot_Integrated_28277.docx"
SCREENSHOT_COMPOSITE = ASSETS / "nenapotha_ai_app_execution_screens.png"
SCREENSHOTS_DIR = ROOT / "work" / "thesis_screenshots_2026-09-29"
SCREENSHOT_MANIFEST = [
    ("01_profile_setup.png", "Language-selection screen for Sinhala and English interface preferences"),
    ("02_home.png", "Secure parent or teacher sign-in screen"),
    ("03_learning_hub.png", "Account registration with parent and teacher role selection"),
    ("04_letter_tracing.png", "Learner-profile setup with avatar, name and grade selection"),
    ("05_story_reading.png", "Child-facing home dashboard with recommended learning activities"),
    ("06_grade2_pillam.png", "Grade 2 picture-supported pillam learning screen"),
    ("07_grade2_words.png", "Grade 2 word-learning screen with bilingual navigation controls"),
    ("08_grade2_tracing.png", "Grade 2 structured task feedback and level evidence"),
    ("09_grade2_tasks.png", "Learner progress dashboard with activity and skill indicators"),
    ("10_progress.png", "Learner profile and accumulated learning evidence"),
    ("11_teacher_overview.png", "Teacher sign-in screen"),
    ("12_teacher_students.png", "Teacher dashboard and linked-student list"),
    ("13_teacher_student_detail.png", "Teacher workflow for linking a learner by join code"),
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

    # Replace the earlier progress chart with the protected held-out result.
    img, d = _new_canvas("Protected Held-out CNN Evaluation", 1750, 970)
    metrics = [
        ("Top-1 accuracy", 88.61, CORAL),
        ("Macro precision", 88.86, ORANGE),
        ("Macro recall", 88.11, TEAL),
        ("Macro F1-score", 88.14, BLUE),
        ("Top-2 accuracy", 92.05, "8E44AD"),
        ("Top-3 accuracy", 93.51, "5C6BC0"),
    ]
    y = 155
    for label, value, color in metrics:
        d.text((65, y + 30), label, font=font(25, True), fill=f"#{BLACK}", anchor="lm")
        d.rounded_rectangle((560, y, 1560, y + 62), radius=18, fill="#E5E7EB")
        d.rounded_rectangle((560, y, 560 + 1000 * value / 100, y + 62), radius=18, fill=f"#{color}")
        d.text((1660, y + 30), f"{value:.2f}%", font=font(25, True), fill=f"#{color}", anchor="mm")
        y += 115
    d.text((875, 885), "Test n = 11,984; 454 classes; exact-hash-deduplicated 70/15/15 split; seed 42",
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
        ("Answer comprehension tasks", 720, 600), ("Ask NenaPotha AI", 1050, 600),
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
        (70, 700, 560, 1030, "LetterClassifierService", "modelVersion\nlabels[454]\nthreshold", "loadModel()\npredict()"),
        (750, 690, 1260, 1040, "AIService / IntentRouter", "English/Sinhala tokens\nknown intents", "routeChatIntent()\ncreateExercise()"),
        (1440, 700, 1930, 1040, "FirebaseAIChatService", "model\ntimeout\nApp Check", "chat()\nfriendlyFallback()"),
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
         [(0,1,"tap Check"),(1,2,"predict(PNG)"),(2,3,"run [1,64,64,1]"),(3,2,"454 scores"),(2,1,"typed prediction"),(1,4,"save scalar evidence"),(1,0,"feedback / retry")]),
        ("chat_sequence_diagram.png", "Sequence — Hybrid NenaPotha Chat",
         ["User", "AI Help UI", "Intent Router", "Firebase AI", "App Check"],
         [(0,1,"send English/Sinhala message"),(1,2,"route complete words"),(2,1,"known intent / exercise"),(2,3,"unknown conversation only"),(3,4,"verify app attestation"),(4,3,"verified"),(3,1,"child-friendly answer"),(1,0,"answer or friendly fallback")]),
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
                "Child-facing learning and reading UI\n\nLocal intent router\n\nTFLite CNN (454 outputs)\n\nDart Grade 1/2 text classifier\n\nLocal TTS/STT and cached task state", 34, 25)
    rounded_box(d, (1230, 155, 1870, 480), "#DFF2EF", f"#{TEAL}", "Firebase Project",
                "Authentication\nFirestore progress records\nApp Check verification", 32, 25)
    rounded_box(d, (1230, 650, 1870, 995), "#F3E5F5", "#8E44AD", "Firebase AI Logic",
                "Gemini Developer API provider\nConversational answers only\nAPI credential remains server-side", 32, 25)
    arrow(d, (1040, 340), (1230, 340), TEAL, 6)
    arrow(d, (1040, 820), (1230, 820), "8E44AD", 6)
    d.text((1135, 300), "authenticated data", font=font(20, True), fill=f"#{TEAL}", anchor="ms")
    d.text((1135, 780), "unknown chat only", font=font(20, True), fill="#8E44AD", anchor="ms")
    d.text((975, 1090), "No trace image, learner name, stored progress, or CNN output is sent to the conversational model.",
           font=font(24, True), fill=f"#{CORAL}", anchor="ma")
    img.save(ASSETS / "deployment_trust_boundary.png", quality=96)

    # Final-build execution evidence selected from the student's dated
    # screenshot set. The four panels cover the learner, learning-content,
    # progress and teacher-facing paths without inventing UI state.
    selected = [
        ("05_story_reading.png", "(a) Learner home"),
        ("06_grade2_pillam.png", "(b) Grade 2 pillam"),
        ("09_grade2_tasks.png", "(c) Learner progress"),
        ("12_teacher_students.png", "(d) Teacher dashboard"),
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
        ("September 2026", 30),
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
        ("September 2026", 30),
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
    p = doc.add_paragraph("Student name: L. M. I. Silva                                      Date: __________________")
    p.paragraph_format.space_before = Pt(30)
    p = doc.add_paragraph("Student signature: ______________________________________________")
    p.paragraph_format.space_before = Pt(12)
    p = doc.add_paragraph("Signature of the Principal Supervisor: __________________________")
    p.paragraph_format.space_before = Pt(30)
    add_body(doc, "Dr./Mr./Ms. ______________________________________________\nSenior Lecturer/Lecturer\nDepartment of Software Engineering\nNSBM Green University")
    doc.add_page_break()

    doc.add_heading("ACKNOWLEDGEMENT", level=1)
    add_body(doc, "I sincerely thank my project supervisor for the direction, critical feedback and research standards that shaped this study. I am grateful to the Faculty of Computing at NSBM Green University for providing the academic environment and resources required to complete the project. I also thank the two teachers whose preliminary observations helped clarify the practical challenges faced in early Sinhala literacy instruction; these observations are treated only as exploratory requirement input because of the small sample. My appreciation extends to my family and friends for their encouragement throughout the design, development, training and evaluation process. Finally, I acknowledge the researchers and open-source communities behind Flutter, Firebase, TensorFlow Lite, scikit-learn and the Sinhala handwriting resources used in this work.")
    doc.add_page_break()

    doc.add_heading("ABSTRACT", level=1)
    add_body(doc, "Foundational literacy remains a concern in Sri Lanka, while Sinhala-focused educational applications provide limited evidence-based support for handwriting feedback, graded reading and bilingual assistance in one mobile environment. This study designed and technically evaluated NenaPotha AI, a child-friendly mobile reading and comprehension assistant for Grade 1 and Grade 2 learners. A pragmatist design-science approach connected educational requirements with two machine-learning components and a protected conversational architecture. The first component is a 454-class convolutional neural network for isolated Sinhala handwritten-letter recognition. Auditing 108,933 publisher paths exposed duplicate leakage; after cross-class conflicts were quarantined and exact hashes grouped, 79,788 unique samples formed deterministic 55,820/11,984/11,984 training, validation and test partitions. On the protected test partition, the custom CNN achieved 88.61% top-1 accuracy, 88.14% macro-F1, 92.05% top-2 accuracy and 93.51% top-3 accuracy. Its 2.41 MiB TensorFlow Lite conversion preserved 99.00% top-1 agreement over 100 registered samples and averaged 83.58 ms native inference on an Android 14 emulator. Five independently verified class-to-Unicode mappings support formative tracing feedback. The second component is an interpretable Grade 1/2 logistic-regression proof of concept; its 69.2% resubstitution accuracy on 26 authored texts is not presented as generalization evidence. A whole-word bilingual intent router handles known learning requests, while Firebase AI Logic with App Check handles unmatched conversation without embedding a Gemini key. Static analysis, 125 automated Flutter tests, conversion parity and emulator execution support technical feasibility. Because no ethics-approved child trial was completed, the contribution is a reproducible, privacy-conscious technical artifact and evaluation protocol rather than evidence of improved classroom learning.")
    p = doc.add_paragraph()
    p.add_run("Keywords—").bold = True
    p.add_run(" Sinhala handwriting recognition, early literacy, convolutional neural network, TensorFlow Lite, readability assessment, Firebase AI Logic, bilingual mobile learning")
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
        ("STT/TTS", "Speech-to-Text / Text-to-Speech"), ("TFLite", "TensorFlow Lite"),
        ("UI/UX", "User Interface / User Experience"), ("UAT", "User Acceptance Testing"),
    ])
    # A new section starts the main text at Arabic page 1.


def correct_legacy_chapter_claims(doc: Document) -> None:
    replacements = {
        "the accuracy, class-level behaviour and confidence calibration of the Sinhala letter CNN on reference validation data;":
            "the accuracy, class-level behaviour and confidence calibration of the Sinhala letter CNN on the protected held-out test data;",
        "No reviewed work combines a Grade 1–2 Sinhala/English literacy application with an on-device Sinhala letter classifier and an offline Sinhala Grade 1/2 text-difficulty checker. ReadBuddy AI addresses that integration gap. It does not yet close the evidence gap: numeric label mapping, representative child traces, exact training provenance and an expert-labelled readability corpus remain necessary. This distinction between artifact contribution and validated educational effectiveness is the central critical position of this thesis.":
            "No reviewed work combines a Grade 1–2 Sinhala/English literacy application with an on-device Sinhala letter classifier, an offline Sinhala Grade 1/2 text-difficulty checker and a protected bilingual conversational fallback. ReadBuddy AI addresses that integration gap. The five exposed letter mappings and reproducible training provenance are now verified, but representative child traces, complete Unicode mapping and an expert-labelled readability corpus remain necessary. This distinction between an evaluated artifact and demonstrated educational effectiveness is the central critical position of this thesis.",
        "Source code, model assets, emulator execution, static-analysis output and test output provide engineering evidence. At the current audit, flutter analyze reports ten findings, and the only widget test is an obsolete counter template that fails against the current app. These outcomes do not invalidate the research models, but they show that software-quality evidence is not yet submission-complete.":
            "Source code, model assets, emulator execution, static-analysis output and automated-test output provide engineering evidence. The final audit reports no Flutter analyzer issues, all current Flutter tests passing, Python pipeline tests passing and the on-device CNN integration benchmark passing. These results support software correctness within the tested scenarios, but do not replace field usability or educational-effectiveness evaluation.",
        "The shipped research component is described as a custom three-block CNN. Each block applies convolution and max pooling, followed by dense classification layers, dropout and a 454-way softmax output. Training used 64×64 grayscale inputs, Adam optimization, sparse categorical cross-entropy, batch size 32 and 15 epochs. Two recorded runs produced approximately 94.10% and 94.04% validation accuracy, suggesting run-level stability.":
            "The final research component is a custom three-convolution CNN using 64×64 grayscale input, max pooling after the first two convolutions, a 128-unit dense layer, dropout 0.30 and a 454-way softmax output. Training used Adam at 0.001, sparse categorical cross-entropy, batch size 64, at most 40 epochs and validation-loss early stopping. On the separately protected test split it achieved 88.61% top-1 accuracy and 88.14% macro-F1.",
        "The component is accepted as end-to-end functional only when the class mapping is complete, all five prototype letters have deterministic mapping tests, the UI verdict and persisted attempt agree, the application identifies whether CNN or geometric fallback produced the verdict, and physical-device inference succeeds within a supervisor-approved latency threshold. The current implementation does not yet meet all these criteria.":
            "The component is accepted as technically integrated because all five exposed letters have deterministic mapping tests, the UI and stored verdict use the same typed prediction, model failures remain unscored, and emulator inference satisfies the functional runtime path. A physical-device benchmark and representative child-trace validation remain pending and are not implied by this acceptance.",
        "The repository notebook currently describes a different 128×128 MobileNetV2/TFJS pipeline, whereas the app ships a 64×64 custom-CNN TFLite model. The exact notebook that generated the shipped model must be recovered and archived with environment versions, dataset manifest, seed and SHA-256 hashes before final submission.":
            "The original repository notebook described an obsolete 128×128 MobileNetV2/TFJS path. A reproducible 64×64 custom-CNN pipeline was therefore rebuilt from the final architecture, and now archives environment versions, seed 42, the frozen manifest and SHA-256 identities for the protected experiment and deployed TFLite artifact.",
    }
    token_replacements = {
        "Wasalthilake and Thangathurai": "Wasalthilake and Kartheeswaran",
        "94.04% reference validation accuracy; macro-F1 0.940": "88.61% held-out test accuracy; macro-F1 0.8814",
        "Adds local mobile integration, but Unicode mapping and child-field validity remain open.": "Adds local mobile integration and five verified Unicode mappings; child-field validity remains open.",
        "94.04% on n=10,896 validation images": "88.61% on n=11,984 protected test images",
        "ECE 0.084 on reference validation data": "ECE 0.0515 on protected test data",
        "Physical-device median and p95 pending": "Emulator mean 83.58 ms and p95 140.79 ms; physical device pending",
        "Held-out/reference validation images": "Protected held-out test images",
        "Implement numeric-ID-to-Unicode mapping and tests for five letters": "Completed: versioned numeric-ID-to-Unicode mapping and tests for five exposed letters",
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
        ("Grade 1 learner", "Large, simple controls; letter/word learning; supportive retry feedback", "High user impact", "Five verified tracing letters, audio cues, picture-supported choices and minimal text"),
        ("Grade 2 learner", "Word construction, pillam practice, short stories and comprehension", "High user impact", "Separate Grade 2 tasks and grade-filtered content"),
        ("Parent / teacher", "Understand activity, progress and areas needing practice", "High decision influence", "Authenticated dashboard, scalar trace evidence and non-diagnostic wording"),
        ("Researcher/developer", "Reproducible models, measurable tests and traceable claims", "High technical influence", "Frozen manifests, model hashes, automated tests and reports"),
        ("Supervisor / university", "Methodological validity, ethics and assessable contribution", "High governance influence", "Evidence boundaries, IEEE citations, documented limitations and approval gates"),
        ("Firebase / Gemini provider", "Secure and legitimate service use", "Infrastructure dependency", "App Check, timeouts, server-side API credential and local fallback"),
    ], font_size=7.9)

    doc.add_heading("4.3 Operationalization of the Research Objectives", level=2)
    add_table(doc, ["Objective", "Question / evidence source", "Operational requirement", "Measure"], [
        ("RO1 Identify", "Literature and two-teacher exploratory input", "Capture early-literacy difficulties without claiming prevalence", "Traceable themes and requirement rationale"),
        ("RO2 Analyze", "HCR, readability, mobile and child-design literature", "Compare candidate algorithms and architectures", "Suitability matrix and explicit trade-offs"),
        ("RO3 Develop", "Flutter repository and model assets", "Implement separated CNN, classifier, router and conversational service", "Passing functional and integration tests"),
        ("RO4 Evaluate", "Frozen test split, parity data and emulator logs", "Quantify model and deployment performance", "Accuracy, macro-F1, top-k, ECE, parity and latency"),
    ], font_size=8.1)

    doc.add_heading("4.4 Requirement Elicitation and Validation", level=2)
    add_body(doc, "Requirements were triangulated from the supplied interim documents, the two-teacher exploratory responses, recent literature, the Grade 1/2 boundary, and direct inspection of the implemented repository. A requirement was retained only when it had a user need, research rationale and feasible verification method. For example, handwriting feedback was retained because letter recognition and formation were reported by both exploratory respondents and because the HCR literature establishes technical feasibility. Conversely, diagnosis of dyslexia and automated pronunciation grading were excluded because the system lacks validated constructs, labels and clinical evidence.")
    add_callout(doc, "Validity rule", "The two-teacher input is design evidence, not a representative survey. Percentages are therefore expressed as respondent counts (2/2 or 1/2), and no population prevalence or causal inference is made.", PALE_ORANGE)

    doc.add_heading("4.5 System and Model Analysis", level=2)
    add_body(doc, "ReadBuddy AI is a hybrid mobile system with four deliberately separate intelligence components. The CNN performs only isolated Sinhala handwriting classification. The logistic model provides only a Grade 1/2 text-difficulty cross-check. The local intent router selects known learning functions and creates deterministic interactive exercises. Firebase AI Logic answers only unmatched conversational questions. This separation prevents a generative answer from being mistaken for model evidence and allows each component to be tested against a task-appropriate contract.")
    add_table(doc, ["Component", "Input", "Output", "Primary failure handling"], [
        ("CNN", "64×64 grayscale trace", "Class ID, optional verified Unicode and confidence", "Unscored attempt with retry guidance"),
        ("Text classifier", "Authored Sinhala text features", "Grade 1/2 review flag", "Keep authored grade and request human review"),
        ("Intent router", "English/Sinhala message", "Known intent, exercise or unknown", "Ask clarification or delegate unknown conversation"),
        ("Firebase AI Logic", "Minimal conversational prompt", "Short child-friendly explanation", "Timeout/error/blocked friendly fallback"),
    ])

    doc.add_heading("4.6 Use Cases and Specifications", level=2)
    doc.add_picture(str(ASSETS / "use_case_diagram.png"), width=Inches(6.3))
    _center_last_picture(doc)
    add_caption(doc, "Figure 4.1. Principal learner, adult and Firebase use cases within the ReadBuddy AI boundary.")
    add_table(doc, ["Use case", "Precondition", "Main success flow", "Alternative / postcondition"], [
        ("UC-01 Trace letter", "Grade 1 profile; model loaded; supported letter", "Learner draws → taps Check → CNN predicts → mapping and threshold evaluated", "Failure remains unscored; typed evidence is stored only for successful inference"),
        ("UC-02 Read story", "Profile and grade selected", "System filters story → displays text → optional TTS → quiz", "Classifier disagreement flags author review; learner's selected content is not silently relabelled"),
        ("UC-03 Request exercise", "AI Help available", "Router detects complete Sinhala/English words → creates one question with three options", "Ambiguous known request produces clarification"),
        ("UC-04 Ask conversation", "Firebase initialized and network available", "Unknown local intent → App Check → Firebase AI Logic → bounded answer", "Timeout, blocked or unavailable reply becomes a friendly fallback"),
        ("UC-05 Review progress", "Authenticated parent/teacher access", "Load task attempts → aggregate scores and trace evidence → display guidance", "No diagnostic label; empty state explains how to collect evidence"),
    ], font_size=7.5)

    doc.add_heading("4.7 Class Model", level=2)
    doc.add_picture(str(ASSETS / "class_model_diagram.png"), width=Inches(6.4))
    _center_last_picture(doc)
    add_caption(doc, "Figure 4.2. Core domain and service class model for evidence-aware learning activities.")
    add_body(doc, "The model separates mutable learner records from service contracts. TaskAttempt is the evidence boundary: it can retain a score, timestamp and optional model metadata without retaining a raw trace image. LetterClassifierService owns tensor validation and prediction identity; AIService owns deterministic routing; FirebaseAIChatService owns the external conversational boundary.")

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
    add_caption(doc, "Figure 4.5. Sequence of deterministic local routing and protected conversational fallback.")

    doc.add_heading("4.10 Deployment and Proposed Architecture", level=2)
    doc.add_picture(str(ASSETS / "deployment_trust_boundary.png"), width=Inches(6.35))
    _center_last_picture(doc)
    add_caption(doc, "Figure 4.6. Deployment structure and privacy/trust boundaries.")
    add_body(doc, "Most child-facing intelligence remains on the Android device. Authentication and progress synchronization use Firebase. Firebase AI Logic is reached only for unmatched conversation; its proxy and App Check protect the Gemini Developer API credential so it is not embedded in Dart source or the APK [25], [26]. This design keeps the system usable for core learning when conversational AI is unavailable.")

    doc.add_heading("4.11 Functional and Non-functional Requirements", level=2)
    add_table(doc, ["ID", "Functional requirement", "Priority", "Verification"], [
        ("FR-01", "Support only Grade 1 and Grade 2 content and profiles", "Must", "Widget and scope tests"),
        ("FR-02", "Provide bilingual Sinhala/English navigation and commands", "Must", "Localization and router tests"),
        ("FR-03", "Classify supported Sinhala traces using bundled TFLite", "Must", "Model contract and integration benchmark"),
        ("FR-04", "Map only independently verified class IDs to Unicode", "Must", "Five deterministic mapping cases"),
        ("FR-05", "Provide grade-filtered reading, TTS and comprehension", "Must", "Functional reading tests"),
        ("FR-06", "Create local three-option letter exercises", "Must", "English/Sinhala chatbot tests"),
        ("FR-07", "Use Firebase AI Logic only for unknown conversation", "Should", "Prompt/router/fallback tests"),
        ("FR-08", "Store progress and scalar trace evidence", "Must", "Serialization and aggregation tests"),
        ("FR-09", "Show adult progress without diagnostic wording", "Must", "UI/content inspection"),
        ("FR-10", "Classify authored text as a Grade 1/2 review signal", "Could", "Classifier unit tests and limitation audit"),
    ], font_size=7.5)
    add_table(doc, ["ID", "Non-functional requirement", "Target / rationale", "Evidence"], [
        ("NFR-01", "Usability", "Large touch targets, consistent navigation and child-friendly feedback", "Theme and widget tests; screenshot review"),
        ("NFR-02", "Performance", "Interactive on-device inference; report mean and p95 rather than hide tails", "Android emulator benchmark"),
        ("NFR-03", "Reliability", "Reject invalid tensor/label contracts; provide explicit fallbacks", "Negative-path tests"),
        ("NFR-04", "Privacy", "No raw trace upload; minimize conversational prompt data", "Architecture and code inspection"),
        ("NFR-05", "Security", "Authenticated access and App Check for Firebase AI", "Configuration/code inspection"),
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
    add_body(doc, "This chapter explains how ReadBuddy AI was implemented and why each significant design decision supports the research. Generic account screens are mentioned only where they enforce a trust boundary; emphasis is placed on the two research models, the bilingual intent architecture, evidence-aware progress, child-facing interaction and deployment controls.")

    doc.add_heading("5.2 Technology Selection and Justification", level=2)
    add_table(doc, ["Technology", "Purpose", "Reason for selection", "Trade-off"], [
        ("Dart / Flutter", "Cross-platform mobile UI and local logic", "One codebase, Material components, strong test tooling and Firebase integration", "Plugin/native build dependencies"),
        ("Python / TensorFlow", "CNN audit, training and evaluation", "Reproducible numerical ecosystem and TFLite export", "Training is separate from the mobile runtime"),
        ("scikit-learn", "Interpretable Grade 1/2 logistic model", "Transparent coefficients and small deployment footprint", "Insufficient evidence at n=26 [21]"),
        ("TensorFlow Lite", "Offline CNN inference", "Low-latency mobile execution and no trace upload", "Operator/device differences require parity and runtime testing"),
        ("Firebase Auth/Firestore", "Identity and progress persistence", "Existing Flutter support and role-aware cloud synchronization", "Network dependency for synchronized data"),
        ("Firebase AI Logic", "Unmatched conversational questions", "Official Dart SDK, App Check, server-side credential and free-tier path [25]", "Availability, quota and generated-answer uncertainty"),
        ("Git and model hashes", "Version and evidence control", "Links claims to exact source/model artifacts", "Requires disciplined artifact registration"),
    ], font_size=7.7)

    doc.add_heading("5.3 Component 1 — Sinhala Letter CNN", level=2)
    add_body(doc, "The final training pipeline begins by hashing every source image. Exact duplicates are assigned as a group so that the same byte content cannot appear in both fitting and evaluation data. Seven cross-label conflicts are quarantined. The remaining 79,788 unique samples are stratified into 70% training, 15% validation and 15% test partitions with seed 42. The test partition is untouched until validation-based model selection is complete.")
    add_equation(doc, "x′ = grayscale(resize(compositeWhite(PNG), 64, 64)) / 255")
    add_body(doc, "The network applies 32, 64 and 128 3×3 convolution filters; max pooling follows the first two convolutions. The 18,432-value flattened representation feeds a 128-unit dense layer, dropout 0.30 and a 454-way softmax. Adam (learning rate 0.001) minimizes sparse categorical cross-entropy in batches of 64 for at most 40 epochs. Early stopping monitors validation loss and restores the best weights.")
    add_code(doc, "ALGORITHM 1 — LEAKAGE-AWARE CNN PIPELINE\nfor each publisher image:\n    decode, validate label 1..454, compute SHA-256\nquarantine any hash associated with more than one label\nkeep every remaining identical-hash group in one seeded split\ntrain custom CNN on train; select checkpoint using validation only\nevaluate selected checkpoint once on protected test\nconvert to TFLite; require ≥98% Keras/TFLite top-1 agreement")
    add_body(doc, "The Flutter service validates float32 input [1,64,64,1], float32 output [1,454], exactly 454 unique numeric labels and the supported class range before prediction. Output index i maps to one-based dataset class ID labels[i]. Only IDs 1, 2, 12, 25 and 250 are presently mapped to අ, ආ, ක, ග and ස. Any other result is displayed internally as class:<ID> rather than guessed as a Sinhala character.")

    doc.add_heading("5.4 Component 2 — Grade 1/2 Text-Difficulty Proof of Concept", level=2)
    add_body(doc, "The text component extracts word count, mean word length and mean sentence length from authored content. A binary logistic-regression equation estimates a Grade 2 score; the coefficients are ported to Dart so classification is offline and deterministic. This model does not replace the authored grade label. It acts as a quality-control signal: agreement increases confidence in content selection, while disagreement requests human review.")
    add_equation(doc, "P(Grade 2 | x) = 1 / (1 + exp(−(β₀ + β₁words + β₂meanWordLength + β₃meanSentenceLength)))")
    add_callout(doc, "Proof-of-concept boundary", "The corpus contains only 26 authored texts (9 Grade 1 and 17 Grade 2). Its 69.2% resubstitution accuracy is only 3.8 percentage points above the 65.4% majority training baseline and cannot support a production-grade generalization claim.", PALE_ORANGE)

    doc.add_heading("5.5 Hybrid Bilingual Assistant", level=2)
    add_body(doc, "The local router normalizes case and punctuation and matches complete tokens rather than substrings. It recognizes Grade 1/2 exercise, letter, choose/select, task, remember, pronunciation, reading, writing, help, progress, summary, quiz and greeting intentions in English and Sinhala. A letter-selection request produces a real interactive question with three options and a stored correct answer. If a request is ambiguous but appears task-oriented, the assistant asks which activity and grade the user wants. Only genuinely unmatched conversation is forwarded to Firebase AI Logic.")
    add_code(doc, "ALGORITHM 2 — HYBRID CHAT ROUTING\nroute = localIntentRouter(message, language, profileGrade)\nif route has deterministic response or exercise:\n    render locally without network\nelse:\n    show loading state\n    request Firebase AI Logic with App Check and timeout\n    if answer is non-empty and not blocked: render bounded answer\n    else: render friendly retry/activity fallback")
    add_body(doc, "The AI service uses the Gemini Developer API through Firebase AI Logic. The proxy retains the provider credential server-side, while App Check verifies that calls originate from an authorized application [25], [26]. Empty candidates, empty content, blocked responses, timeouts and SDK failures are logged diagnostically but converted to child-friendly messages. Learner names, progress, handwriting images and CNN results are excluded from the conversational prompt.")

    doc.add_heading("5.6 Reading, Comprehension and Learning Modules", level=2)
    add_body(doc, "The Grade 1 path emphasizes letter exploration, example words, picture-supported initial-letter selection, letter matching and tracing. The Grade 2 path introduces picture-supported pillam exploration, explicit consonant-plus-sign sound building, word construction, pillam recognition/fill tasks, longer texts and inferential questions. Reading content is filtered by the stored grade, can be spoken through local text-to-speech and is followed by rule-generated comprehension questions. This design follows the research boundary: the CNN is not used to generate stories, and the generative service is not used to grade handwriting.")

    doc.add_heading("5.7 Progress and Evidence Design", level=2)
    add_body(doc, "Task results record the task identity, score and timestamp. Successfully inferred tracing attempts additionally store expected letter, numeric class ID, optional mapped letter, confidence, inference latency, correctness and model version. Daily activity synchronization distinguishes active learning days from app-open-only days. The learner progress service aggregates attempts, accuracy, tracing evidence and skill history, while the authenticated teacher dashboard groups linked learners by grade and exposes individual activity, task and coaching summaries. Evidence-based coaching identifies repeatedly weak items, mastered skills and recent improvement without producing a diagnostic label. Raw tracing images and direct student identifiers are excluded from the sanitized research export.")

    doc.add_heading("5.8 User-interface Design and Execution Evidence", level=2)
    add_body(doc, "The app-wide visual system uses a consistent indigo identity with semantic accents for learning, AI help and progress. Material 3 cards, rounded surfaces, minimum 48-pixel primary controls, bilingual labels and predictable five-area navigation reduce interaction cost for young learners and adults. The home story follows the selected grade rather than always displaying Grade 2 content. These choices should still be validated with accessibility scanning and supervised user testing rather than assumed effective [27].")
    if SCREENSHOT_COMPOSITE.exists():
        doc.add_picture(str(SCREENSHOT_COMPOSITE), width=Inches(5.6))
        _center_last_picture(doc)
        add_caption(doc, "Figure 5.1. NenaPotha AI final Android implementation evidence across learner, Grade 2, progress and teacher workflows.")
    add_body(doc, "Figure 5.1 demonstrates that the final Flutter application renders the principal learner and teacher workflows on Android. The complete dated screenshot set is reproduced in Appendix I and covers language selection, authentication, learner-profile creation, the home dashboard, Grade 2 learning, progress evidence, the learner profile and teacher–student linking. These screenshots establish implementation and navigation evidence; they do not by themselves prove usability, accessibility or learning effectiveness.")

    doc.add_heading("5.9 Security, Privacy and Failure-state Implementation", level=2)
    add_bullets(doc, [
        "No Gemini API key is stored in Dart, env.json or the APK; Firebase AI Logic mediates access.",
        "Debug App Check is limited to development; Play Integrity is the release provider.",
        "The CNN runs locally and raw traces do not need to leave the device.",
        "A classifier loading/inference failure cannot be marked correct through a geometric fallback.",
        "The assistant exposes loading, timeout, blocked, empty-response and friendly fallback states.",
        "Progress language uses practice indicators rather than diagnostic or clinical labels.",
        "Model version and SHA-256 identity connect app evidence to the evaluated artifact.",
    ])
    add_body(doc, "These controls operationalize the reliability, privacy, transparency and safety concerns emphasized by the NIST AI Risk Management Framework [28]. They do not eliminate all risks; they make known risks measurable and prevent unsupported output from being silently presented as evidence.")

    doc.add_heading("5.10 Chapter Summary", level=2)
    add_body(doc, "Chapter 5 described the implemented mobile, machine-learning and conversational layers. The most important engineering contribution is not any single model: it is the separation of responsibilities, leakage-aware data handling, explicit label identity, honest abstention and evidence-aware integration. Chapter 6 tests these claims quantitatively and functionally.")
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
        "Run service, mapping, routing, persistence and widget tests.",
        "Benchmark the exact bundled model through the Android integration path.",
        "Interpret technical evidence separately from unperformed child usability and learning studies.",
    ])

    doc.add_heading("6.3 Test Plan and Principal Test Cases", level=2)
    add_table(doc, ["ID", "Test and eligibility rationale", "Expected result", "Observed status"], [
        ("TC-01", "Analyzer — detects source-level type/lint issues", "No issues", "Pass"),
        ("TC-02", "Dataset integrity — prevents exact duplicate leakage", "All hash groups remain in one split; conflicts quarantined", "Pass"),
        ("TC-03", "Model tensor contract — prevents incompatible assets", "[1,64,64,1] input and [1,454] output accepted", "Pass"),
        ("TC-04", "Label contract — prevents numeric/Unicode identity errors", "454 unique IDs and five mappings verified", "Pass"),
        ("TC-05", "Trace decision — protects stored/UI agreement", "Expected mapping and ≥0.50 confidence both required", "Pass"),
        ("TC-06", "Failure path — avoids false success", "Unavailable inference remains unscored", "Pass"),
        ("TC-07", "English router — whole-word exercise request", "Interactive three-option Grade 1/2 exercise", "Pass"),
        ("TC-08", "Sinhala router — bilingual equivalence", "Same deterministic route for Sinhala request", "Pass"),
        ("TC-09", "Firebase AI fallback — safe asynchronous states", "Loading, timeout/error/blocked friendly response", "Pass in automated path; service availability external"),
        ("TC-10", "Android integration benchmark — real mobile runtime path", "Load exact bundled model and complete repeated inference", "Pass on Android 14 emulator"),
    ], font_size=7.2)

    doc.add_heading("6.4 Functional Testing Results", level=2)
    add_body(doc, "All 125 current Flutter tests pass. The suite exercises language selection, five-area navigation, Grade 1/2 learning paths, verified pillam names and picture coverage, pillam detail navigation, story comprehension, progress analytics, teacher coaching, daily activity evidence, mapping validation, threshold decisions, trace evidence serialization and aggregation, privacy-preserving exports, English/Sinhala chat routing, exercise generation, Firebase prompt boundaries and friendly fallback messages. Python tests validate deterministic splitting, duplicate containment, conflicting-label rejection and frozen-manifest integrity. Static analysis reports no issues. The Android integration test loads the bundled model and executes native inference.")
    add_table(doc, ["Verification layer", "Latest recorded result", "Interpretation"], [
        ("Flutter static analysis", "No issues found", "Source-level quality gate passed"),
        ("Flutter unit/widget tests", "125/125 tests passed", "Specified decision, evidence and UI behaviours passed"),
        ("Python pipeline tests", "Dataset/split integrity tests pass", "Reproducibility controls behave as designed"),
        ("Android CNN integration", "Model load and 30 measured inference runs pass", "On-device path is technically feasible on emulator"),
        ("Physical-device pilot", "Workflow implemented; phone result pending", "No physical-device claim is made"),
        ("Child usability/effectiveness", "Not conducted", "No learning-gain or child-usability claim is made"),
    ])

    doc.add_heading("6.5 Non-functional Testing", level=2)
    add_table(doc, ["Quality attribute", "Method", "Result", "Limitation"], [
        ("Performance", "5 warm-ups + 30 native emulator runs", "Mean 83.58 ms; p95 140.79 ms", "Android x86_64 emulator, not ARM phone"),
        ("Portability", "Flutter Android build/install/launch", "Pass on Android 14 emulator", "iOS and low-end phones not benchmarked"),
        ("Reliability", "Invalid labels/tensors and inference failures", "Rejected or unscored", "Long-duration stress testing pending"),
        ("Security", "Credential/code/config audit and App Check architecture", "No Gemini key embedded; protected proxy design", "Production attestation must remain configured"),
        ("Privacy", "Data-flow and sanitized export inspection", "Raw traces and direct identifiers excluded", "Firestore rules require periodic review"),
        ("Maintainability", "Analyzer, modular services, versioned artifacts", "No analyzer issues; typed boundaries", "Test coverage percentage not claimed"),
        ("Accessibility", "Theme/widget checks and minimum target design", "Implemented design baseline", "Formal scanner and child observation pending"),
    ], font_size=7.5)

    doc.add_heading("6.6 CNN Results", level=2)
    doc.add_picture(str(ASSETS / "cnn_protected_test_metrics.png"), width=Inches(6.35))
    _center_last_picture(doc)
    add_caption(doc, "Figure 6.1. Performance of the custom CNN on the protected 11,984-image test partition.")
    add_table(doc, ["Measure", "Custom CNN", "Low-capacity control", "Research interpretation"], [
        ("Top-1 accuracy", "88.61%", "0.25%", "Custom CNN learns useful structure; control is near 1/454 chance"),
        ("95% Wilson CI", "88.03%–89.17%", "Not emphasized", "Quantifies image-level sampling uncertainty"),
        ("Macro precision", "88.86%", "<0.01%", "Per-class precision remains high on average"),
        ("Macro recall / balanced accuracy", "88.11%", "0.22%", "Class-balanced performance is close to aggregate accuracy"),
        ("Macro-F1", "88.14%", "<0.01%", "Precision/recall balance across 454 classes"),
        ("Top-2 / Top-3", "92.05% / 93.51%", "0.49% / 0.73%", "Correct label often remains among close alternatives"),
        ("ECE / log loss", "0.0515 / 0.7319", "0.00005 / 6.1118", "Control's low ECE is meaningless with uniform near-chance predictions"),
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
    add_body(doc, "The CNN result is materially more credible than the earlier 94.04% publisher-split validation figure because the final protocol detected 8,551 hashes crossing publisher splits and rebuilt a disjoint exact-hash split. The lower but protected 88.61% test score is therefore the headline result. However, images may still be correlated by writer because reliable writer IDs were not available; the Wilson interval can consequently understate uncertainty.")

    doc.add_heading("6.7 Conversion and Deployment Results", level=2)
    add_table(doc, ["Evidence", "Result"], [
        ("Evaluated TFLite size", "2,527,920 bytes (approximately 2.41 MiB)"),
        ("TFLite SHA-256", "ad082e94b4f80f4b55d265f98c057972107dfd1d5245675cebc1c56ba0e0b189"),
        ("Parity sample count", "100 registered protected samples"),
        ("Keras–TFLite top-1 agreement", "99.00%"),
        ("Mean absolute probability difference", "0.00002762"),
        ("Android 14 emulator native inference", "Mean 83.58 ms; p95 140.79 ms over 30 measured runs"),
    ])
    add_body(doc, "The exact TFLite hash matches the evaluated conversion, bundled Flutter asset and runtime evidence. This identity check is important because a benchmark of a different artifact would not validate the model reported in the results. Ninety-nine percent top-1 parity exceeds the predefined 98% gate, though one disagreement and a maximum probability difference of 0.0834 justify retaining versioned conversion tests.")

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
    add_body(doc, "The hybrid assistant improves functional coverage without changing the research model claims. Deterministic local routes answer predictable learning requests consistently and without network cost. Firebase AI Logic is reserved for conversation and protected by App Check, as recommended in the official architecture [25], [26]. Generated answers remain a possible source of error and should support adults or low-stakes explanation rather than determine grades, diagnoses or stored model outcomes.")
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
    add_body(doc, "Chapter 6 reported the verified testing and evaluation outcomes. The protected CNN test result, Keras–TFLite parity, artifact identity, automated tests and emulator benchmark support the technical feasibility of ReadBuddy AI. The text classifier remains a transparent proof of concept, and participant outcomes remain unmeasured. These evidence boundaries guide the objective assessment and future recommendations in Chapter 7.")
    doc.add_page_break()


def chapter_seven(doc: Document) -> None:
    doc.add_heading("Chapter 07 — Concluding Remarks", level=1)
    doc.add_heading("7.1 Research Conclusion", level=2)
    add_body(doc, "This research designed, developed and technically evaluated ReadBuddy AI, a bilingual Grade 1–2 mobile reading assistant that integrates offline Sinhala letter recognition, grade-aware content review, deterministic learning routes and protected conversational support. The study demonstrates that trustworthy integration requires more than model accuracy: duplicate-aware data management, explicit label identity, conversion parity, failure-state design, privacy boundaries and claim discipline are equally important.")

    doc.add_heading("7.2 Accomplishment of the Research Objectives", level=2)
    add_table(doc, ["Objective", "Triangulated evidence", "Achievement"], [
        ("RO1 — Identify gaps", "Recent literature, official Sri Lankan context, exploratory teacher input and repository audit", "Achieved: defined bounded HCR, readability and integration gaps"),
        ("RO2 — Analyze approaches", "Comparative HCR/readability/mobile/architecture review and suitability decisions", "Achieved: justified CNN, logistic proof of concept and hybrid deployment"),
        ("RO3 — Develop artifact", "Flutter modules, trained TFLite CNN, Dart classifier, intent router, Firebase AI Logic and evidence service", "Achieved within Grade 1/2 and five-letter mapping boundary"),
        ("RO4 — Evaluate", "Protected 11,984-image test, macro/top-k/calibration metrics, parity, automated tests and emulator benchmark", "Technically achieved; child field effectiveness remains future work"),
    ], font_size=8.0)

    doc.add_heading("7.3 Problems Encountered and Resolutions", level=2)
    add_table(doc, ["Problem", "Why it mattered", "Resolution / lesson"], [
        ("Publisher split leakage", "Duplicated images could inflate evaluation", "SHA-256 audit, conflict quarantine and deterministic regrouping"),
        ("Numeric labels compared with Unicode", "Could mark correct traces as wrong or guess identities", "Versioned mapping for five independently verified letters"),
        ("Legacy 94.04% terminology", "Validation result was incorrectly treated as test-like evidence", "Excluded from headline and replaced by protected 88.61% test result"),
        ("Tiny Grade 1/2 text corpus", "No credible hold-out or cross-validation conclusion", "Downgraded to proof-of-concept human-review signal"),
        ("Mobile API credential risk", "Hardcoded secrets are extractable from APKs", "Firebase AI Logic proxy plus App Check; no embedded Gemini key"),
        ("Empty/blocked AI replies", "Poor user experience and internal error exposure", "Diagnostics, timeout and child-friendly fallback states"),
        ("Physical phone connection/build delay", "Final device performance could not be recorded", "Reproducible benchmark script retained; claim limited to emulator"),
    ], font_size=7.7)

    doc.add_heading("7.4 Self-reflection and Research Ideology", level=2)
    add_body(doc, "The strongest learning from this study was that an honest lower result is more valuable than a higher but weakly controlled result. Initially, a 94.04% validation figure appeared attractive. The leakage audit showed why that value should not headline the research, and the protected 88.61% test result became a stronger contribution. The same principle changed the treatment of the text classifier: instead of calling 69.2% 'accuracy' without qualification, the final design labels it resubstitution performance and restricts its role.")
    add_body(doc, "The project also changed my view of AI integration. A system does not become intelligent by sending every input to a generative model. ReadBuddy works more responsibly when deterministic learning tasks, the handwriting CNN, the text classifier and conversational AI remain separate. This architecture improves reproducibility, cost control, privacy and the ability to explain failures to a supervisor, teacher and parent.")

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
    add_body(doc, "The architecture also generalizes beyond the immediate application. Other low-resource scripts can adopt the same pattern: a task-specific on-device model with explicit label identity, an interpretable content-quality check, deterministic local routing and a protected conversational service. The research value lies in the pattern and evidence contract, not only the current set of five mapped letters.")

    doc.add_heading("7.7 Future Recommendations", level=2)
    add_numbered(doc, [
        "Complete an authoritative numeric-class-to-Unicode mapping for all curriculum-relevant classes, independently reviewed by Sinhala language experts.",
        "Repeat the registered CNN experiment across multiple seeds and add writer-grouped or perceptual-near-duplicate evaluation where metadata permits.",
        "Run the provided benchmark on low-, mid- and high-range physical Android devices and report release APK size, load time, p50/p95 latency, memory and offline behaviour.",
        "Conduct an adult/synthetic tracing pilot first; involve children only after institutional ethics, school permission, guardian consent and child assent.",
        "Collect representative Grade 1/2 touchscreen traces, preserve writer groups and evaluate per-letter recall, calibration and abstention.",
        "Create a larger balanced Sinhala readability corpus with independent teacher labels and inter-rater agreement; add akshara, morphology, vocabulary and cohesion features.",
        "Evaluate local routing coverage, clarification quality and Firebase AI answers with a bilingual safety/appropriateness rubric.",
        "Perform formal Flutter accessibility checks, teacher/parent UAT and a preregistered active-control learning study before claiming educational impact.",
        "Use Remote Config or a server prompt template for controlled conversational-model changes without exposing secrets or requiring an app release.",
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
        '[25] Google, “Gemini API using Firebase AI Logic,” Firebase Documentation, Sep. 2026. [Online]. Available: https://firebase.google.com/docs/ai-logic. [Accessed: Sep. 29, 2026].',
        '[26] Google, “Prevent Gemini API abuse with Firebase App Check,” Firebase Documentation, 2026. [Online]. Available: https://firebase.google.com/docs/ai-logic/app-check. [Accessed: Sep. 29, 2026].',
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
        "What safeguards are required before a child uses conversational or speech features?",
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
        "Pseudonymize learner identity and retain raw handwriting or voice only when scientifically necessary and approved.",
        "Separate recognition, usability and learning outcomes; never label intelligence, disability or clinical status.",
        "Begin with adult or synthetic traces and predefined technical stopping rules before any child pilot.",
    ])

    doc.add_page_break()
    doc.add_heading("Appendix E — Dataset and Supplementary Evidence", level=1)
    add_table(doc, ["Dataset characteristic", "Registered value"], [
        ("Publisher image paths audited", "108,933"),
        ("Usable unique samples after validation and conflict handling", "79,788"),
        ("Class count", "454 numeric output classes"),
        ("Protected split", "55,820 training / 11,984 validation / 11,984 test"),
        ("Split policy", "Exact SHA-256 groups retained within one deterministic split; seed 42"),
        ("Input format", "64 × 64 single-channel grayscale"),
        ("Mapped app classes", "1→අ, 2→ආ, 12→ක, 25→ග, 250→ස"),
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
        ("FR-07", "Route known bilingual requests locally and unknown conversation through protected AI", "Intent-router and Firebase prompt-boundary tests"),
        ("FR-08", "Present friendly loading, timeout, blocked and failure states", "Service and widget tests"),
    ], font_size=8.0)
    add_table(doc, ["ID", "Non-functional requirement", "Target / evidence"], [
        ("NFR-01", "Usability", "Large touch targets, predictable navigation, child-friendly feedback"),
        ("NFR-02", "Privacy", "No Gemini key in APK; no raw trace sent to conversational AI"),
        ("NFR-03", "Reliability", "Model failure abstains rather than awarding a correct score"),
        ("NFR-04", "Performance", "Recorded emulator mean 83.58 ms and p95 140.79 ms CNN inference"),
        ("NFR-05", "Maintainability", "Separated CNN, text classifier, intent router and conversational services"),
        ("NFR-06", "Testability", "No analyzer issues and 125/125 Flutter tests passing"),
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
    add_body(doc, "Figures I.1–I.13 are dated Android-emulator captures from the final application workflow supplied on 29 September 2026. Demonstration identities and join codes are test data. The figures document implementation state; they are not participant-study evidence.")
    for index, (filename, caption) in enumerate(SCREENSHOT_MANIFEST, start=1):
        path = SCREENSHOTS_DIR / filename
        if not path.exists():
            continue
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.add_run().add_picture(str(path), width=Inches(3.05))
        add_caption(doc, f"Figure I.{index}. {caption}.")
        if index != len(SCREENSHOT_MANIFEST):
            doc.add_page_break()

    doc.add_page_break()
    doc.add_heading("Appendix J — Algorithm, Model and Technical Configuration", level=1)
    add_table(doc, ["CNN configuration", "Registered value"], [
        ("Input / output", "float32 [1,64,64,1] → float32 [1,454]"),
        ("Architecture", "Three convolution layers; max pooling after first two; dense 128; dropout 0.30; softmax 454"),
        ("Optimization", "Adam, learning rate 0.001, sparse categorical cross-entropy"),
        ("Training", "Batch 64; maximum 40 epochs; validation-loss early stopping"),
        ("Preprocessing", "Decode, grayscale, crop-normalize, resize 64 × 64, normalize intensity"),
        ("Decision gate", "Expected Unicode mapping and confidence ≥0.50; otherwise abstain/retry"),
        ("Deployment", "2,527,920-byte TensorFlow Lite model"),
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
        ("Flutter unit/widget suite", "All specified services and UI behaviours pass", "Pass — 125/125"),
        ("Pillam selection navigation", "Selected detail panel scrolls into view", "Pass — regression test included"),
        ("Dataset integrity", "Hash groups stay in one split; conflicts quarantined", "Pass"),
        ("Tensor contract", "Bundled asset exposes [1,64,64,1] and [1,454]", "Pass"),
        ("Unicode mapping", "All exposed app letters map deterministically", "Pass for five exposed classes"),
        ("Keras–TFLite parity", "At least 98% top-1 agreement", "Pass — 99/100"),
        ("Android integration", "Load bundled model and complete native inference", "Pass on Android 14 emulator"),
        ("Conversational failures", "Timeout/blocked/empty output becomes child-friendly fallback", "Pass in deterministic service tests"),
        ("Physical-device benchmark", "Defined low/mid/high-device results", "Pending; no physical-device performance claim"),
    ], font_size=8.0)

    doc.add_page_break()
    doc.add_heading("Appendix L — User Acceptance and Expert Evaluation Instrument", level=1)
    add_callout(doc, "Administration condition", "Use this blank instrument only after supervisor authorization. Record respondent role and consent; do not present an unadministered form as evaluation results.")
    add_table(doc, ["Statement", "1", "2", "3", "4", "5", "Comment"], [
        ("The main navigation is clear.", "", "", "", "", "", ""),
        ("Text, colour and touch targets are suitable for the intended age.", "", "", "", "", "", ""),
        ("Grade 1 and Grade 2 activities are appropriately separated.", "", "", "", "", "", ""),
        ("Tracing feedback is understandable and appropriately cautious.", "", "", "", "", "", ""),
        ("Progress evidence is useful to a parent or teacher.", "", "", "", "", "", ""),
        ("Sinhala and English controls are understandable.", "", "", "", "", "", ""),
        ("Error and offline states are acceptable.", "", "", "", "", "", ""),
        ("I would recommend supervised pilot use after corrections.", "", "", "", "", "", ""),
    ], font_size=7.2)
    add_body(doc, "Scale: 1 = strongly disagree; 2 = disagree; 3 = neutral; 4 = agree; 5 = strongly agree. Respondent role: __________  Date: __________  Consent recorded: Yes / No")

    doc.add_page_break()
    doc.add_heading("Appendix M — Evaluation Results and Supplementary Analysis", level=1)
    add_table(doc, ["Metric", "Custom CNN result", "Interpretation boundary"], [
        ("Protected top-1 accuracy", "88.61%", "Reference test-set performance, not child touchscreen accuracy"),
        ("Macro precision", "88.86%", "Class-balanced precision summary"),
        ("Macro recall", "88.11%", "Class-balanced recall summary"),
        ("Macro F1", "88.14%", "Class-balanced precision/recall balance"),
        ("Top-2 / top-3 accuracy", "92.05% / 93.51%", "Candidate coverage; app still requires identity gating"),
        ("Expected calibration error", "0.0515", "Confidence calibration on the protected test set"),
        ("Keras–TFLite agreement", "99.00% on 100 samples", "Conversion parity sample, not new accuracy evidence"),
        ("Emulator inference", "Mean 83.58 ms; p95 140.79 ms", "Android 14 emulator only"),
    ])
    for path, caption in [
        (ASSETS / "cnn_protected_test_metrics.png", "Figure M.1. Protected held-out CNN performance metrics."),
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
        "If cloud or conversational support is unavailable, retry later and continue with the offline learning activities.",
        "Use the profile/logout controls to end the adult session on a shared device.",
    ])

    doc.add_page_break()
    doc.add_heading("Appendix O — Installation and Deployment Guide", level=1)
    add_code(doc, "flutter pub get\nflutter analyze\nflutter test\nflutter run")
    add_bullets(doc, [
        "Install the stable Flutter SDK, Android Studio/SDK and a supported Android emulator or device.",
        "Configure the authorized Firebase Android application using google-services.json; do not store a Gemini credential in Dart or the APK.",
        "Enable Firebase Authentication, Firestore, Firebase AI Logic with the Gemini Developer API provider and Firebase App Check.",
        "Register the App Check debug token only for development; use Play Integrity for a release build.",
        "Confirm that the bundled TFLite model and verified label asset retain their registered hashes before reporting research results.",
        "Build a release artifact only after analyzer, tests, Firestore rules and production App Check are verified.",
    ])

    doc.add_page_break()
    doc.add_heading("Appendix P — Supervisor Meeting Record", level=1)
    add_table(doc, ["Review point", "Supervisor feedback / decision", "Student action and date"], [
        ("Final Grade 1–2 scope and title", "", ""),
        ("Research question and four objectives", "", ""),
        ("Treatment of two-teacher exploratory input", "", ""),
        ("Protected test terminology and 88.61% result", "", ""),
        ("Text classifier proof-of-concept wording", "", ""),
        ("Screenshot and appendix selection", "", ""),
        ("Permission for participant or pilot activity", "", ""),
        ("Final formatting and submission corrections", "", ""),
    ], font_size=8.0)
    p = doc.add_paragraph("Supervisor name/signature: ______________________________    Date: ______________")
    p.paragraph_format.space_before = Pt(24)
    doc.add_paragraph("Student signature: _______________________________________    Date: ______________")

    doc.add_page_break()
    doc.add_heading("Appendix Q — Project Progress and Management Evidence", level=1)
    add_table(doc, ["Stage", "Principal output", "Evidence status"], [
        ("1", "Project audit, scope and baseline research components", "Completed and documented"),
        ("2", "Dataset preparation and leakage controls", "Completed and documented"),
        ("3", "Custom CNN training, protected evaluation and model registration", "Completed and documented"),
        ("4", "Flutter model integration and verified label contract", "Completed for five exposed mappings"),
        ("5", "Hybrid bilingual intent and protected conversational integration", "Implemented and tested"),
        ("6", "Technical evaluation package, parity, tests and emulator benchmark", "Completed; child field trial pending ethics"),
        ("7", "Physical-device protocol and final deployment evidence", "Protocol ready; physical-device benchmark pending"),
    ])

    doc.add_page_break()
    doc.add_heading("Appendix R — Source Code and Repository Information", level=1)
    add_table(doc, ["Repository area", "Purpose"], [
        ("lib/screens", "Learner, learning, tracing, reading, progress, profile and teacher interfaces"),
        ("lib/services", "CNN inference, progress, activity, coaching, intent, Firebase AI, authentication and persistence boundaries"),
        ("assets/models", "Bundled TensorFlow Lite model and label/mapping assets"),
        ("training", "Leakage-aware preparation, training, protected evaluation and deployment registration"),
        ("test", "Flutter unit and widget regression tests"),
        ("integration_test", "Android model-loading and native-inference integration path"),
        ("deliverables/stage6_evaluation", "Registered metrics, figures, summaries and pilot protocol"),
        ("tools", "Reproducible document and evaluation-report generation"),
    ])
    add_body(doc, "The complete repository should be submitted through the institution-approved channel. Hundreds of source-code pages are intentionally not printed; the appendix identifies the auditable locations and the installation guide defines how to reproduce the software checks.")

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
        ("Firebase AI Logic", "Unmatched conversational prompt and response", "App Check-protected proxy; no embedded API key"),
    ], font_size=7.6)
    add_body(doc, "CNN inference, shape comparison and the Grade 1/2 text-difficulty check run locally. The conversational prompt excludes learner names, stored progress, raw traces and CNN outputs. Debug App Check is a development-only configuration and must be replaced by production attestation before release.")

    doc.add_page_break()
    doc.add_heading("Appendix T — Supporting Evidence and Claim Register", level=1)
    add_table(doc, ["Claim", "Supporting artifact", "Permitted conclusion"], [
        ("Protected CNN performance", "custom_cnn_metrics.json and classification report", "88.61% reference test accuracy under the registered split"),
        ("Deployment parity", "keras_tflite_parity.json", "99% top-1 agreement on the registered 100-sample parity set"),
        ("Android execution", "Device benchmark plus Figures 5.1 and I.1–I.13", "The app and bundled model execute on the recorded emulator path"),
        ("Software correctness", "Analyzer output and 125 automated tests", "Specified tested behaviours pass; exhaustive correctness is not implied"),
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
