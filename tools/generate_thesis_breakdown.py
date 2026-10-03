from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "deliverables"
ASSETS = OUT / "thesis_assets"
DOCX_PATH = OUT / "ReadBuddy_AI_Detailed_Thesis_Chapter_Breakdown_Ch1-3_v1.1.docx"

NAVY = "17365D"
BLUE = "2E75B6"
TEAL = "2A9D8F"
ORANGE = "F4A261"
CORAL = "E76F51"
PALE_BLUE = "DCE6F1"
PALE_TEAL = "DFF2EF"
PALE_ORANGE = "FCE4D6"
LIGHT = "F5F7FA"
MID_GREY = "6B7280"
WHITE = "FFFFFF"
BLACK = "111827"


def font(size: int, bold: bool = False):
    candidates = [
        Path("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf"),
        Path("C:/Windows/Fonts/calibrib.ttf" if bold else "C:/Windows/Fonts/calibri.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def rounded_box(draw, xy, fill, outline, title, body="", title_size=31, body_size=23):
    draw.rounded_rectangle(xy, radius=26, fill=fill, outline=outline, width=4)
    x1, y1, x2, y2 = xy
    draw.multiline_text(((x1+x2)//2, y1+25), title, font=font(title_size, True), fill=f"#{BLACK}",
                        anchor="ma", align="center", spacing=5)
    if body:
        draw.multiline_text(((x1+x2)//2, y1+82), body, font=font(body_size), fill=f"#{BLACK}",
                            anchor="ma", align="center", spacing=6)


def arrow(draw, start, end, color=NAVY, width=6):
    draw.line([start, end], fill=f"#{color}", width=width)
    import math
    angle = math.atan2(end[1]-start[1], end[0]-start[0])
    length = 19
    spread = 0.62
    points = [end,
              (end[0]-length*math.cos(angle-spread), end[1]-length*math.sin(angle-spread)),
              (end[0]-length*math.cos(angle+spread), end[1]-length*math.sin(angle+spread))]
    draw.polygon(points, fill=f"#{color}")


def make_diagrams():
    ASSETS.mkdir(parents=True, exist_ok=True)

    # Rich picture
    img = Image.new("RGB", (1800, 1050), "white")
    d = ImageDraw.Draw(img)
    d.text((900, 42), "NenaPotha AI — Rich Picture (Grades 1–2)", font=font(45, True), fill=f"#{NAVY}", anchor="ma")
    rounded_box(d, (70, 185, 390, 440), "#FCE4D6", f"#{CORAL}", "Grade 1 Child", "traces selected\nSinhala letters")
    rounded_box(d, (70, 610, 390, 865), "#DCE6F1", f"#{BLUE}", "Grade 1/2 Reader", "reads bilingual stories\nand answers tasks")
    rounded_box(d, (555, 160, 935, 455), "#DFF2EF", f"#{TEAL}", "On-device CNN", "64×64 grayscale\n454 numeric classes\nTFLite inference")
    rounded_box(d, (555, 590, 935, 885), "#FFF2CC", "#C9A227", "Difficulty Classifier", "word count\navg. word length\navg. sentence length")
    rounded_box(d, (1100, 270, 1510, 555), "#E8EAF6", "#5C6BC0", "NenaPotha Mobile App", "feedback • practice\nrecommendations • progress\nSinhala/English interface")
    rounded_box(d, (1110, 700, 1500, 940), "#F3E5F5", "#8E44AD", "Firebase Services", "authentication\nprogress persistence\nrole-controlled access")
    rounded_box(d, (1560, 390, 1760, 725), "#F5F7FA", "#6B7280", "Adult Stakeholders", "parent\nteacher\nresearcher", 27, 22)
    arrow(d, (390, 310), (555, 310), CORAL)
    arrow(d, (390, 735), (555, 735), BLUE)
    arrow(d, (935, 310), (1100, 390), TEAL)
    arrow(d, (935, 735), (1100, 520), "C9A227")
    arrow(d, (1305, 555), (1305, 700), "8E44AD")
    arrow(d, (1510, 430), (1560, 510), NAVY)
    arrow(d, (1560, 620), (1510, 690), NAVY)
    d.text((900, 990), "Open evidence gap: map numeric class IDs to Unicode letters and validate with real child tracing data.",
           font=font(25, True), fill=f"#{CORAL}", anchor="ma")
    img.save(ASSETS / "rich_picture.png", quality=95)

    # Conceptual map
    img = Image.new("RGB", (1800, 980), "white")
    d = ImageDraw.Draw(img)
    d.text((900, 40), "Conceptual Map of the Literature", font=font(45, True), fill=f"#{NAVY}", anchor="ma")
    rounded_box(d, (90, 150, 530, 400), "#FCE4D6", f"#{CORAL}", "Foundational Literacy", "Sri Lankan Grade 1–2 context\neducational technology\nchild-centred feedback")
    rounded_box(d, (680, 150, 1120, 400), "#DFF2EF", f"#{TEAL}", "Sinhala HCR", "offline character recognition\nCNN/GCNN architectures\ndataset and field gaps")
    rounded_box(d, (1270, 150, 1710, 400), "#DCE6F1", f"#{BLUE}", "Text Readability", "surface features\nlow-resource ARA\nmultilingual/hybrid models")
    rounded_box(d, (490, 540, 1310, 790), "#E8EAF6", "#5C6BC0", "Convergent Research Gap", "No reviewed work combines a Grade 1–2 Sinhala literacy app with\non-device tracing classification and Sinhala-specific grade-level checking.", 35, 27)
    arrow(d, (310, 400), (620, 540), CORAL)
    arrow(d, (900, 400), (900, 540), TEAL)
    arrow(d, (1490, 400), (1180, 540), BLUE)
    rounded_box(d, (620, 840, 1180, 940), "#FFF2CC", "#C9A227", "NenaPotha AI Research Artifact", "", 31, 22)
    arrow(d, (900, 790), (900, 840), "C9A227")
    img.save(ASSETS / "conceptual_map.png", quality=95)

    # DSR workflow
    img = Image.new("RGB", (1900, 700), "white")
    d = ImageDraw.Draw(img)
    d.text((950, 35), "Design Science Research Methodology Applied to NenaPotha AI", font=font(43, True), fill=f"#{NAVY}", anchor="ma")
    titles = ["1. Identify\nproblem", "2. Define\nobjectives", "3. Design &\ndevelop", "4. Demonstrate", "5. Evaluate", "6. Communicate"]
    bodies = ["literacy and\ntechnical gaps", "measurable\nresearch objectives", "CNN + logistic\nmodel + integration", "Android\nprototype", "metrics, tests,\nlimitations", "thesis, viva,\nartifacts"]
    fills = ["#FCE4D6", "#FFF2CC", "#DFF2EF", "#DCE6F1", "#E8EAF6", "#F3E5F5"]
    outlines = [CORAL, "C9A227", TEAL, BLUE, "5C6BC0", "8E44AD"]
    boxes = []
    for i in range(6):
        x1 = 50 + i*305
        box = (x1, 190, x1+250, 465)
        boxes.append(box)
        rounded_box(d, box, fills[i], f"#{outlines[i]}", titles[i], bodies[i], 29, 22)
        if i:
            arrow(d, (boxes[i-1][2], 325), (box[0], 325), NAVY, 5)
    d.arc((300, 485, 1580, 670), start=5, end=175, fill=f"#{CORAL}", width=5)
    arrow(d, (315, 575), (290, 450), CORAL, 5)
    d.text((950, 620), "Iteration loop: evidence and integration defects trigger redesign and re-evaluation",
           font=font(27, True), fill=f"#{CORAL}", anchor="ma")
    img.save(ASSETS / "dsr_workflow.png", quality=95)


def shade(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_text(cell, text, bold=False, color=BLACK, size=9.5):
    cell.text = ""
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(0)
    p.paragraph_format.line_spacing = 1.05
    r = p.add_run(str(text))
    r.bold = bold
    r.font.name = "Times New Roman"
    r.font.size = Pt(size)
    r.font.color.rgb = RGBColor.from_string(color)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER


def add_table(doc, headers, rows, widths=None, font_size=9.5):
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = True
    for i, h in enumerate(headers):
        shade(table.rows[0].cells[i], NAVY)
        set_cell_text(table.rows[0].cells[i], h, True, WHITE, font_size)
    for ridx, row in enumerate(rows):
        cells = table.add_row().cells
        for i, value in enumerate(row):
            if ridx % 2 == 1:
                shade(cells[i], LIGHT)
            set_cell_text(cells[i], value, False, BLACK, font_size)
            if widths:
                cells[i].width = Cm(widths[i])
    doc.add_paragraph().paragraph_format.space_after = Pt(0)
    return table


def add_caption(doc, text):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_after = Pt(8)
    r = p.add_run(text)
    r.italic = True
    r.font.name = "Times New Roman"
    r.font.size = Pt(10)


def add_callout(doc, title, text, fill=PALE_BLUE):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = table.cell(0, 0)
    shade(cell, fill)
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(3)
    r = p.add_run(title + "\n")
    r.bold = True
    r.font.name = "Times New Roman"
    r.font.size = Pt(10.5)
    r.font.color.rgb = RGBColor.from_string(NAVY)
    r2 = p.add_run(text)
    r2.font.name = "Times New Roman"
    r2.font.size = Pt(10)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)


def add_body(doc, text, bold_lead=None):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    if bold_lead and text.startswith(bold_lead):
        r = p.add_run(bold_lead)
        r.bold = True
        text = text[len(bold_lead):]
    p.add_run(text)
    return p


def add_bullets(doc, items, level=0):
    for item in items:
        p = doc.add_paragraph(style="List Bullet" if level == 0 else "List Bullet 2")
        p.paragraph_format.left_indent = Cm(0.65 + level*0.45)
        p.paragraph_format.first_line_indent = Cm(-0.3)
        p.add_run(item)


def add_numbered(doc, items):
    for item in items:
        p = doc.add_paragraph(style="List Number")
        p.paragraph_format.left_indent = Cm(0.7)
        p.paragraph_format.first_line_indent = Cm(-0.35)
        p.add_run(item)


def add_page_number(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = paragraph.add_run()
    fld_char1 = OxmlElement("w:fldChar")
    fld_char1.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = " PAGE "
    fld_char2 = OxmlElement("w:fldChar")
    fld_char2.set(qn("w:fldCharType"), "end")
    run._r.extend([fld_char1, instr, fld_char2])


def add_toc(doc):
    p = doc.add_paragraph()
    run = p.add_run()
    fld_char = OxmlElement("w:fldChar")
    fld_char.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = 'TOC \\o "1-3" \\h \\z \\u'
    fld_sep = OxmlElement("w:fldChar")
    fld_sep.set(qn("w:fldCharType"), "separate")
    fallback = OxmlElement("w:t")
    fallback.text = "Right-click and select Update Field to generate the table of contents."
    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    run._r.extend([fld_char, instr, fld_sep, fallback, fld_end])


def setup_document():
    doc = Document()
    sec = doc.sections[0]
    sec.page_height = Cm(29.7)
    sec.page_width = Cm(21.0)
    sec.top_margin = Cm(2.3)
    sec.bottom_margin = Cm(2.2)
    sec.left_margin = Cm(2.7)
    sec.right_margin = Cm(2.2)

    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Times New Roman"
    normal.font.size = Pt(11)
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Noto Sans Sinhala")
    normal.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    normal.paragraph_format.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
    normal.paragraph_format.space_after = Pt(6)

    for style_name, size, color in [("Title", 22, NAVY), ("Heading 1", 17, NAVY), ("Heading 2", 14, BLUE), ("Heading 3", 12, TEAL)]:
        s = styles[style_name]
        s.font.name = "Times New Roman"
        s.font.size = Pt(size)
        s.font.bold = True
        s.font.color.rgb = RGBColor.from_string(color)
        s.paragraph_format.space_before = Pt(10)
        s.paragraph_format.space_after = Pt(6)
        s.paragraph_format.keep_with_next = True

    if "Callout Title" not in [s.name for s in styles]:
        s = styles.add_style("Callout Title", WD_STYLE_TYPE.PARAGRAPH)
        s.font.name = "Times New Roman"
        s.font.size = Pt(11)
        s.font.bold = True
        s.font.color.rgb = RGBColor.from_string(NAVY)

    header = sec.header.paragraphs[0]
    header.text = "ReadBuddy AI — Detailed Thesis Chapter Breakdown (Chapters 1–3)"
    header.alignment = WD_ALIGN_PARAGRAPH.CENTER
    header.runs[0].font.name = "Times New Roman"
    header.runs[0].font.size = Pt(8)
    header.runs[0].font.color.rgb = RGBColor.from_string(MID_GREY)
    footer = sec.footer.paragraphs[0]
    add_page_number(footer)

    doc.core_properties.title = "ReadBuddy AI Detailed Thesis Chapter Breakdown v1.1 — Chapters 1–3"
    doc.core_properties.author = "Mahima Induvara"
    doc.core_properties.subject = "Final Year Research Project — Grade 1 and Grade 2"
    settings = doc.settings._element
    update = OxmlElement("w:updateFields")
    update.set(qn("w:val"), "true")
    settings.append(update)
    return doc


def build_document():
    make_diagrams()
    doc = setup_document()

    # Title page
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(70)
    r = p.add_run("DETAILED AND ELABORATORY\nTHESIS CHAPTER BREAKDOWN v1.1")
    r.bold = True
    r.font.name = "Times New Roman"
    r.font.size = Pt(22)
    r.font.color.rgb = RGBColor.from_string(NAVY)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(20)
    r = p.add_run("Chapters 1, 2 and 3 Only")
    r.bold = True
    r.font.size = Pt(16)
    r.font.color.rgb = RGBColor.from_string(CORAL)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(28)
    r = p.add_run("Design and Development of an AI-Enhanced Bilingual Reading and Comprehension Assistant for Grade 1 and Grade 2 Primary School Students: On-Device Sinhala Letter Recognition and Sinhala Text-Difficulty Classification")
    r.bold = True
    r.font.name = "Times New Roman"
    r.font.size = Pt(17)
    r.font.color.rgb = RGBColor.from_string(BLUE)
    for text, size, bold in [
        ("ReadBuddy AI", 16, True),
        ("Mahima Induvara", 14, True),
        ("NSBM Green University — Faculty of Computing", 12, False),
        ("BSc (Hons) in Software Engineering — Final Year Research Project", 12, False),
        ("2026", 12, False),
    ]:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(10 if text != "ReadBuddy AI" else 30)
        rr = p.add_run(text)
        rr.font.name = "Times New Roman"
        rr.font.size = Pt(size)
        rr.bold = bold
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(40)
    rr = p.add_run("Supervisor: ____________________     Student ID: ____________________")
    rr.font.size = Pt(10)
    rr.font.color.rgb = RGBColor.from_string(MID_GREY)
    doc.add_page_break()

    doc.add_heading("Document Purpose and Scope Control", level=1)
    add_body(doc, "This document converts the university's generic MIS/CS/SE/DS chapter-breakdown guide into a research-specific, examiner-oriented blueprint for ReadBuddy AI. It covers Chapters 1–3 only. It is deliberately restricted to Grade 1 and Grade 2 because the current application and final text-difficulty model support only those grades. The structure below can be used both as a writing plan and as thesis-ready content, but university cover-page details and supervisor-approved terminology must be inserted before submission.")
    add_callout(doc, "Non-negotiable scope correction", "Replace every remaining occurrence of “Grade 1–3” in earlier drafts with “Grade 1–2” unless it appears inside a historical account of an abandoned model iteration. Grade 3 is out of scope and must not appear in the title, aim, research question, objectives, contribution claim, or evaluation claim.", PALE_ORANGE)

    doc.add_heading("Evidence-Control Sheet (Use Before Submission and Viva)", level=2)
    add_table(doc, ["Claim area", "Evidence currently available", "Permitted thesis wording / required action"], [
        ("Application scope", "Code comments, constants and learning screens state Grade 1 and Grade 2 only.", "State Grade 1–2 consistently. Treat older Grade 1–3 text as superseded."),
        ("CNN performance", "94.04% accuracy, macro precision 0.944, macro recall/F1 0.940 on a 10,896-image validation set.", "Call this validation accuracy, not test accuracy. Do not imply performance on real children."),
        ("Text classifier", "Binary Grade 1/2 logistic regression; 26 authored samples (9/17); 69.2% training accuracy.", "Describe as exploratory proof-of-concept. It is only 3.8 percentage points above the 65.4% majority-class baseline and has no held-out generalization evidence."),
        ("Tracing integration", "TFLite inference is connected to pass/fail logic with a 0.50 confidence threshold.", "State that inference is integrated, but end-to-end correctness remains blocked until numeric class IDs are mapped to Sinhala Unicode."),
        ("Model labels", "class_names.txt contains numeric labels 1–454; the UI compares the label with Sinhala characters.", "Complete and test the ID-to-Unicode mapping before claiming operational letter correctness feedback."),
        ("Tracing curriculum coverage", "The current tracing prototype exposes five letters: අ, ආ, ක, ග and ස.", "Call this a five-letter Grade 1 prototype; do not claim full curriculum coverage."),
        ("Training provenance", "The shipped TFLite model is described as a custom 64×64 CNN, while the repository notebook describes a different 128×128 MobileNetV2/TFJS pipeline.", "Archive the exact final training notebook, dataset version, random seed, model hash and run outputs before final submission."),
        ("Human evaluation", "No children, parents or teachers were recruited for this research stage.", "Do not claim usability, learning improvement or classroom effectiveness. Present field evaluation as future ethically approved work."),
    ], font_size=8.7)

    doc.add_heading("Recommended Chapter Length and Marking Balance", level=2)
    add_table(doc, ["Chapter", "Recommended share", "Primary examiner question", "Core output"], [
        ("Chapter 1 — Introduction", "20–25%", "Is the problem important, specific, researchable and correctly bounded?", "One coherent problem → question → aim → objectives chain."),
        ("Chapter 2 — Literature Review", "35–40%", "Does the student critically synthesize recent work and prove a genuine gap?", "Comparative evidence, personal reflection and a defensible gap statement."),
        ("Chapter 3 — Methodology", "35–40%", "Could another researcher reproduce the artifact and judge validity?", "DSR workflow, data/model procedures, evaluation plan, ethics and validity controls."),
    ])

    doc.add_heading("Table of Contents", level=1)
    add_toc(doc)
    doc.add_page_break()

    # Chapter 1
    doc.add_heading("Chapter 1 — Introduction", level=1)
    add_callout(doc, "Chapter outcome", "By the end of Chapter 1, an examiner should understand why Grades 1–2 matter, exactly what is missing, what ReadBuddy AI investigates, what will be measured, and what the project does not claim.")

    doc.add_heading("1.1 Chapter Overview", level=2)
    add_body(doc, "Recommended thesis-ready direction: This chapter introduces ReadBuddy AI, a bilingual Sinhala/English mobile reading and comprehension assistant scoped to Grade 1 and Grade 2 primary students. It establishes the Sri Lankan foundational-literacy context, defines the general and technical problems, presents the research question, motivation, aim and objectives, explains the proposed workflow, lists the required resources, and fixes the boundaries of the study. The chapter ends by linking the stated problem to the literature review in Chapter 2.")
    add_callout(doc, "Marking check", "Keep this section descriptive. Do not introduce model results here. One compact paragraph is sufficient.")

    doc.add_heading("1.2 Problem Background", level=2)
    add_body(doc, "Begin with the educational need, then narrow to the technical opportunity. A 2023 Ministry of Education–UNICEF initiative reported that 85% of assessed Grade 3 children were not achieving minimum literacy and numeracy proficiency and described a learning-recovery need affecting 1.6 million primary children [1]. The World Bank's 2024 Sri Lanka brief also identifies a shortage of recent internationally comparable reading-assessment evidence and reports primary expenditure per child below regional comparators [2]. These data do not prove that a mobile application will improve literacy; instead, they justify why foundational-literacy support and measurable assessment deserve attention.")
    add_body(doc, "The Grade 1–2 boundary is educationally defensible because Sri Lanka's 2025 reform structure groups Grades 1 and 2 as Key Stage 1 [3]. During this stage, learners develop letter knowledge, basic word construction and early sentence comprehension. Digital tools can offer interactivity, adaptivity and immediate feedback, although a 2024 systematic review found that effectiveness varies and that claims must be supported by proper evaluation rather than assumed from technology use alone [4].")
    add_body(doc, "The technical background contains two connected problems. First, Sinhala handwriting-recognition research has produced offline CNN-based classifiers, yet the reviewed work primarily evaluates isolated dataset images rather than a child-facing, on-device tracing workflow [5]–[7]. Second, modern automatic readability assessment increasingly uses linguistic, neural and hybrid features, but low-resource languages still depend heavily on small corpora and handcrafted features [8]–[12]. ReadBuddy AI investigates whether a compact on-device CNN and a lightweight Grade 1/2 text classifier can be integrated into one bilingual mobile artifact while remaining honest about data and validation limits.")
    add_bullets(doc, [
        "Move from national context → Grade 1–2 learning stage → technical gaps → proposed research artifact.",
        "Do not claim that 85% failed literacy alone; the UNICEF/MoE figure combines literacy and numeracy.",
        "Do not claim educational effectiveness because no child outcome study was conducted.",
    ])

    doc.add_heading("1.3 Problem Statement", level=2)
    doc.add_heading("1.3.1 General Problem", level=3)
    add_body(doc, "Suggested formulation: Grade 1 and Grade 2 Sinhala-speaking learners require repeated, age-appropriate practice in letter formation and early reading. Where digital learning tools provide content without reliable automated feedback, learners may receive limited correction during independent practice, while parents and teachers receive limited evidence about which activities require additional support. This general problem concerns the lack of measurable, adaptive feedback in a low-resource-language learning context, not the replacement of classroom teaching.")

    doc.add_heading("1.3.2 Specific Problem and Research Gap", level=3)
    add_body(doc, "Suggested formulation: Within the literature reviewed for this study, Sinhala handwritten-character recognition has been evaluated mainly as offline image classification [5]–[7], while recent low-resource readability research demonstrates that language-specific data and linguistic features remain essential [8]–[12]. No reviewed system was found that combines (i) on-device Sinhala single-letter classification within a Grade 1 tracing activity and (ii) an offline Sinhala Grade 1-versus-Grade 2 text-difficulty check within the same bilingual reading assistant. Furthermore, the project's own evidence base exposes two deployment constraints: the CNN has not been validated on children's in-app traces, and the text classifier is trained on only 26 authored samples. The research gap is therefore both an artifact gap (the combined mobile workflow) and an evidence gap (field-valid and grade-valid data for Sinhala early literacy).")
    add_callout(doc, "High-mark wording", "Use “no system was found within the reviewed search scope,” not the absolute claim “no system exists.” Define the databases, keywords and dates in Chapter 3 so this statement is auditable.", PALE_TEAL)

    doc.add_heading("1.4 Research Question", level=2)
    add_body(doc, "Primary research question: How can an AI-enhanced bilingual mobile reading assistant be designed and evaluated to provide offline Sinhala letter-tracing classification for Grade 1 learners and automated Sinhala text-difficulty classification for Grade 1 and Grade 2 reading content?")
    add_body(doc, "Supporting analytical regions (not separate unrelated questions):")
    add_bullets(doc, [
        "How accurately and consistently does the custom CNN classify the held-out Sinhala Letter 454 validation data, including per-class and confidence behaviour?",
        "To what extent can three interpretable surface features discriminate Grade 1 from Grade 2 content, given the current small and imbalanced dataset?",
        "What integration, deployment and evidence limitations must be resolved before the artifact can provide trustworthy child-facing feedback?",
    ])

    doc.add_heading("1.5 Research Motivation", level=2)
    add_body(doc, "The social motivation is to support foundational Sinhala literacy at the earliest primary stage without assuming continuous connectivity. The academic motivation is to investigate two under-resourced tasks—Sinhala child-oriented handwriting feedback and Sinhala grade-level estimation—inside a reproducible software artifact. The engineering motivation arose from observable limitations in the pre-existing application: tracing initially lacked model-grounded correctness, and story difficulty relied on authored grade tags. The research therefore goes beyond API consumption by training and integrating original models, while explicitly separating model performance from untested learning impact.")

    doc.add_heading("1.6 Research Aim", level=2)
    add_body(doc, "To design, develop and evaluate an AI-enhanced bilingual mobile reading assistant for Grade 1 and Grade 2 students by integrating an on-device Sinhala handwritten-letter CNN and an interpretable Sinhala Grade 1/2 text-difficulty classifier.")

    doc.add_heading("1.7 Research Objectives", level=2)
    add_numbered(doc, [
        "To identify the educational, application and evidence gaps affecting automated Sinhala letter-tracing feedback and grade-appropriate reading-content selection for Grade 1 and Grade 2 learners.",
        "To analyze Sinhala handwriting-recognition methods, low-resource readability approaches, on-device deployment options and evaluation strategies appropriate to the target context.",
        "To design and develop a custom CNN deployed through TensorFlow Lite and a logistic-regression Grade 1/2 text classifier, and to integrate both components into the Flutter-based ReadBuddy AI application.",
        "To evaluate the CNN using held-out validation metrics and integration tests, and to evaluate the text classifier as an exploratory model against transparent baselines while documenting threats to validity and unresolved field-evidence gaps.",
    ])
    add_table(doc, ["Objective", "Evidence expected", "Where reported later"], [
        ("RO1 — Identify", "Problem evidence, code audit, literature gap", "Chapters 1–2"),
        ("RO2 — Analyze", "Comparative literature and technology matrices", "Chapter 2"),
        ("RO3 — Design/develop", "Architecture, model files, integration code, reproducible training record", "Chapters 3–5"),
        ("RO4 — Evaluate", "Metrics, baselines, functional tests, limitations", "Methodology in Chapter 3; results in later chapters"),
    ])

    doc.add_heading("1.8 Rich Picture of the Proposed Solution", level=2)
    doc.add_picture(str(ASSETS / "rich_picture.png"), width=Inches(6.35))
    add_caption(doc, "Figure 1.1. Rich picture of the Grade 1–2 ReadBuddy AI workflow (author-generated).")
    add_body(doc, "Explain the figure from left to right. A Grade 1 learner produces a trace, which is captured, composited onto a white background, resized and classified locally by the TFLite CNN. Grade 1/2 story content is independently analyzed using the lightweight text classifier, which returns a predicted grade for content checking and recommendation. The mobile application presents activities and stores authorized progress through Firebase. Adults remain supervisory stakeholders; the system is not positioned as an autonomous teacher or diagnostic tool. The red evidence note is intentional: it makes the remaining ID-to-Unicode and field-validation work visible rather than concealing it.")

    doc.add_heading("1.9 Resource Requirements", level=2)
    doc.add_heading("1.9.1 Hardware", level=3)
    add_table(doc, ["Resource", "Purpose", "Justification"], [
        ("Windows development laptop", "Flutter/Dart development, documentation and local testing", "Primary implementation environment."),
        ("Android emulator and Android device", "Functional, layout and inference testing", "Android is the evidenced deployment target; physical-device latency should be measured before final submission."),
        ("Google Colab T4 GPU", "CNN training and evaluation", "Avoids dependence on unavailable local GPU resources and supports reproducible notebooks."),
        ("Secure cloud storage/version control", "Model, notebook and evidence preservation", "Required to establish provenance between the evaluated model and the shipped TFLite asset."),
    ])
    doc.add_heading("1.9.2 Software", level=3)
    add_table(doc, ["Software", "Role"], [
        ("Flutter/Dart", "Cross-platform application and hand-written on-device logistic-regression inference."),
        ("Python, TensorFlow/Keras", "CNN training, preprocessing and TFLite export."),
        ("scikit-learn", "Logistic regression and evaluation utilities [17]."),
        ("TensorFlow Lite / tflite_flutter", "Offline CNN execution; on-device inference can reduce network latency and data transfer [13]."),
        ("Firebase Authentication and Firestore", "Role-aware identity and progress persistence; not used for CNN inference."),
        ("Git and artifact hashes", "Version control and model-evidence traceability."),
    ])

    doc.add_heading("1.10 Project Scope", level=2)
    add_table(doc, ["In scope", "Out of scope"], [
        ("Grade 1 and Grade 2 users and curriculum content only.", "Grade 3 or higher content/model predictions."),
        ("Bilingual Sinhala/English interface; Sinhala is the modeled handwriting/readability language.", "A universal multilingual literacy model."),
        ("Single isolated-letter CNN classification, 64×64 grayscale, 454 dataset classes.", "Words, connected handwriting, full worksheets, OCR segmentation or photographed pages."),
        ("Five-letter Grade 1 tracing prototype (අ, ආ, ක, ග, ස).", "Complete Grade 1 stroke-path authoring or complete curriculum coverage."),
        ("Binary Grade 1/2 logistic regression with three surface features.", "Clinical diagnosis, dyslexia detection, semantic comprehension scoring or Grade 3 classification."),
        ("Validation-set model evaluation and Android functional integration testing.", "Claims of classroom effectiveness or learning gains without a child-participant study."),
        ("Parent/teacher access to authorized progress data.", "An unsupervised child-facing generative chatbot or replacement of teachers."),
    ], font_size=9)
    add_body(doc, "Assumptions: target users have access to an Android device; Grade 1/2 content labels are initially supplied by the application author; the public handwriting dataset is legally usable for research; and any future child-data collection will occur only after formal ethics approval and guardian consent.")

    doc.add_heading("1.11 Chapter Summary", level=2)
    add_body(doc, "This chapter establishes a nationally relevant but carefully bounded research problem: the lack of validated, adaptive Sinhala literacy support for the earliest primary stage. It defines one integrated research question, a measurable aim and four aligned objectives. It also limits the contribution to a five-letter Grade 1 tracing prototype, a 454-class dataset CNN, and an exploratory Grade 1/2 text classifier, without claiming classroom effectiveness. Chapter 2 now determines whether the literature supports the selected algorithms, deployment choices and stated research gap.")
    doc.add_page_break()

    # Chapter 2
    doc.add_heading("Chapter 2 — Literature Review", level=1)
    add_callout(doc, "Chapter outcome", "This chapter must synthesize, compare and judge literature. Each subsection should end with your own evidence-based decision about suitability for ReadBuddy AI; a sequence of paper summaries will not earn the strongest marks.")

    doc.add_heading("2.1 Chapter Overview", level=2)
    add_body(doc, "The chapter should explain that the review follows three converging strands: foundational literacy and educational technology, Sinhala handwritten-character recognition, and automatic readability assessment in low-resource languages. It then compares systems and algorithms, analyzes design/workflow options, and derives a precise research gap that motivates the methodology in Chapter 3.")

    doc.add_heading("2.2 Conceptual Map of the Literature", level=2)
    doc.add_picture(str(ASSETS / "conceptual_map.png"), width=Inches(6.35))
    add_caption(doc, "Figure 2.1. Conceptual organization of the literature (author-generated).")
    add_body(doc, "The map should be explained, not merely inserted. The education strand establishes user need and cautions against assuming that technology automatically improves learning [1]–[4]. The handwriting strand supports CNN selection but exposes dataset-to-child and offline-to-on-device gaps [5]–[7]. The readability strand shows that simple features remain defensible for low-resource settings, while recent work demonstrates the value of larger, human-annotated, multilingual and hybrid models [8]–[12]. The contribution lies at their intersection.")

    doc.add_heading("2.3 Domain Overview", level=2)
    doc.add_heading("2.3.1 Foundational Literacy and the Grade 1–2 Context", level=3)
    add_body(doc, "Frame Grade 1–2 as Key Stage 1 in the current Sri Lankan reform structure [3], not merely as a convenient software subset. Use the 2023 learning-recovery statistic [1] to establish urgency, while noting that it concerns Grade 3 literacy and numeracy together and therefore provides context rather than direct evidence about the app's target cohort. The World Bank brief [2] further shows why current learning evidence and careful local evaluation matter.")
    doc.add_heading("2.3.2 Educational Technology for Early Literacy", level=3)
    add_body(doc, "Bautista, Ghesquière and Torbeyns reviewed 67 studies and found some positive evidence for educational technology in early literacy, but effect sizes and feature-specific conclusions were not uniformly available [4]. Your reflection should be: interactivity and feedback justify designing ReadBuddy AI, but educational benefit must remain a future empirical question until a controlled child-participant evaluation is conducted.")
    doc.add_heading("2.3.3 Sinhala as a Low-Resource Computational Context", level=3)
    add_body(doc, "Avoid treating “low-resource” as a vague synonym for “non-English.” In this thesis it specifically means limited task-specific, child-annotated Sinhala handwriting data; no verified large Grade 1/2 readability corpus; incomplete label mapping; and limited pretrained tools for Sinhala educational text. Define the shortage in terms of the resources needed by this research.")

    doc.add_heading("2.4 Existing Systems, Frameworks and Designs", level=2)
    doc.add_heading("2.4.1 Sinhala Handwritten-Character Recognition", level=3)
    add_table(doc, ["Study", "Data/task", "Reported result", "Critical relevance to ReadBuddy AI"], [
        ("Mariyathas et al. (2020) [5]", "CNN; approximately 110,000 images; up to 434 Sinhala classes", "82.33% overall accuracy for 434 characters", "Strong Sinhala CNN precedent, but offline dataset recognition rather than child tracing or on-device feedback."),
        ("Wasalthilake and Thangathurai (2022) [6]", "55 characters; 33 samples per character; pixel-length vs CNN", "CNN accuracy 85.71%", "Shows CNN advantage over a simple handcrafted method; small dataset and no educational deployment."),
        ("Karunarathne et al. (2024) [7]", "6,000 images; 60 characters; CNN vs Gabor-initialized CNN", "CNN test accuracy 90.14%; GCNN 80.00% with faster early convergence", "Useful architecture/convergence comparison, but results are not directly comparable across datasets."),
        ("ReadBuddy AI", "454 classes; custom CNN; on-device TFLite; five-letter tracing UI", "94.04% validation accuracy; macro-F1 0.940", "Adds mobile integration and broader class count, but lacks Unicode mapping and real-child field validation."),
    ], font_size=8.3)
    add_body(doc, "Critical synthesis: the three published studies justify CNN-based feature learning for Sinhala script, but their accuracy figures cannot be ranked directly because class counts, sample sources, preprocessing, partitions and evaluation protocols differ. ReadBuddy AI's novelty claim should therefore emphasize deployment context and combined workflow—not “the best Sinhala model.”")

    doc.add_heading("2.4.2 Automatic Readability Assessment", level=3)
    add_table(doc, ["Study", "Approach/data", "Finding", "Decision for this research"], [
        ("Pilán et al. (2016) [14]", "Supervised linguistic features for Swedish learning material", "81.3% document-level and 63.4% sentence-level accuracy", "Supports learned linguistic features and shows short-text difficulty is harder."),
        ("Imperial and Kochmar (2023) [8], [9]", "Low-resource Philippine languages; surface, syllable and n-gram/cross-lingual features", "Language relatedness and tailored features improved low-resource ARA", "Supports handcrafted features where language tools/data are limited."),
        ("Naous et al. (2024) [10]", "9,757 human-annotated sentences across five languages and many domains", "Exposes cross-domain/cross-lingual limitations and benchmarks multilingual models", "Shows how much stronger evidence requires human annotation and diverse sources."),
        ("Liu et al. (2025) [11]", "Neural, hybrid and LLM sentence-level models; large English/Chinese corpora", "Hybrid models outperformed traditional, neural and LLM-only approaches", "Defines a future benchmark; current 26-sample model cannot support this complexity."),
        ("Kazakov et al. (2025) [12]", "First Bulgarian readability-index attempt; child-targeted texts and surface features", "Polynomial models captured non-linearity; interpretability trade-off", "Closest recent analogy for a language-specific first-stage index."),
        ("ReadBuddy AI", "26 Sinhala samples; 3 surface features; binary logistic regression", "69.2% training accuracy; majority baseline 65.4%", "A reproducible proof-of-concept only; more human-labelled content is the immediate research need."),
    ], font_size=8.1)
    add_body(doc, "Personal reflection: the current ReadBuddy classifier chooses interpretability and zero-runtime overhead over representational depth. That choice is defensible for a prototype, but the literature shows that word/sentence length alone cannot capture Sinhala morphology, vocabulary familiarity, pillam density, cohesion or reader-specific difficulty. The model should be presented as a pipeline validation, not a solved readability measure.")

    doc.add_heading("2.4.3 Existing Digital Learning Platforms", level=3)
    add_body(doc, "Briefly compare curriculum repositories such as Sri Lanka's e-Thaksalawa and commercial English reading assistants at the feature level only: content delivery, personalization, handwriting feedback, readability checking, offline inference, bilingual support and stakeholder reporting. Do not imply proprietary internals or performance without public evidence. This subsection should occupy less space than the peer-reviewed technical analysis.")

    doc.add_heading("2.5 Technological Analysis", level=2)
    doc.add_heading("2.5.1 Algorithmic Analysis", level=3)
    add_table(doc, ["Decision", "Alternatives considered", "Selected option and justification", "Trade-off"], [
        ("Letter recognition", "Handcrafted contours; transfer learning; custom CNN; Gabor-CNN", "Three-block custom CNN: enough data/classes to learn script-specific features, compact export, aligned with Sinhala CNN precedent [5]–[7].", "Requires exact training provenance and does not automatically generalize to child traces."),
        ("Difficulty estimation", "Fixed English formulas; tree models; transformers/LLMs; logistic regression", "Logistic regression over three transparent surface features because the Sinhala dataset is extremely small and on-device implementation is simple.", "Underfits linguistic complexity; needs stronger baselines and labelled data."),
        ("Confidence evaluation", "Accuracy only vs calibration analysis", "Reliability diagram and Expected Calibration Error because softmax confidence is shown/used in decisions [15].", "Calibration on reference data does not prove calibration on child traces."),
        ("Explainability", "No explanation vs Grad-CAM", "Grad-CAM is a suitable planned visual explanation for CNN focus [16].", "Do not report it as completed until the exact shipped model is analyzed."),
    ], font_size=8.5)

    doc.add_heading("2.5.2 Design Analysis", level=3)
    add_body(doc, "On-device inference is preferred to cloud inference for the CNN because it avoids a network round trip, supports offline practice and reduces transfer of children's trace images. On-device neural inference is commonly motivated by lower latency and privacy benefits, although compute, thermal and device-compatibility constraints remain [13]. The selected design keeps Firebase for authenticated persistence and stakeholder access rather than model execution.")
    add_body(doc, "The preprocessing design is methodologically significant: the captured drawing must be composited onto a white background, resized to 64×64, converted to grayscale and normalized to match training conditions. A transparent canvas decoding as black would create a distribution shift. Treat this as a reproducibility decision, not a minor UI detail.")

    doc.add_heading("2.5.3 Workflow Analysis", level=3)
    add_table(doc, ["Workflow", "Input → processing → output", "Evidence risk"], [
        ("Letter tracing", "Canvas strokes → white composite → PNG → 64×64 grayscale → TFLite CNN → top label/confidence → pass/fail", "Numeric label cannot match Unicode expected letter until mapping is completed."),
        ("Text difficulty", "Sinhala text → token/sentence split → 3 features → linear score → sigmoid → Grade 1/2", "Short-text tokenization and tiny authored dataset limit construct validity."),
        ("Progress", "Activity outcome → local/service model → Firestore-authorized records → parent/teacher view", "No learning-impact inference should be made from activity completion alone."),
    ])

    doc.add_heading("2.6 Critical Reflection and Final Research Gap", level=2)
    add_body(doc, "The final literature-derived gap should have four layers. First, an educational-context gap: Sri Lankan early-grade foundational learning warrants additional support, but technology effectiveness must be evaluated rather than assumed [1]–[4]. Second, a deployment gap: prior Sinhala HCR work demonstrates CNN feasibility without establishing a child-facing, on-device tracing loop [5]–[7]. Third, a language-resource gap: recent ARA research depends on annotated corpora, language-aware features and/or multilingual models that are not presently available for Grade 1/2 Sinhala [8]–[12]. Fourth, an integration-evidence gap: no reviewed work combines both components within one bilingual artifact and evaluates their practical integration constraints.")
    add_body(doc, "Resulting contribution statement: ReadBuddy AI contributes a bounded design-science artifact that integrates two original offline models and exposes what is technically feasible with available Sinhala resources. Its strongest current evidence is the CNN's dataset validation; its weakest evidence is end-to-end child tracing and text-difficulty generalization. The thesis earns credibility by making that asymmetry explicit.")

    doc.add_heading("2.7 Chapter Summary", level=2)
    add_body(doc, "This chapter shows that CNNs are established for Sinhala handwritten recognition, that recent low-resource readability studies still benefit from language-specific features and corpora, and that educational technology must be evaluated cautiously. It justifies a compact CNN, a transparent logistic-regression proof-of-concept and an on-device design, while identifying missing Unicode mapping, training provenance, larger readability data and child field validation as unresolved evidence gaps. Chapter 3 translates these findings into a reproducible design-science methodology.")
    doc.add_page_break()

    # Chapter 3
    doc.add_heading("Chapter 3 — Methodology", level=1)
    add_callout(doc, "Chapter outcome", "The methodology must distinguish what was actually executed from what is proposed before final evaluation. Reproducibility, baselines, ethics and threats to validity matter as much as model architecture.")

    doc.add_heading("3.1 Chapter Overview", level=2)
    add_body(doc, "This chapter defines the research paradigm, approach and design-science strategy; explains literature and dataset collection; maps the execution workflow to the objectives; specifies both model-development pipelines; defines evaluation and integration criteria; and addresses project management, ethics, reliability and validity. The methodology is artifact-centred and quantitative, with no human-participant effectiveness study in the present scope.")

    doc.add_heading("3.2 Research Paradigm", level=2)
    add_body(doc, "Adopt pragmatism. The research asks whether useful technical artifacts can be constructed and evaluated under real resource constraints. Quantitative model metrics provide an empirical view of performance, while iterative design decisions—such as reducing text classification from three grades to two—respond to observed evidence. Pragmatism is preferable to a purely positivist framing because the work includes design choices and software integration, but it does not justify subjective claims of usefulness without data.")

    doc.add_heading("3.3 Research Approach", level=2)
    add_body(doc, "Describe the approach as predominantly deductive with inductive iteration. Deductively, CNN and linguistic-feature hypotheses are derived from Chapter 2 and evaluated using measurable metrics. Inductively, failures discovered during implementation—class imbalance, background mismatch, package incompatibility and label mapping—lead to revised scope and design. This combination is consistent with the pragmatist stance and should be explained using concrete project examples.")

    doc.add_heading("3.4 Research Strategy — Design Science Research", level=2)
    add_body(doc, "Use the six-stage Design Science Research Methodology (DSRM) of Peffers et al. [18]: problem identification and motivation; definition of solution objectives; design and development; demonstration; evaluation; and communication. DSR is appropriate because the central research output is an evaluated software/ML artifact rather than a survey of attitudes.")
    doc.add_picture(str(ASSETS / "dsr_workflow.png"), width=Inches(6.5))
    add_caption(doc, "Figure 3.1. DSRM execution workflow for ReadBuddy AI, adapted from [18].")

    doc.add_heading("3.5 Fact Collection Mechanisms", level=2)
    doc.add_heading("3.5.1 Secondary Literature", level=3)
    add_body(doc, "Document the search protocol so the gap claim is repeatable. Recommended sources: IEEE Xplore, ACM Digital Library, ACL Anthology, SpringerLink, ScienceDirect, Google Scholar for discovery, and official Sri Lankan/UN sources for policy context. Recommended date window: 2020–2026 for current technical/educational work, with older sources retained only for foundational algorithms or methodology.")
    add_table(doc, ["Element", "Recommended record"], [
        ("Search strings", '“Sinhala handwritten character recognition CNN”; “Sinhala child handwriting recognition”; “automatic readability assessment low-resource”; “Grade-level text classification”; “early literacy educational technology”; “on-device CNN mobile”.'),
        ("Inclusion", "Peer-reviewed primary studies or systematic reviews; official statistics/policy; explicit method/data/results; English-accessible full metadata; direct relevance to one research strand."),
        ("Exclusion", "Unverifiable snippets, duplicate versions, purely commercial claims, papers without method/result relevance, and sources whose bibliographic data cannot be confirmed."),
        ("Extraction fields", "Authors, year, venue, DOI/URL, dataset, sample size, classes, features/model, metrics, deployment context, limitations and relevance decision."),
    ], font_size=8.8)

    doc.add_heading("3.5.2 Component 1 Dataset", level=3)
    add_body(doc, "The CNN uses Sathira L. Amal's Sinhala Letter and Modifications dataset (“Sinhala Letter 454”) [19]. The locally reported run contains 454 classes with 87,141 training and 10,896 validation images. Before final submission, record the exact downloaded dataset version, directory counts, test-set count, license, checksum and any augmentation because public descriptions of the dataset differ in sample count. The thesis must describe the data actually used, not a generic web summary.")
    add_bullets(doc, [
        "Unit of analysis: one isolated handwritten Sinhala letter/modification image.",
        "Target: numeric class ID among 454 classes.",
        "Known domain gap: reference dataset images are not equivalent to young children's finger traces inside the app.",
        "Leakage control: keep writer/source groups separated where metadata permits; otherwise acknowledge possible writer overlap as a threat.",
    ])

    doc.add_heading("3.5.3 Component 2 Dataset", level=3)
    add_body(doc, "The text classifier uses 26 Sinhala samples taken from the application's authored content: 9 labelled Grade 1 and 17 labelled Grade 2. The labels come from existing content placement, not independent expert annotation. Preserve each text, source file, grade label and feature vector in a versioned CSV. Because the sample is both small and imbalanced, it supports exploratory classification only.")

    doc.add_heading("3.6 Research Methodology Execution Workflow", level=2)
    add_table(doc, ["DSRM stage", "ReadBuddy AI activity", "Output/evidence"], [
        ("1. Problem identification", "Inspect existing app and literature; identify tracing-feedback and content-level gaps.", "Problem statement, stakeholder needs, literature matrix."),
        ("2. Define objectives", "Translate gaps into identify–analyze–develop–evaluate objectives.", "RQ/aim/objective traceability table."),
        ("3. Design/develop", "Train CNN, build logistic classifier, export/port models, integrate with Flutter.", "Versioned notebooks, model hashes, source code and architecture diagrams."),
        ("4. Demonstrate", "Run the app on Android; execute representative tracing and Grade 1/2 story flows.", "Screenshots/video, debug logs and reproducible scenarios."),
        ("5. Evaluate", "Model metrics, calibration, baselines, latency and functional tests; document limitations.", "Metric tables, confusion matrix, reliability plot, test evidence."),
        ("6. Communicate", "Write thesis, prepare viva and archive research artifacts.", "Chapters, appendices, dataset/model cards and evidence index."),
    ], font_size=8.5)

    doc.add_heading("3.7 Component 1 Methodology — On-Device Sinhala Letter Recognition", level=2)
    doc.add_heading("3.7.1 Preprocessing", level=3)
    add_numbered(doc, [
        "Capture the user's trace from the Flutter RepaintBoundary.",
        "Composite the transparent drawing over a white background to match training-image polarity.",
        "Encode/decode the captured image and resize it to 64×64 pixels.",
        "Convert to grayscale and normalize pixel intensity to [0,1].",
        "Reshape to [1,64,64,1] and pass it to the TFLite interpreter.",
        "Select the highest softmax score, retain top-k scores for analysis, map the class ID to the correct Unicode letter, and compare it with the expected letter.",
    ])

    doc.add_heading("3.7.2 Architecture and Training", level=3)
    add_body(doc, "Specify the exact model layer-by-layer in the final thesis: three Conv2D–MaxPooling blocks, followed by flattening/dense layers, dropout and a 454-way softmax output. Record filter counts, kernel sizes, dense units, dropout rate, parameter count, initialization and random seed from the final executable notebook. Current reported training used Adam, sparse categorical cross-entropy, batch size 32 and 15 epochs. Two independent runs produced approximately 94.10% and 94.04% validation accuracy, which is useful repeatability evidence but does not substitute for a held-out field test.")
    add_callout(doc, "Critical reproducibility action", "The repository notebook currently describes MobileNetV2/TFJS, while the shipped app uses a custom 64×64 TFLite model. The final thesis must cite and archive the exact notebook that produced assets/models/sinhala_letter_model.tflite. Include the SHA-256 hash of the model and label file.", PALE_ORANGE)

    doc.add_heading("3.7.3 Evaluation Plan", level=3)
    add_table(doc, ["Metric/test", "Purpose", "Reporting rule"], [
        ("Top-1 accuracy", "Overall correct classification rate", "Report 94.04% as validation accuracy on 10,896 images."),
        ("Macro precision/recall/F1", "Equal weight to all 454 classes", "Report 0.944/0.940/0.940 and include class-support distribution."),
        ("Confusion matrix", "Identify systematic letter/modification confusions", "Normalize as well as show counts; discuss strongest confusion pairs."),
        ("Top-2/top-3 accuracy", "Determine whether correct class remains among alternatives", "Report 96.35% and 97.12% with exact implementation."),
        ("ECE/reliability diagram", "Check whether confidence matches empirical correctness [15]", "Report ECE 0.084 and binning procedure."),
        ("Repeat runs", "Assess training stability", "Use fixed and varied seeds; report mean and standard deviation when possible."),
        ("Android latency/model size", "Establish mobile feasibility", "Measure on a physical target device; report median, p95 and model size."),
        ("End-to-end functional test", "Verify capture → mapping → verdict", "Cannot pass until numeric ID-to-Unicode mapping is completed."),
    ], font_size=8.3)

    doc.add_heading("3.7.4 Integration Decision Rule", level=3)
    add_body(doc, "A trace passes only when the mapped predicted Unicode letter equals the expected letter and confidence exceeds 0.50. The threshold is an engineering decision and should be tuned on representative child-trace validation data rather than treated as universally valid. If the model is unavailable, the app currently uses a geometric guide-coverage fallback; this must be logged visibly because it is not equivalent to CNN evidence.")

    doc.add_heading("3.8 Component 2 Methodology — Grade 1/2 Text Difficulty", level=2)
    doc.add_heading("3.8.1 Feature Engineering", level=3)
    add_table(doc, ["Feature", "Definition", "Rationale and limitation"], [
        ("Word count", "Number of non-empty whitespace-separated tokens", "Approximates passage length; sensitive to Sinhala tokenization conventions."),
        ("Average word length", "Mean Unicode character count per token", "Simple lexical proxy; code-point length is not equivalent to syllabic/morphological complexity."),
        ("Average sentence length", "Mean words per segment split on . ! ?", "Classic readability proxy; punctuation may be sparse/inconsistent in children's Sinhala content."),
    ])
    add_body(doc, "The implemented binary model computes z = −4.6827 + 0.4839x₁ + 0.5542x₂ + 0.4839x₃ and p(Grade 2) = 1/(1 + e^(−z)). A probability of at least 0.50 returns Grade 2; otherwise Grade 1. Include full-precision coefficients in an appendix and the rounded equation in Chapter 3.")

    doc.add_heading("3.8.2 Training and Evaluation", level=3)
    add_body(doc, "The current 69.2% figure is training accuracy, not a held-out estimate. The majority-class baseline is 17/26 = 65.4%, so the observed improvement is only 3.8 percentage points on the same training data. A strong methodology must therefore avoid comparing 69.2% directly with published test accuracies. The present model demonstrates integration feasibility; it does not establish robust grade prediction.")
    add_table(doc, ["Minimum final evaluation improvement", "Reason"], [
        ("Expand and balance the corpus with independently reviewed Grade 1/2 texts.", "Reduces variance, author-source bias and class imbalance."),
        ("Group samples by story/source before splitting.", "Prevents near-duplicate sentences from leaking across train/test partitions."),
        ("Use repeated stratified cross-validation or nested CV when data becomes adequate.", "Provides uncertainty estimates while preserving scarce data."),
        ("Report majority, rule-based and logistic baselines; macro-F1, balanced accuracy and confusion matrix.", "Accuracy alone hides Grade 1 minority-class failure."),
        ("Perform ablation and add Sinhala-relevant features: syllable/pillam density, lexical frequency, compound-letter density and vocabulary familiarity.", "Tests whether the three selected features actually contribute and improves construct validity."),
        ("Obtain teacher/expert grade annotations and inter-rater agreement.", "Authored grade tags are not independent ground truth."),
    ], font_size=8.7)

    doc.add_heading("3.9 Evaluation and Objective Traceability", level=2)
    add_table(doc, ["Objective", "Measure", "Current status", "Completion criterion"], [
        ("RO1", "Literature/code gap audit", "Substantially evidenced", "Search log and comparison matrix archived."),
        ("RO2", "Algorithm/design comparison", "Evidenced in Chapter 2", "Each technology decision linked to literature and trade-off."),
        ("RO3", "Model and app artifacts", "Implemented with evidence gaps", "Exact model provenance + Unicode mapping + reproducible Android flow."),
        ("RO4 — CNN", "Accuracy, macro metrics, top-k, ECE, functional tests", "Dataset validation available", "Report exact split and add physical-device/end-to-end tests."),
        ("RO4 — text", "Baseline, macro-F1, balanced accuracy, cross-validation", "Training accuracy only", "Expanded independently labelled corpus and honest uncertainty report."),
    ], font_size=8.5)

    doc.add_heading("3.10 Project Management Methodology", level=2)
    add_body(doc, "Use an Agile/Kanban approach adapted to a single researcher. This is more accurate than claiming full Scrum without a team, Scrum Master or formal ceremonies. Maintain a prioritized backlog, weekly supervisor review, definition of done, risk register and evidence checklist. Model experiments should be time-boxed and each completed card must produce a reproducible artifact or test result.")
    add_table(doc, ["Workstream", "Definition of done"], [
        ("Literature", "Metadata verified from original publisher; relevance and limitation recorded."),
        ("Model", "Notebook executes; data/version/seed stored; metrics exported; model hash recorded."),
        ("Integration", "Automated/manual test passes on Android; screenshot/log stored; fallback path identified."),
        ("Documentation", "Claim linked to evidence; citation present; limitation stated; supervisor feedback addressed."),
    ])

    doc.add_heading("3.11 Project Timeline", level=2)
    add_table(doc, ["Weeks", "Activity", "Milestone"], [
        ("1–2", "Scope correction, source verification and literature matrix", "Approved RQ/aim/objectives; verified bibliography."),
        ("3–4", "Archive final CNN training pipeline and dataset manifest", "Reproducible TFLite artifact with hashes."),
        ("5", "Complete 454-ID Unicode mapping for the five UI letters first; add mapping tests", "End-to-end tracing verdict works for prototype letters."),
        ("6–7", "Expand/relabel Grade 1/2 text corpus with expert review", "Balanced, versioned corpus and annotation record."),
        ("8", "Run baselines/cross-validation and error analysis", "Defensible text-classifier evaluation."),
        ("9", "Physical-device latency, functional and privacy tests", "Integration evidence pack."),
        ("10", "Finalize Chapters 1–3 and diagrams", "Supervisor-ready draft."),
        ("11–12", "Corrections, reference audit, plagiarism/format checks and viva evidence index", "Submission-ready document and artifact archive."),
    ], font_size=8.7)

    doc.add_heading("3.12 Ethical Considerations", level=2)
    add_bullets(doc, [
        "No children were recruited and no learning-effectiveness claim is made in the current study.",
        "Any future study involving minors requires institutional approval, school permission, guardian consent and age-appropriate child assent before collection.",
        "Collect the minimum data needed. Avoid retaining raw handwriting images by default; if retention is necessary, specify purpose, encryption, retention period and deletion process.",
        "Separate student identity from research records using pseudonymous IDs and role-based Firestore rules.",
        "Do not frame classifier outputs as clinical or developmental diagnoses. A wrong prediction must not shame, penalize or label a child.",
        "Provide a visible fallback/manual review route and disclose when geometric rather than model-based scoring is used.",
        "The parent/teacher AI assistant is supporting engineering context, not one of the two evaluated research models and not an autonomous child tutor.",
    ])

    doc.add_heading("3.13 Reliability, Validity and Threats", level=2)
    add_table(doc, ["Validity area", "Threat", "Mitigation / honest limitation"], [
        ("Construct validity", "Dataset class accuracy may not represent correct pedagogical stroke formation; text length may not represent reading difficulty.", "Separate recognition from handwriting quality; add child/teacher annotations and Sinhala-specific features in future work."),
        ("Internal validity", "Data leakage, inconsistent preprocessing or tuning on validation data.", "Freeze splits, log seeds, hash artifacts, match preprocessing and reserve a true final test set."),
        ("External validity", "Reference handwriting differs from Grade 1 finger traces; authored texts come from one application.", "Do not generalize to children/classrooms; conduct multi-school field evaluation later."),
        ("Conclusion validity", "Small n=26 text corpus and class imbalance make accuracy unstable.", "Use baselines, uncertainty intervals and cross-validation after expansion; avoid significance claims now."),
        ("Reliability", "Final shipped model cannot currently be regenerated from repository notebook.", "Archive executable final notebook, environment versions, data manifest and model hashes."),
        ("Integration validity", "Numeric class labels prevent Unicode comparison; fallback may mask model failure.", "Implement mapping tests and log inference source/model version on every attempt."),
    ], font_size=8.2)

    doc.add_heading("3.14 Chapter Summary", level=2)
    add_body(doc, "This chapter adopts pragmatism, a deductive-with-inductive-iteration approach and DSRM to guide the construction and evaluation of ReadBuddy AI. It specifies literature and data collection, the CNN and logistic-regression pipelines, evaluation measures, integration rules, Agile/Kanban management, ethics and validity controls. Most importantly, it distinguishes achieved dataset validation from unresolved end-to-end and field evidence. Later results chapters should report only tests actually executed under this methodology.")

    doc.add_page_break()
    doc.add_heading("IEEE-Style Reference List", level=1)
    refs = [
        '[1] UNICEF Sri Lanka, “MOE and UNICEF spearhead national initiative to recover lost learning for 1.6 million primary school children across Sri Lanka,” Aug. 16, 2023. [Online]. Available: https://www.unicef.org/srilanka/press-releases/moe-and-unicef-spearhead-national-initiative-recover-lost-learning-16-million. [Accessed: Aug. 11, 2026].',
        '[2] World Bank, “Sri Lanka Learning Poverty Brief,” version 2, Apr. 2024. [Online]. Available: https://documents1.worldbank.org/curated/en/099090524113181787/pdf/P1792091cc4ce70d01bda7185ee313a94c7.pdf. [Accessed: Aug. 11, 2026].',
        '[3] Ministry of Education, Higher Education and Vocational Education, Sri Lanka, “Transform Education: Transform Sri Lanka,” 2025. [Online]. Available: https://moe.gov.lk/wp-content/uploads/2025/07/Education-Reforms-Sri-Lanka-PPT.pdf. [Accessed: Aug. 11, 2026].',
        '[4] G. F. Bautista, P. Ghesquière, and J. Torbeyns, “Stimulating preschoolers’ early literacy development using educational technology: A systematic literature review,” Int. J. Child-Comput. Interact., vol. 39, Art. no. 100620, Mar. 2024, doi: 10.1016/j.ijcci.2023.100620.',
        '[5] J. Mariyathas, V. Shanmuganathan, and B. Kuhaneswaran, “Sinhala handwritten character recognition using convolutional neural network,” in Proc. 5th Int. Conf. Inf. Technol. Res. (ICITR), 2020, pp. 1–6, doi: 10.1109/ICITR51448.2020.9310914.',
        '[6] W. V. S. K. Wasalthilake and T. Thangathurai, “Improved handwritten character recognition for Sinhala language based on convolutional neural networks,” in Proc. IEEE 7th Int. Conf. Convergence Technol. (I2CT), 2022, doi: 10.1109/I2CT54291.2022.9824233.',
        '[7] M. L. Karunarathne, C. P. Wijesiriwardana, K. M. I. Nishantha, and W. G. C. W. Kumara, “Efficiency and accuracy in Sinhala handwritten character recognition: A Gabor-initialized CNN perspective,” Sri Lankan J. Technol., vol. 5, no. 1, pp. 13–24, Jun. 2024. [Online]. Available: https://seu.ac.lk/sljot/publication/v5n1/003.pdf.',
        '[8] J. M. Imperial and E. Kochmar, “BasahaCorpus: An expanded linguistic resource for readability assessment in Central Philippine languages,” in Proc. 2023 Conf. Empirical Methods Natural Language Process. (EMNLP), Singapore, 2023, pp. 6302–6309, doi: 10.18653/v1/2023.emnlp-main.388.',
        '[9] J. M. Imperial and E. Kochmar, “Automatic readability assessment for closely related languages,” in Findings Assoc. Comput. Linguistics: ACL 2023, Toronto, Canada, 2023, pp. 5371–5386, doi: 10.18653/v1/2023.findings-acl.331.',
        '[10] T. Naous, M. J. Ryan, A. Lavrouk, M. Chandra, and W. Xu, “ReadMe++: Benchmarking multilingual language models for multi-domain readability assessment,” in Proc. 2024 Conf. Empirical Methods Natural Language Process. (EMNLP), Miami, FL, USA, 2024, pp. 12230–12266, doi: 10.18653/v1/2024.emnlp-main.682.',
        '[11] F. Liu, T. Jin, and J. S. Y. Lee, “Automatic readability assessment for sentences: Neural, hybrid and large language models,” Lang. Resources Eval., vol. 59, pp. 2265–2296, 2025, doi: 10.1007/s10579-024-09800-5.',
        '[12] D. Kazakov, S. Minkov, R. Margova, I. Temnikova, and I. Emanuilov, “Towards creating a Bulgarian readability index,” in Proc. 1st Workshop Advancing NLP for Low-Resource Languages, Varna, Bulgaria, 2025, pp. 192–200, doi: 10.26615/978-954-452-100-4-018.',
        '[13] J. Lee et al., “On-device neural net inference with mobile GPUs,” in Workshop Efficient Deep Learning for Computer Vision, CVPR, 2019. [Online]. Available: https://arxiv.org/abs/1907.01989.',
        '[14] I. Pilán, S. Vajjala, and E. Volodina, “A readable read: Automatic assessment of language learning materials based on linguistic complexity,” Int. J. Comput. Linguistics Appl., vol. 7, no. 1, pp. 143–159, 2016.',
        '[15] C. Guo, G. Pleiss, Y. Sun, and K. Q. Weinberger, “On calibration of modern neural networks,” in Proc. 34th Int. Conf. Mach. Learn., vol. 70, 2017, pp. 1321–1330.',
        '[16] R. R. Selvaraju, M. Cogswell, A. Das, R. Vedantam, D. Parikh, and D. Batra, “Grad-CAM: Visual explanations from deep networks via gradient-based localization,” in Proc. IEEE Int. Conf. Comput. Vis. (ICCV), 2017, pp. 618–626.',
        '[17] F. Pedregosa et al., “Scikit-learn: Machine learning in Python,” J. Mach. Learn. Res., vol. 12, pp. 2825–2830, 2011.',
        '[18] K. Peffers, T. Tuunanen, M. A. Rothenberger, and S. Chatterjee, “A design science research methodology for information systems research,” J. Manage. Inf. Syst., vol. 24, no. 3, pp. 45–77, 2007, doi: 10.2753/MIS0742-1222240302.',
        '[19] S. L. Amal, “Sinhala Letter and Modifications,” Kaggle dataset, 2020. [Online]. Available: https://www.kaggle.com/datasets/sathiralamal/sinhala-letter-454. [Accessed: Aug. 11, 2026].',
    ]
    for ref in refs:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Cm(0.75)
        p.paragraph_format.first_line_indent = Cm(-0.75)
        p.paragraph_format.line_spacing = 1.0
        p.paragraph_format.space_after = Pt(5)
        p.add_run(ref)

    doc.add_heading("Final Examiner-Readiness Checklist", level=1)
    add_bullets(doc, [
        "Title, problem, RQ, aim, objectives and scope all say Grade 1–2 only.",
        "Every numerical claim names its dataset split and does not convert validation/training accuracy into test accuracy.",
        "The 69.2% text result is compared with the 65.4% majority baseline and not oversold.",
        "The exact TFLite-generating notebook, dependency versions and SHA-256 hashes are archived.",
        "Numeric label IDs are mapped to Unicode and end-to-end tests pass for all five prototype letters.",
        "The literature matrix contains recent 2023–2025 readability studies and verified Sinhala CNN sources.",
        "The literature review contains comparison and personal reflection, not only descriptions.",
        "No claim of learning improvement, usability or child-field accuracy appears without participant evidence.",
        "Figures and tables are numbered, captioned, discussed in text and cited where adapted.",
        "All IEEE references are cited in first-appearance order and checked against original publisher pages.",
        "Supervisor name, student ID, university template, declaration and final formatting rules are inserted.",
    ])
    add_callout(doc, "Best viva position", "The strongest defense is not pretending every component is equally mature. State that the CNN has strong dataset-level validation, the mobile integration is a functioning prototype with a mapping task to close, and the text classifier establishes a reproducible low-resource pipeline whose next scientific step is an expanded expert-labelled corpus.", PALE_TEAL)

    OUT.mkdir(parents=True, exist_ok=True)
    doc.save(DOCX_PATH)
    return DOCX_PATH


if __name__ == "__main__":
    path = build_document()
    print(path)

