from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Inches, Pt, RGBColor

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
    WHITE,
    add_body,
    add_bullets,
    add_callout,
    add_caption,
    add_numbered,
    add_page_number,
    add_table,
    add_toc,
    arrow,
    font,
    make_diagrams,
    rounded_box,
)


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "deliverables"
DOCX = OUT / "Interim_Submission_Updated_Chapters_1-3_28277.docx"
PDF = OUT / "Interim_Submission_Updated_Chapters_1-3_28277_preview.pdf"
EXTRACTED = ROOT / "work" / "submission2" / "media" / "research"


def make_additional_diagrams() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)

    # Preliminary teacher requirement-elicitation chart (n=2).
    img = Image.new("RGB", (1700, 900), "white")
    d = ImageDraw.Draw(img)
    d.text((850, 48), "Preliminary Teacher Requirement-Elicitation Findings (n = 2)",
           font=font(41, True), fill=f"#{NAVY}", anchor="ma")
    labels = [
        "Letter recognition difficulty",
        "Word-reading difficulty",
        "Mirror writing",
        "Incorrect letter formation",
        "Complex-letter pronunciation",
    ]
    values = [2, 1, 2, 2, 2]
    colors = [CORAL, ORANGE, TEAL, BLUE, "8E44AD"]
    y = 165
    for label, value, color in zip(labels, values, colors):
        d.text((70, y + 30), label, font=font(27, True), fill=f"#{BLACK}", anchor="lm")
        d.rounded_rectangle((610, y, 1510, y + 62), radius=20, fill="#E5E7EB")
        width = 900 * value / 2
        d.rounded_rectangle((610, y, 610 + width, y + 62), radius=20, fill=f"#{color}")
        d.text((1560, y + 30), f"{value}/2", font=font(28, True), fill=f"#{color}", anchor="mm")
        y += 125
    d.text((850, 820),
           "Percentages from two respondents are shown as counts to avoid implying population-level prevalence.",
           font=font(24, True), fill=f"#{CORAL}", anchor="ma")
    img.save(ASSETS / "teacher_survey_counts.png", quality=95)

    # System architecture.
    img = Image.new("RGB", (1900, 1120), "white")
    d = ImageDraw.Draw(img)
    d.text((950, 42), "NenaPotha AI — Proposed and Implemented System Architecture",
           font=font(43, True), fill=f"#{NAVY}", anchor="ma")
    rounded_box(d, (65, 180, 400, 450), "#FCE4D6", f"#{CORAL}", "Users",
                "Grade 1–2 learner\nparent / teacher", 32, 24)
    rounded_box(d, (560, 130, 1110, 510), "#DCE6F1", f"#{BLUE}", "Flutter Mobile Application",
                "learning modules • reading\ntracing canvas • quizzes\nprogress • adult AI assistant", 34, 25)
    rounded_box(d, (1300, 125, 1805, 510), "#DFF2EF", f"#{TEAL}", "On-device Intelligence",
                "TFLite CNN (454 classes)\nlogistic text classifier\nTTS/STT device services", 33, 25)
    rounded_box(d, (560, 675, 1110, 1010), "#F3E5F5", "#8E44AD", "Firebase Backend",
                "Authentication • Firestore\nAI Logic proxy • App Check\nrole-aware data access", 34, 25)
    rounded_box(d, (1300, 690, 1805, 995), "#FFF2CC", "#C9A227", "External Adult-facing AI",
                "Gemini-backed guidance\nnot a child-facing tutor\nnot part of the two evaluated models", 31, 23)
    arrow(d, (400, 315), (560, 315), CORAL)
    arrow(d, (1110, 315), (1300, 315), BLUE)
    arrow(d, (835, 510), (835, 675), "8E44AD")
    arrow(d, (1110, 825), (1300, 825), "C9A227")
    d.text((950, 1060), "Privacy boundary: raw tracing inference remains on-device; persisted data is access-controlled.",
           font=font(25, True), fill=f"#{NAVY}", anchor="ma")
    img.save(ASSETS / "system_architecture.png", quality=95)

    # Two-component research workflow.
    img = Image.new("RGB", (1900, 1020), "white")
    d = ImageDraw.Draw(img)
    d.text((950, 42), "Research Component Workflows", font=font(44, True), fill=f"#{NAVY}", anchor="ma")
    d.text((470, 120), "Component 1: Letter Recognition", font=font(32, True), fill=f"#{CORAL}", anchor="ma")
    d.text((1430, 120), "Component 2: Text Difficulty", font=font(32, True), fill=f"#{BLUE}", anchor="ma")
    left = [
        ("Trace capture", "Flutter canvas"),
        ("Preprocess", "white background\n64×64 grayscale"),
        ("CNN inference", "TFLite on device"),
        ("Decision", "mapped label +\nconfidence threshold"),
    ]
    right = [
        ("Sinhala text", "Grade-tagged content"),
        ("Extract features", "word count • word length\nsentence length"),
        ("Logistic score", "sigmoid of linear model"),
        ("Decision", "Grade 1 or Grade 2"),
    ]
    for x, items, fills, outlines in [
        (90, left, ["#FCE4D6", "#FFF2CC", "#DFF2EF", "#E8EAF6"], [CORAL, "C9A227", TEAL, "5C6BC0"]),
        (1050, right, ["#DCE6F1", "#FFF2CC", "#DFF2EF", "#E8EAF6"], [BLUE, "C9A227", TEAL, "5C6BC0"]),
    ]:
        previous = None
        y = 190
        for (title, body), fill, outline in zip(items, fills, outlines):
            box = (x, y, x + 760, y + 150)
            rounded_box(d, box, fill, f"#{outline}", title, body, 29, 22)
            if previous:
                arrow(d, ((previous[0]+previous[2])//2, previous[3]), ((box[0]+box[2])//2, box[1]), NAVY, 5)
            previous = box
            y += 205
    d.text((470, 960), "Open gate: numeric ID → Unicode mapping and child-trace validation",
           font=font(23, True), fill=f"#{CORAL}", anchor="ma")
    d.text((1430, 960), "Open gate: larger balanced expert-labelled Sinhala corpus",
           font=font(23, True), fill=f"#{BLUE}", anchor="ma")
    img.save(ASSETS / "research_component_workflows.png", quality=95)

    # CNN metric summary for the administrative progress section.
    img = Image.new("RGB", (1700, 930), "white")
    d = ImageDraw.Draw(img)
    d.text((850, 45), "CNN Evaluation Evidence Available for Results Chapter",
           font=font(42, True), fill=f"#{NAVY}", anchor="ma")
    metrics = [
        ("Top-1 / validation accuracy", 94.04, CORAL),
        ("Macro precision", 94.40, ORANGE),
        ("Macro recall", 94.00, TEAL),
        ("Macro F1-score", 94.00, BLUE),
        ("Top-2 accuracy", 96.35, "8E44AD"),
        ("Top-3 accuracy", 97.12, "5C6BC0"),
    ]
    y = 150
    for label, value, color in metrics:
        d.text((60, y+28), label, font=font(25, True), fill=f"#{BLACK}", anchor="lm")
        d.rounded_rectangle((590, y, 1550, y+58), radius=18, fill="#E5E7EB")
        d.rounded_rectangle((590, y, 590 + 960*value/100, y+58), radius=18, fill=f"#{color}")
        d.text((1620, y+28), f"{value:.2f}%", font=font(25, True), fill=f"#{color}", anchor="mm")
        y += 115
    d.text((850, 860), "These are reference validation-set results, not child-field or classroom-effectiveness results.",
           font=font(24, True), fill=f"#{CORAL}", anchor="ma")
    img.save(ASSETS / "cnn_metrics_progress.png", quality=95)


def setup_document() -> Document:
    doc = Document()
    sec = doc.sections[0]
    sec.page_height = Cm(29.7)
    sec.page_width = Cm(21.0)
    sec.top_margin = Cm(2.3)
    sec.bottom_margin = Cm(2.2)
    sec.left_margin = Cm(2.8)
    sec.right_margin = Cm(2.2)

    normal = doc.styles["Normal"]
    normal.font.name = "Times New Roman"
    normal.font.size = Pt(11)
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Noto Sans Sinhala")
    normal.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    normal.paragraph_format.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
    normal.paragraph_format.space_after = Pt(6)

    for style_name, size, color in [
        ("Title", 22, NAVY),
        ("Heading 1", 17, NAVY),
        ("Heading 2", 14, BLUE),
        ("Heading 3", 12, TEAL),
    ]:
        s = doc.styles[style_name]
        s.font.name = "Times New Roman"
        s.font.size = Pt(size)
        s.font.bold = True
        s.font.color.rgb = RGBColor.from_string(color)
        s.paragraph_format.space_before = Pt(10)
        s.paragraph_format.space_after = Pt(6)
        s.paragraph_format.keep_with_next = True

    header = sec.header.paragraphs[0]
    header.text = "Updated Interim Submission — Chapters 1–3 — Student 28277"
    header.alignment = WD_ALIGN_PARAGRAPH.CENTER
    header.runs[0].font.name = "Times New Roman"
    header.runs[0].font.size = Pt(8)
    header.runs[0].font.color.rgb = RGBColor.from_string(MID_GREY)
    add_page_number(sec.footer.paragraphs[0])

    doc.core_properties.title = "Updated Interim Submission — ReadBuddy AI — Chapters 1–3"
    doc.core_properties.author = "L. M. I. Silva (28277)"
    doc.core_properties.subject = "BSc (Hons) in Software Engineering Final Year Research"
    settings = doc.settings._element
    update = OxmlElement("w:updateFields")
    update.set(qn("w:val"), "true")
    settings.append(update)
    return doc


def title_page(doc: Document) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(55)
    r = p.add_run("NSBM GREEN UNIVERSITY\nFACULTY OF COMPUTING")
    r.bold = True
    r.font.name = "Times New Roman"
    r.font.size = Pt(16)
    r.font.color.rgb = RGBColor.from_string(NAVY)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(35)
    r = p.add_run("DESIGN AND DEVELOPMENT OF AN AI-ENHANCED BILINGUAL READING AND COMPREHENSION ASSISTANT FOR GRADE 1 AND GRADE 2 PRIMARY SCHOOL STUDENTS")
    r.bold = True
    r.font.name = "Times New Roman"
    r.font.size = Pt(18)
    r.font.color.rgb = RGBColor.from_string(BLUE)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("On-Device Sinhala Letter Recognition and Sinhala Text-Difficulty Classification")
    r.italic = True
    r.font.size = Pt(14)
    r.font.color.rgb = RGBColor.from_string(CORAL)

    for text, size, bold in [
        ("UPDATED INTERIM RESEARCH SUBMISSION", 15, True),
        ("Chapters 01, 02 and 03 with Research Progress Update", 13, True),
        ("L. M. I. SILVA", 14, True),
        ("Student ID: 28277", 12, False),
        ("BSc (Hons) in Software Engineering", 12, False),
        ("2026", 12, False),
    ]:
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(22 if "UPDATED" in text or "SILVA" in text else 8)
        rr = p.add_run(text)
        rr.font.name = "Times New Roman"
        rr.font.size = Pt(size)
        rr.bold = bold

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(30)
    r = p.add_run("Supervisor: ______________________________________________")
    r.font.size = Pt(10)
    r.font.color.rgb = RGBColor.from_string(MID_GREY)
    doc.add_page_break()


def front_matter(doc: Document) -> None:
    doc.add_heading("Submission Scope and Evidence Statement", level=1)
    add_body(doc, "This submission contains updated Chapters 01, 02 and 03 only. The generic chapter-breakdown document and the interim-submission brief were treated as assessment instructions rather than factual evidence. Earlier source documents were reconciled with the implemented project. Consequently, the target population is restricted to Grade 1 and Grade 2, while prior Grade 3 plans, unsupported pre-test/post-test claims and unverified citations are excluded.")
    add_body(doc, "A separate administrative section titled Research Progress toward Results and Discussion is included after Chapter 3. It reports evidence already available for later chapters without presenting a Chapter 4 or Chapter 5. This distinction satisfies the requested progress update while preserving the Chapters 1–3-only thesis scope.")
    add_callout(doc, "Supervisor discussion required before submission", "The student must discuss the Grade 1–2 scope, treatment of the two-teacher exploratory survey, model-evaluation terminology, and remaining integration/testing gaps with the supervisor. A confirmation sheet is provided near the end of this document. This document does not claim that such discussion has already occurred.", PALE_ORANGE)

    doc.add_heading("Supervisor/Assessment Feedback Response Matrix", level=1)
    add_table(doc, ["Instruction or issue", "Action taken in this revision", "Status"], [
        ("Problem statement must be focused and supported by recent evidence.", "Reframed from a broad all-in-one Grade 1–3 reading problem to two Grade 1–2 research problems; added official 2023–2025 context and verified primary research.", "Addressed"),
        ("Use one ‘Wh’ research question.", "Replaced five disconnected questions with one integrated ‘How’ question and three analytical regions.", "Addressed"),
        ("Objectives must be research-specific: identify, analyze, develop, evaluate.", "Rewrote four objectives and added evidence traceability.", "Addressed"),
        ("Include a rich picture and workflow.", "Added rich picture, architecture, component workflows and DSR workflow.", "Addressed"),
        ("Literature review: 10% domain, 30% existing work, 60% technical analysis plus personal reflection.", "Reorganized Chapter 2 to follow the required balance and added explicit suitability judgements.", "Addressed"),
        ("Methodology must justify paradigm, approach, strategy, facts, execution and project management.", "Adopted pragmatism, deductive-with-inductive iteration, DSRM, structured data sources and Agile/Kanban governance.", "Addressed"),
        ("Progress update up to Results and Discussion.", "Added a non-chapter progress section with available metrics, current code-quality findings, discussion themes and remaining work.", "Addressed transparently"),
        ("Use IEEE references and recent research.", "Added numbered in-text citations and a verified IEEE-style list emphasizing 2023–2025 work.", "Addressed"),
    ], font_size=8.4)

    doc.add_heading("Research Progress Snapshot", level=1)
    add_table(doc, ["Area", "Evidence available at 19 August 2026", "Status"], [
        ("Chapters 1–3", "Scope, literature synthesis, DSR methodology, ethics and validity updated.", "Completed in this document"),
        ("Grade 1–2 application", "Flutter learning, reading, comprehension, progress and adult-support modules implemented.", "Implemented"),
        ("Letter CNN", "TFLite asset (2,527,776 bytes), 454 labels and reference validation metrics available.", "Model implemented; integration partially blocked"),
        ("Text classifier", "Binary Grade 1/2 logistic model wired into recommendation engine.", "Proof-of-concept implemented"),
        ("End-to-end tracing", "CNN verdict path exists, but numeric labels 1–454 are compared against Unicode letters; only five UI letters are exposed.", "Incomplete"),
        ("Static quality", "flutter analyze reports 10 issues: two warnings and eight informational/deprecation/style findings.", "Requires cleanup"),
        ("Automated tests", "Default counter widget test fails because it no longer matches the application.", "Test suite requires replacement"),
        ("Human evaluation", "No documented ethics-approved child field study or completed pre/post evaluation is present in the evidence pack.", "Not completed / not claimed"),
    ], font_size=8.3)

    doc.add_heading("Table of Contents", level=1)
    add_toc(doc)
    doc.add_page_break()

    doc.add_heading("List of Abbreviations", level=1)
    add_table(doc, ["Abbreviation", "Meaning"], [
        ("AI", "Artificial Intelligence"),
        ("ARA", "Automatic Readability Assessment"),
        ("CNN", "Convolutional Neural Network"),
        ("DSR/DSRM", "Design Science Research / Design Science Research Methodology"),
        ("ECE", "Expected Calibration Error"),
        ("HCR", "Handwritten Character Recognition"),
        ("NLP", "Natural Language Processing"),
        ("STT/TTS", "Speech-to-Text / Text-to-Speech"),
        ("TFLite", "TensorFlow Lite"),
        ("UI/UX", "User Interface / User Experience"),
    ])
    doc.add_page_break()


def chapter_one(doc: Document) -> None:
    doc.add_heading("Chapter 01 — Introduction", level=1)

    doc.add_heading("1.1 Chapter Overview", level=2)
    add_body(doc, "This chapter introduces ReadBuddy AI, an AI-enhanced bilingual mobile reading and comprehension assistant for Grade 1 and Grade 2 primary school students. It establishes the foundational-literacy context, reports cautiously interpreted preliminary teacher requirement-elicitation evidence, defines the general and specific research problems, and states the research question, motivation, aim and objectives. It then explains the proposed workflow, resources and project boundaries. The chapter concludes by linking the identified gap to the literature reviewed in Chapter 2.")

    doc.add_heading("1.2 Problem Background", level=2)
    doc.add_heading("1.2.1 Foundational-Literacy Context", level=3)
    add_body(doc, "Reading is a gateway skill through which learners access content across the curriculum. In Sri Lanka, interruptions associated with the COVID-19 period and the economic crisis intensified existing learning inequalities. A joint Ministry of Education and UNICEF initiative reported in 2023 that 85% of assessed Grade 3 children had not achieved minimum proficiency in literacy and numeracy and that learning disruption affected approximately 1.6 million primary children [1]. This combined literacy-and-numeracy statistic cannot be treated as a direct measurement of Grade 1–2 reading alone; however, it demonstrates the urgency of strengthening foundational learning before children reach Grade 3.")
    add_body(doc, "The World Bank's 2024 Sri Lanka Learning Poverty Brief emphasizes that the country lacks recent internationally comparable reading-assessment data and last administered the cited end-of-primary national assessment in 2015 [2]. It also reports primary-education expenditure per child below South Asian and lower-middle-income comparators. Therefore, the problem is not only access to digital content. Locally appropriate tools must be paired with valid evidence showing what is measured and for whom.")
    add_body(doc, "The Grade 1–2 boundary is aligned with the Ministry of Education's current reform structure, which groups Grades 1 and 2 as Key Stage 1 [3]. This stage is appropriate for a research artifact focused on letter knowledge, basic word construction, short-text reading and early comprehension. Restricting the system to these two grades also corrects the mismatch in earlier drafts, where Grade 3 was claimed despite the final difficulty classifier supporting only Grades 1 and 2.")

    doc.add_heading("1.2.2 Role of Educational Technology", level=3)
    add_body(doc, "Educational technology can offer immediate feedback, repeated practice, linked audio/visual representations and adjustable learning pathways. Nevertheless, technology should not be assumed to improve literacy simply because it is interactive. A 2024 systematic review of 67 early-literacy studies found some positive evidence, but only part of the evidence supported medium-to-large effects, and the contribution of specific technological features remained insufficiently studied [4]. This finding informs the position taken in this thesis: ReadBuddy AI is a designed and technically evaluated artifact, while its effect on children's learning remains a future empirical question.")
    add_body(doc, "The learning design also reflects the view that reading comprehension emerges through the interaction of decoding and linguistic comprehension [5]. ReadBuddy AI therefore includes letter and word activities alongside reading, vocabulary and comprehension rather than presenting tracing as a complete reading intervention. The system assists practice; it is not an autonomous teacher or a clinical diagnostic tool.")

    doc.add_heading("1.2.3 Preliminary Teacher Requirement-Elicitation Evidence", level=3)
    add_body(doc, "The supplied interim report records responses from two teachers. Both respondents identified letter recognition, mirror writing, incorrect letter formation and pronunciation of complex Sinhala letters as challenges; one of the two also identified word reading. The two respondents estimated that an average of 24.5% of pupils in their own classes experienced reading difficulty. Because n=2 is extremely small, 100% means two teachers and 50% means one teacher. These figures are requirement-elicitation signals, not population prevalence estimates.")
    doc.add_picture(str(ASSETS / "teacher_survey_counts.png"), width=Inches(6.35))
    add_caption(doc, "Figure 1.1. Preliminary teacher requirement-elicitation findings, reported as counts (source: supplied interim report; n=2).")
    add_callout(doc, "Evidence limitation", "Raw questionnaire responses, participant information/consent records and ethics approval were not included in the supplied evidence pack. Until these are verified, the survey must be treated as preliminary design input rather than a representative formal study. No inferential statistics are appropriate.", PALE_ORANGE)

    doc.add_heading("1.2.4 Technical Background", level=3)
    add_body(doc, "Two technical opportunities emerge from the educational context. First, a drawing captured in a letter-tracing activity can be classified using a CNN and executed locally through TensorFlow Lite. Second, measurable characteristics of Sinhala text can be used to provide an independent check on manually assigned Grade 1/2 labels. Existing Sinhala HCR studies demonstrate the feasibility of CNNs [6]–[8], while low-resource ARA research shows that language-specific corpora and features remain essential even as multilingual neural models develop [9]–[14]. These two strands motivate the research components integrated into ReadBuddy AI.")

    doc.add_heading("1.3 Problem Statement", level=2)
    doc.add_heading("1.3.1 General Problem", level=3)
    add_body(doc, "Grade 1 and Grade 2 Sinhala-speaking learners have limited access to a single, locally relevant mobile environment that combines early writing practice, graded reading, comprehension support and evidence-based progress feedback. Without reliable automated feedback, independent practice can become passive: a child may repeat an incorrect form, and adults may see activity completion without understanding whether the modeled skill was performed correctly. At a wider level, this limits the capacity of low-cost educational technology to complement teacher-led foundational-literacy support.")

    doc.add_heading("1.3.2 Specific Problem and Research Gap", level=3)
    add_body(doc, "The specific problem has two parts. First, the reviewed Sinhala HCR literature evaluates isolated offline images but does not establish a Grade 1, child-facing, on-device tracing-feedback workflow [6]–[8]. Second, no verified Grade 1/2 Sinhala readability corpus or established Sinhala readability model was located in the structured search; the closest low-resource studies rely on larger annotated corpora, cross-lingual evidence or richer linguistic features [9]–[14]. Within the reviewed search scope, no system was found that combines both functions inside one Sinhala/English early-literacy application.")
    add_body(doc, "The research gap is consequently an artifact gap and an evidence gap. The artifact gap concerns the integration of on-device letter classification and Sinhala Grade 1/2 text checking in one mobile workflow. The evidence gap concerns the absence of field-valid child tracing data and a sufficiently large, independently labelled Sinhala readability corpus. ReadBuddy AI investigates the integrated technical pipeline while explicitly documenting these limitations.")

    doc.add_heading("1.4 Research Question", level=2)
    add_callout(doc, "Primary research question", "How can an AI-enhanced bilingual mobile reading assistant be designed and evaluated to provide offline Sinhala letter-tracing classification for Grade 1 learners and automated Sinhala text-difficulty classification for Grade 1 and Grade 2 reading content?", PALE_TEAL)
    add_body(doc, "The question contains three connected analytical regions rather than multiple unrelated research questions:")
    add_bullets(doc, [
        "the accuracy, class-level behaviour and confidence calibration of the Sinhala letter CNN on reference validation data;",
        "the feasibility and limitations of a lightweight, interpretable Grade 1/2 Sinhala text classifier; and",
        "the integration, privacy, reliability and evidence requirements for trustworthy mobile deployment.",
    ])

    doc.add_heading("1.5 Research Motivation", level=2)
    add_body(doc, "The social motivation is the need to strengthen foundational learning through low-cost tools that can operate under variable connectivity. The educational motivation arises from the value of repeated letter, word, reading and comprehension practice, while respecting the central role of teachers and families. The research motivation is the shortage of task-specific Sinhala resources and the opportunity to contribute an evaluated artifact rather than another English-centred demonstration.")
    add_body(doc, "The practical motivation emerged from inspecting the existing application. The tracing activity initially required model-grounded correctness feedback, while story difficulty depended on authored grade tags. These problems could be addressed through original trained components rather than solely through a third-party generative API. The resulting project combines software engineering, computer vision and NLP within a bounded Grade 1–2 scope.")

    doc.add_heading("1.6 Research Aim", level=2)
    add_callout(doc, "Research aim", "To design, develop and evaluate an AI-enhanced bilingual mobile reading and comprehension assistant for Grade 1 and Grade 2 students by integrating an on-device Sinhala handwritten-letter CNN and an interpretable Sinhala Grade 1/2 text-difficulty classifier.")

    doc.add_heading("1.7 Research Objectives", level=2)
    add_numbered(doc, [
        "To identify the educational, application and evidence gaps affecting automated Sinhala letter-tracing feedback and grade-appropriate reading-content selection for Grade 1 and Grade 2 learners.",
        "To analyze Sinhala handwriting-recognition approaches, low-resource readability methods, on-device deployment options and appropriate evaluation strategies.",
        "To design and develop a custom CNN deployed through TensorFlow Lite and a logistic-regression Grade 1/2 text classifier, and integrate both within the Flutter-based ReadBuddy AI application.",
        "To evaluate the CNN using held-out validation metrics and integration tests, and evaluate the text classifier against transparent baselines while documenting reliability, validity and field-evidence limitations.",
    ])
    add_table(doc, ["Objective", "Research evidence", "Success indicator"], [
        ("RO1 — Identify", "Official context, preliminary teacher input, code audit and literature gap", "A focused and bounded problem supported by auditable evidence."),
        ("RO2 — Analyze", "Comparative algorithm, design and workflow matrices", "Every technology decision includes suitability and trade-offs."),
        ("RO3 — Develop", "Versioned model artifacts, source code, architecture and Android demonstration", "Reproducible component and integration evidence."),
        ("RO4 — Evaluate", "CNN metrics, baselines, calibration, tests, latency and limitations", "Claims use correct data split and uncertainty language."),
    ], font_size=8.6)

    doc.add_heading("1.8 Rich Picture of the Proposed Solution", level=2)
    doc.add_picture(str(ASSETS / "rich_picture.png"), width=Inches(6.35))
    add_caption(doc, "Figure 1.2. Rich picture of the Grade 1–2 ReadBuddy AI solution (author-generated).")
    add_body(doc, "A Grade 1 learner traces a selected letter. The image is captured, normalized and sent to the local TFLite CNN. Reading content is separately analyzed by the text classifier, which estimates Grade 1 or Grade 2 difficulty. The Flutter application delivers activities, while Firebase provides authenticated progress storage and adult access. The adult-facing generative AI assistant is an application-support feature rather than one of the two evaluated research models.")
    add_body(doc, "The rich picture deliberately shows the outstanding evidence gate. Numeric CNN labels must be mapped to Unicode letters, and the full pipeline must be validated with representative child traces before the feedback can be described as trustworthy in a classroom context.")

    doc.add_heading("1.9 Resource Requirements", level=2)
    doc.add_heading("1.9.1 Hardware", level=3)
    add_table(doc, ["Resource", "Purpose", "Current use"], [
        ("Windows development laptop", "Flutter development, model integration, testing and documentation", "Primary workstation"),
        ("Android emulator / physical device", "Functional, UI and inference testing", "API 34 emulator used; physical-device performance remains to be measured"),
        ("Google Colab T4 GPU", "CNN training and evaluation", "Used for model experimentation"),
        ("Secure versioned storage", "Preserve datasets, notebooks, metrics and model hashes", "Required to close provenance gap"),
    ])
    doc.add_heading("1.9.2 Software", level=3)
    add_table(doc, ["Software", "Purpose"], [
        ("Flutter / Dart", "Cross-platform UI, learning logic and local logistic-regression inference"),
        ("TensorFlow / Keras", "CNN training and TFLite export"),
        ("TensorFlow Lite / tflite_flutter", "On-device letter classification"),
        ("scikit-learn", "Logistic regression and evaluation utilities"),
        ("Firebase Authentication / Firestore", "Role-aware identity and progress persistence"),
        ("Cloud Functions / Gemini", "Adult-facing AI guidance; outside the two evaluated models"),
        ("Git or equivalent version control", "Source and research-artifact traceability"),
    ])

    doc.add_heading("1.10 Project Scope", level=2)
    add_table(doc, ["In scope", "Out of scope"], [
        ("Grade 1 and Grade 2 students and content only", "Grade 3 or higher-grade difficulty classification"),
        ("Sinhala and English application interface; Sinhala ML components", "A universal multilingual literacy model or Tamil support"),
        ("Isolated Sinhala letter classification using a bundled TFLite model", "Full-page worksheet analysis, connected handwriting, word OCR or segmentation"),
        ("Five-letter Grade 1 tracing prototype: අ, ආ, ක, ග and ස", "Complete Grade 1 alphabet and verified stroke-order paths"),
        ("Binary Grade 1/2 text-difficulty proof-of-concept", "Clinical diagnosis, semantic comprehension diagnosis or production-grade readability scoring"),
        ("Reading, vocabulary, quizzes, recommendations and progress support", "Replacement of teachers or an unsupervised child-facing generative chatbot"),
        ("Dataset validation and technical integration evaluation", "Claims of classroom learning improvement without ethics-approved participant evidence"),
    ], font_size=8.7)
    add_body(doc, "Assumptions include access to an Android device, legal research use of the selected public dataset, correct initial curriculum tagging by the content author, and formal approval before any future collection from minors. Constraints include Sinhala resource scarcity, a 26-sample readability corpus, incomplete class mapping, approximate tracing guides and a single-researcher schedule.")

    doc.add_heading("1.11 Chapter Summary", level=2)
    add_body(doc, "This chapter established a focused Grade 1–2 research problem grounded in Sri Lankan foundational-learning context, cautious preliminary teacher input and two identifiable technical gaps. It defined one integrated research question, a measurable aim, four research objectives, the solution workflow, required resources and explicit boundaries. The next chapter critically evaluates whether prior educational, handwriting-recognition and readability research supports the selected contribution and design decisions.")
    doc.add_page_break()


def chapter_two(doc: Document) -> None:
    doc.add_heading("Chapter 02 — Literature Review", level=1)

    doc.add_heading("2.1 Chapter Overview", level=2)
    add_body(doc, "This chapter critically reviews the knowledge required to justify ReadBuddy AI. Following the required balance, the domain overview is intentionally concise, existing systems and frameworks are comparatively assessed, and most of the chapter is devoted to technological analysis. The review emphasizes recent 2020–2025 work, retaining older sources only when they establish a foundational theory, evaluation method or research strategy. Each major subsection ends with a reasoned judgement of suitability for the present problem.")

    doc.add_heading("2.2 Conceptual Map of the Literature", level=2)
    doc.add_picture(str(ASSETS / "conceptual_map.png"), width=Inches(6.35))
    add_caption(doc, "Figure 2.1. Conceptual organization of the reviewed literature (author-generated).")
    add_body(doc, "The first strand concerns foundational literacy and responsible educational technology. The second examines Sinhala handwritten-character recognition, datasets and mobile inference. The third considers automatic readability assessment, particularly in low-resource languages. ReadBuddy AI occupies the intersection: a Grade 1–2 educational artifact that integrates offline letter classification and text-difficulty checking while exposing the limitations of currently available Sinhala data.")

    doc.add_heading("2.3 Domain Overview", level=2)
    doc.add_heading("2.3.1 Early Reading and Writing", level=3)
    add_body(doc, "Early literacy includes letter knowledge, decoding, vocabulary, oral-language understanding and the ability to construct meaning from text. The Simple View of Reading conceptualizes reading comprehension as the interaction of decoding and linguistic comprehension [5]. Although this theory predates the five-year review window, it is retained because it explains why a reading assistant should not be reduced to pronunciation or tracing alone.")
    add_body(doc, "Recent educational-technology evidence is more cautious than commercial claims. Bautista et al. found that some early-literacy technologies were effective, but the evidence was heterogeneous and feature-specific conclusions were limited [4]. Therefore, an application should be evaluated as a combination of pedagogy, interface, content and feedback—not as a technology whose effectiveness is self-evident.")

    doc.add_heading("2.3.2 Sri Lankan and Low-Resource Context", level=3)
    add_body(doc, "Official Sri Lankan evidence demonstrates a foundational-learning recovery need [1]–[3], but it does not provide a ready-made Grade 1/2 Sinhala ML corpus. In this thesis, ‘low-resource’ refers specifically to shortages that affect the research task: child-trace images, expert-labelled grade-level text, verified label mappings and Sinhala-specific linguistic tools. This operational definition avoids treating all non-English languages as uniformly low-resource.")

    doc.add_heading("2.4 Existing Systems, Frameworks and Designs", level=2)
    doc.add_heading("2.4.1 Sinhala Handwritten-Character Recognition", level=3)
    add_table(doc, ["Study", "Data and method", "Reported evidence", "Suitability judgement"], [
        ("Mariyathas et al., 2020 [6]", "CNN; approximately 110,000 images; experiments up to 434 classes", "82.33% overall accuracy for 434 characters", "Strong Sinhala CNN precedent; not an on-device Grade 1 tracing evaluation."),
        ("Wasalthilake and Thangathurai, 2022 [7]", "55 characters × 33 samples; handcrafted pixel length vs. CNN", "CNN accuracy of 85.71%", "Supports learned features over a weak handcrafted baseline; sample is small and deployment is not educational."),
        ("Karunarathne et al., 2024 [8]", "6,000 images, 60 classes; CNN vs. Gabor-initialized CNN", "CNN test accuracy 90.14%; GCNN 80.00% but faster early convergence", "Useful architecture/convergence evidence; not directly comparable with a 454-class dataset."),
        ("ReadBuddy AI", "454-class custom CNN; 64×64 grayscale; TFLite; five-letter UI", "94.04% reference validation accuracy; macro-F1 0.940", "Adds local mobile integration, but Unicode mapping and child-field validity remain open."),
    ], font_size=8.0)
    add_body(doc, "Personal reflection: the reported accuracies cannot be ranked as a leaderboard because the studies differ in classes, sample sources, partitions and preprocessing. The defensible novelty of ReadBuddy AI is the intended child-facing, on-device workflow and combination with text-level checking, not a claim of being the universally best Sinhala recognizer.")

    doc.add_heading("2.4.2 Automatic Readability Assessment", level=3)
    add_table(doc, ["Study", "Approach", "Key finding", "Relevance and limitation"], [
        ("Pilán et al., 2016 [15]", "Supervised linguistic features for Swedish learning materials", "81.3% document-level and 63.4% sentence-level accuracy", "Shows both value of learned linguistic features and difficulty of short-text grading."),
        ("Imperial and Kochmar, 2023 [9], [10]", "Surface, syllable, n-gram and cross-lingual features for low-resource Philippine languages", "Language relatedness and tailored features improved low-resource ARA", "Supports handcrafted features when deep language tools/data are unavailable."),
        ("Naous et al., 2024 [11]", "9,757 human-annotated sentences across five languages and 112 sources", "Benchmark exposes domain and language diversity challenges", "Demonstrates the scale and annotation quality missing from the current Sinhala corpus."),
        ("Liu et al., 2025 [12]", "Traditional, neural, hybrid and LLM sentence models", "Hybrid linguistic/neural models outperformed alternatives across English and Chinese", "Strong future direction, but unsuitable for 26 current samples."),
        ("Kazakov et al., 2025 [13]", "Language-specific Bulgarian index using child-targeted texts and surface features", "Polynomial relationships improved fit but reduced interpretability", "Close analogy for a first-stage language-specific educational index."),
        ("Yang et al., 2025 [14]", "Adaptive pre-training plus linguistic-feature fusion for Chinese ARA", "State-of-the-art textbook results and transfer to other reading domains", "Shows that data quality, balance and feature fusion drive modern ARA."),
        ("ReadBuddy AI", "26 Sinhala samples; three surface features; binary logistic regression", "69.2% training accuracy versus 65.4% majority baseline", "Useful only as an interpretable integration proof-of-concept."),
    ], font_size=7.8)
    add_body(doc, "Personal reflection: recent ARA literature does not invalidate a simple logistic model; it clarifies what the model can legitimately claim. With 26 samples, a transformer or hybrid architecture would invite severe overfitting. Logistic regression is appropriate for demonstrating an auditable pipeline, but it cannot represent Sinhala morphological complexity, vocabulary familiarity, pillam density, cohesion or reader-specific knowledge. The immediate research priority is therefore corpus construction and expert annotation rather than model complexity.")

    doc.add_heading("2.4.3 Educational Applications and Platforms", level=3)
    add_body(doc, "Commercial reading products commonly advertise speech feedback, adaptive content and progress dashboards, while Sri Lanka's e-Thaksalawa provides curriculum-aligned digital resources. These systems are useful functional comparators but cannot support research-performance claims unless their datasets, algorithms and evaluation protocols are public. For this reason, peer-reviewed systems carry greater weight in algorithm selection, while commercial systems inform only feature and workflow comparisons.")
    add_table(doc, ["Capability", "Static curriculum repository", "Typical commercial reading app", "ReadBuddy AI research prototype"], [
        ("Sinhala/English content", "Potentially available", "Usually English-centred", "Included"),
        ("Letter-writing practice", "Activity-dependent", "Product-dependent", "Five-letter Grade 1 prototype"),
        ("On-device Sinhala CNN", "Not evidenced", "Proprietary/unknown", "Implemented with mapping limitation"),
        ("Sinhala Grade 1/2 text check", "Not evidenced", "Proprietary/unknown", "Exploratory logistic classifier"),
        ("Comprehension and vocabulary", "Content-dependent", "Common", "Included"),
        ("Transparent research metrics", "Not normally applicable", "Rarely public", "Reported with limitations"),
    ], font_size=8.2)

    doc.add_heading("2.5 Technological Analysis", level=2)
    doc.add_heading("2.5.1 Algorithmic Analysis — Letter Recognition", level=3)
    add_body(doc, "Traditional contour, projection or pixel-length approaches depend on manually designed features and can struggle with writer variation. CNNs learn local edges, curves and increasingly abstract shapes through convolution and pooling. The three Sinhala studies reviewed above collectively justify CNN selection [6]–[8]. A custom three-block CNN was selected for ReadBuddy AI because the task contains a relatively large number of single-domain classes and mobile deployment benefits from a compact model.")
    add_body(doc, "Transfer learning could offer stronger general-purpose features and faster convergence, while Gabor initialization can accelerate early learning [8]. However, architecture comparison requires a shared dataset and evaluation protocol. The final thesis should therefore include a controlled ablation between the custom CNN and at least one lightweight transfer-learning baseline before claiming architectural superiority.")

    doc.add_heading("2.5.2 Algorithmic Analysis — Text Difficulty", level=3)
    add_body(doc, "Classical readability formulas use surface properties such as word and sentence length. Machine learning generalizes this idea by estimating feature weights from labelled texts. Recent work increasingly combines surface, lexical, syntactic, semantic and neural representations [9]–[15]. ReadBuddy AI uses logistic regression because it is interpretable, cheap to execute in Dart and appropriate for a small exploratory dataset. The trade-off is limited construct validity: a short text can contain difficult vocabulary, and a long sentence can remain easy if its structure and words are familiar.")
    add_body(doc, "The 69.2% training accuracy is only 3.8 percentage points above the 65.4% majority-class baseline. It is methodologically incorrect to compare this number directly with published held-out test accuracy. A proper future evaluation must use more texts, independent teacher labels, source-grouped partitions, balanced accuracy, macro-F1 and uncertainty estimates.")

    doc.add_heading("2.5.3 On-Device versus Cloud Design", level=3)
    add_body(doc, "On-device inference reduces network latency and avoids transferring every child's trace image to a server. Mobile GPU research similarly motivates local neural inference through latency and privacy benefits, while acknowledging device compute and energy constraints [16]. TensorFlow Lite was therefore selected for the CNN. Firebase remains responsible for authenticated persistence, and the adult-facing Gemini feature is separated from child trace classification.")
    doc.add_picture(str(ASSETS / "system_architecture.png"), width=Inches(6.4))
    add_caption(doc, "Figure 2.2. System architecture and intelligence/privacy boundaries (author-generated).")

    doc.add_heading("2.5.4 Preprocessing and Workflow Design", level=3)
    add_body(doc, "Image preprocessing must reproduce the model's training conditions. The trace is captured from a Flutter RepaintBoundary, composited onto white, decoded, resized to 64×64, converted to grayscale and normalized to [0,1]. The white-compositing step is critical: leaving transparent pixels can invert or distort the effective background and create silent distribution shift.")
    doc.add_picture(str(ASSETS / "research_component_workflows.png"), width=Inches(6.4))
    add_caption(doc, "Figure 2.3. Letter-recognition and text-difficulty workflows (author-generated).")
    add_body(doc, "The text workflow tokenizes on whitespace, separates sentences at punctuation and calculates three features. The output is always forced to Grade 1 or Grade 2; it cannot express uncertainty or ‘outside scope.’ The recommendation engine must therefore treat it as a weak signal and preserve authored-grade fallback behaviour.")

    doc.add_heading("2.5.5 Evaluation Design", level=3)
    add_body(doc, "Accuracy alone can hide uneven class performance. Macro precision, recall and F1 give equal importance to each class, while a confusion matrix reveals systematic visual errors. Top-k accuracy is useful because a correct alternative may remain among the model's strongest predictions. Confidence also requires evaluation: modern neural networks can be miscalibrated, so Expected Calibration Error and reliability diagrams are relevant when a confidence threshold drives feedback [17]. Grad-CAM can visualize which image regions influence a CNN prediction [18], but it should be reported only when executed on the exact shipped model.")

    doc.add_heading("2.5.6 Child-Centred and Ethical Design", level=3)
    add_body(doc, "A classifier error in an educational application is not merely a technical event. Incorrect negative feedback can frustrate a learner, while incorrect positive feedback can reinforce an error. The interface should use supportive language, allow retrying, disclose fallback scoring and avoid labels suggesting disability or ability. Any future storage of raw handwriting requires explicit purpose, consent, minimization, security and deletion controls.")

    doc.add_heading("2.6 Critical Reflection and Research Gap", level=2)
    add_body(doc, "The literature supports four conclusions. First, educational technology can assist early literacy, but learning impact is not guaranteed [4]. Second, CNNs are suitable for Sinhala isolated-character recognition, although existing studies do not establish child-trace field performance [6]–[8]. Third, modern ARA depends on language-specific data, rich features and human annotation; low-resource settings still benefit from interpretable handcrafted features [9]–[15]. Fourth, on-device inference is technically appropriate where latency, connectivity and privacy matter [16].")
    add_body(doc, "No reviewed work combines a Grade 1–2 Sinhala/English literacy application with an on-device Sinhala letter classifier and an offline Sinhala Grade 1/2 text-difficulty checker. ReadBuddy AI addresses that integration gap. It does not yet close the evidence gap: numeric label mapping, representative child traces, exact training provenance and an expert-labelled readability corpus remain necessary. This distinction between artifact contribution and validated educational effectiveness is the central critical position of this thesis.")

    doc.add_heading("2.7 Chapter Summary", level=2)
    add_body(doc, "Chapter 2 established the educational and technical foundation for ReadBuddy AI. It compared three Sinhala HCR studies, recent 2023–2025 low-resource and multilingual ARA research, and relevant mobile design choices. The analysis supports a compact on-device CNN and an interpretable logistic proof-of-concept, while rejecting unqualified claims of model superiority or learning improvement. Chapter 3 translates the justified decisions into a reproducible DSR methodology.")
    doc.add_page_break()


def chapter_three(doc: Document) -> None:
    doc.add_heading("Chapter 03 — Methodology", level=1)

    doc.add_heading("3.1 Chapter Overview", level=2)
    add_body(doc, "This chapter describes how the research artifact was investigated, developed and evaluated. It defines the research paradigm, approach and design-science strategy; explains evidence and dataset collection; specifies both ML workflows and mobile integration; maps methods to objectives; and addresses project management, ethics, reliability and validity. The methodology distinguishes completed evidence from future work and does not present a human learning-effectiveness study as completed.")

    doc.add_heading("3.2 Research Paradigm", level=2)
    add_body(doc, "The study adopts a pragmatist paradigm. Pragmatism is suitable because the research is concerned with constructing a useful artifact and judging it through evidence appropriate to each subproblem. Quantitative measures such as accuracy, macro-F1 and calibration evaluate model behaviour, while iterative software decisions respond to observed integration and data limitations. Pragmatism avoids an artificial choice between purely objective model measurement and design-oriented problem solving [19], [20].")

    doc.add_heading("3.3 Research Approach", level=2)
    add_body(doc, "The approach is predominantly deductive with inductive iteration. Deductively, the literature suggests that CNNs can classify Sinhala characters and that linguistic surface features can support first-stage readability estimation. These propositions are tested using defined metrics. Inductively, observed evidence changes the design: the original three-grade difficulty problem was reduced to Grades 1 and 2 when Grade 3 contained insufficient data; preprocessing was corrected to a white background; and the integration audit exposed the need for numeric-ID-to-Unicode mapping.")
    add_body(doc, "The current research is not described as a completed mixed-method effectiveness study. A two-teacher requirement-elicitation exercise exists, but no verified ethics-approved child pre/post study is present. The principal evaluation is therefore quantitative artifact evaluation plus qualitative technical reflection. A future mixed-method field study can be added only after approval, consent and an adequate sampling plan.")

    doc.add_heading("3.4 Research Strategy — Design Science Research", level=2)
    add_body(doc, "Design Science Research is appropriate because the core output is an instantiated mobile/ML artifact. Peffers et al. define six DSRM activities: problem identification and motivation, definition of solution objectives, design and development, demonstration, evaluation and communication [19]. This structure aligns directly with the university breakdown and prevents the project from being treated as software development without research evaluation.")
    doc.add_picture(str(ASSETS / "dsr_workflow.png"), width=Inches(6.4))
    add_caption(doc, "Figure 3.1. Design Science Research Methodology applied to ReadBuddy AI, adapted from [19].")

    doc.add_heading("3.5 Fact Collection Mechanisms", level=2)
    doc.add_heading("3.5.1 Structured Literature Review", level=3)
    add_body(doc, "Literature was discovered through IEEE Xplore, ACL Anthology, SpringerLink, ScienceDirect, institutional repositories and official Sri Lankan/international education sources. The preferred publication window was 2020–2026; older work was retained when it established theory, DSR, calibration or readability foundations. Search strings combined terms such as ‘Sinhala handwritten character recognition CNN,’ ‘child tracing on-device,’ ‘automatic readability assessment low-resource,’ ‘grade-level text classification’ and ‘early literacy educational technology.’")
    add_table(doc, ["Criterion", "Operational rule"], [
        ("Include", "Peer-reviewed primary research/systematic review; official policy/statistics; explicit data/method/results; direct relevance to one research strand."),
        ("Exclude", "Unverifiable snippets, duplicate versions, unsupported commercial claims, missing methodological relevance and unconfirmed bibliographic records."),
        ("Extract", "Authors, year, venue, DOI/URL, sample/dataset, classes/features, model, metrics, deployment, limitations and suitability decision."),
        ("Quality control", "Prefer original publisher/repository metadata and distinguish evidence from inference."),
    ], font_size=8.6)

    doc.add_heading("3.5.2 Preliminary Teacher Requirement Elicitation", level=3)
    add_body(doc, "The supplied interim report summarizes two teacher responses concerning reading, writing and pronunciation challenges. The data informed feature prioritization, especially letter recognition and formation. Because the sample is non-representative and the raw evidence/ethics documents were not supplied, the study reports counts and uses the responses only as preliminary requirements input. No generalization to Sri Lankan teachers or pupils is made.")

    doc.add_heading("3.5.3 Sinhala Letter Dataset", level=3)
    add_body(doc, "The CNN was trained using the Sinhala Letter and Modifications dataset, commonly identified as Sinhala Letter 454 [22]. The project summary records approximately 87,141 training and 10,896 validation images across 454 numeric classes. Before the final thesis, the exact downloaded version, total directory counts, class distribution, license, writer metadata, random seed and checksums must be archived because public descriptions of the dataset contain differing total counts.")
    add_table(doc, ["Dataset property", "Recorded project value", "Validity consideration"], [
        ("Classes", "454", "Includes letters and modifications; current labels are numeric rather than Unicode."),
        ("Training images", "Approximately 87,141", "Must be verified against the final dataset manifest."),
        ("Validation images", "10,896", "Reported performance is validation-set performance."),
        ("Input", "64×64 grayscale after preprocessing", "Must match the exact shipped TFLite model."),
        ("Target context", "Reference handwritten samples", "Not representative evidence of Grade 1 finger traces."),
    ])

    doc.add_heading("3.5.4 Grade 1/2 Text Dataset", level=3)
    add_body(doc, "The text classifier uses 26 samples taken from the application's authored Sinhala content: 9 Grade 1 and 17 Grade 2. Labels correspond to existing content placement rather than independent expert judgement. Every future experiment should preserve the raw text, source story, authored grade, annotator grade and feature vector in a versioned data file. Texts from the same story or near-duplicate template must remain in the same partition to prevent leakage.")

    doc.add_heading("3.5.5 Software and Integration Evidence", level=3)
    add_body(doc, "Source code, model assets, emulator execution, static-analysis output and test output provide engineering evidence. At the current audit, flutter analyze reports ten findings, and the only widget test is an obsolete counter template that fails against the current app. These outcomes do not invalidate the research models, but they show that software-quality evidence is not yet submission-complete.")

    doc.add_heading("3.6 Research Methodology Execution Workflow", level=2)
    add_table(doc, ["DSRM stage", "Research activity", "Objective", "Evidence/status"], [
        ("Problem identification", "Official context, preliminary teacher input, literature and application audit", "RO1", "Problem narrowed to Grade 1–2 and two ML components"),
        ("Define objectives", "Create one RQ, aim and four traceable objectives", "All", "Completed"),
        ("Design/development", "Train CNN, build logistic model, integrate Flutter/TFLite/Firebase", "RO3", "Implemented with mapping/provenance gaps"),
        ("Demonstration", "Run Grade 1–2 workflows on Android", "RO3", "Prototype demonstrated; evidence pack should be refreshed"),
        ("Evaluation", "Validation metrics, calibration, baselines, static/functional tests", "RO4", "CNN evidence available; text/app evidence incomplete"),
        ("Communication", "Updated Chapters 1–3, progress report and viva evidence index", "All", "Current submission"),
    ], font_size=8.2)

    doc.add_heading("3.7 Component 1 — Sinhala Letter Recognition Method", level=2)
    doc.add_heading("3.7.1 Model Architecture and Training", level=3)
    add_body(doc, "The shipped research component is described as a custom three-block CNN. Each block applies convolution and max pooling, followed by dense classification layers, dropout and a 454-way softmax output. Training used 64×64 grayscale inputs, Adam optimization, sparse categorical cross-entropy, batch size 32 and 15 epochs. Two recorded runs produced approximately 94.10% and 94.04% validation accuracy, suggesting run-level stability.")
    add_callout(doc, "Reproducibility gap", "The repository notebook currently describes a different 128×128 MobileNetV2/TFJS pipeline, whereas the app ships a 64×64 custom-CNN TFLite model. The exact notebook that generated the shipped model must be recovered and archived with environment versions, dataset manifest, seed and SHA-256 hashes before final submission.", PALE_ORANGE)

    doc.add_heading("3.7.2 Preprocessing and Inference", level=3)
    add_numbered(doc, [
        "Capture the child's strokes from the Flutter drawing boundary.",
        "Composite the transparent trace onto a white background matching the training distribution.",
        "Decode and resize the image to 64×64 pixels.",
        "Convert to grayscale and normalize channel values to [0,1].",
        "Reshape to [1,64,64,1] and execute the TFLite interpreter.",
        "Return the top class and softmax confidence, then map the numeric class ID to the corresponding Sinhala Unicode form.",
        "Compare the mapped prediction with the expected letter and require confidence above the configured 0.50 threshold.",
    ])

    doc.add_heading("3.7.3 Evaluation Measures", level=3)
    add_table(doc, ["Measure", "Purpose", "Current evidence"], [
        ("Top-1 accuracy", "Overall reference classification", "94.04% on n=10,896 validation images"),
        ("Macro precision / recall / F1", "Treat all 454 classes equally", "0.944 / 0.940 / 0.940"),
        ("Top-2 / top-3 accuracy", "Check if correct label remains among alternatives", "96.35% / 97.12%"),
        ("Confusion matrix", "Identify systematic class-pair errors", "Figure available; exact class mapping needs completion"),
        ("ECE / reliability", "Assess whether confidence reflects correctness [17]", "ECE 0.084 on reference validation data"),
        ("Grad-CAM", "Inspect image regions influencing predictions [18]", "Planned/not verified on exact shipped model"),
        ("Mobile latency", "Evaluate practical inference time", "Physical-device median and p95 pending"),
        ("Child-field accuracy", "Evaluate distribution shift", "Not collected; requires ethics-approved protocol"),
    ], font_size=8.1)

    doc.add_heading("3.7.4 Integration Acceptance Criteria", level=3)
    add_body(doc, "The component is accepted as end-to-end functional only when the class mapping is complete, all five prototype letters have deterministic mapping tests, the UI verdict and persisted attempt agree, the application identifies whether CNN or geometric fallback produced the verdict, and physical-device inference succeeds within a supervisor-approved latency threshold. The current implementation does not yet meet all these criteria.")

    doc.add_heading("3.8 Component 2 — Text-Difficulty Classification Method", level=2)
    doc.add_heading("3.8.1 Feature Engineering and Model", level=3)
    add_table(doc, ["Feature", "Implementation", "Limitation"], [
        ("Word count (x₁)", "Non-empty whitespace-separated tokens", "Sensitive to Sinhala tokenization and passage length"),
        ("Average word length (x₂)", "Mean Unicode character count per token", "Characters do not directly encode syllabic or morphological difficulty"),
        ("Average sentence length (x₃)", "Mean tokens per segment split at . ! ?", "Children's text may use punctuation inconsistently"),
    ])
    add_body(doc, "The implemented model calculates z = −4.6827 + 0.4839x₁ + 0.5542x₂ + 0.4839x₃ and p(Grade 2) = 1/(1 + e^(−z)). When p ≥ 0.50 the result is Grade 2; otherwise it is Grade 1. The final appendix should retain full coefficient precision from the Dart implementation.")

    doc.add_heading("3.8.2 Evaluation and Baselines", level=3)
    add_body(doc, "The model achieved 69.2% accuracy on its own 26 training samples. Since 17 of the 26 examples are Grade 2, an always-Grade-2 majority classifier achieves 65.4%. The current model therefore improves on that training baseline by only 3.8 percentage points, without generalization evidence. The correct interpretation is that the on-device classification pipeline works as a proof-of-concept; the current result does not validate a Sinhala readability measure.")
    add_body(doc, "Before a final result is reported, the corpus should be expanded and independently labelled by multiple Grade 1/2 educators. Evaluation should use source-grouped repeated stratified cross-validation when sample size allows, and report macro-F1, balanced accuracy, class-specific recall, confusion matrix and uncertainty. Baselines should include majority prediction, a transparent threshold rule and logistic regression. Feature ablation should test whether each selected feature contributes.")

    doc.add_heading("3.9 Application Integration and Data Flow", level=2)
    doc.add_picture(str(ASSETS / "system_architecture.png"), width=Inches(6.4))
    add_caption(doc, "Figure 3.2. ReadBuddy AI system architecture (author-generated).")
    add_body(doc, "The Flutter application provides grade-adaptive modules. Grade 1 emphasizes letters, tracing, recognition and simple words; Grade 2 emphasizes pillam, word construction, reading and comprehension. ReadingLevelEngine invokes the local text classifier for Grade 1/2 recommendations and falls back to authored tags when necessary. Authentication and Firestore persist user-authorized progress. The generative AI assistant is adult-facing and should not be included in performance claims for the two research components.")

    doc.add_heading("3.10 Evaluation Plan and Operationalization", level=2)
    add_table(doc, ["Research construct", "Operational measure", "Data source", "Objective"], [
        ("Reference letter recognition", "Accuracy, macro metrics, top-k, confusion and ECE", "Held-out/reference validation images", "RO4"),
        ("Mobile feasibility", "Model size, load success, median/p95 inference latency and crash-free scenarios", "Physical Android device logs", "RO3–RO4"),
        ("End-to-end correctness", "Expected Unicode = mapped prediction; confidence threshold; saved verdict agreement", "Automated mapping/service/widget tests", "RO3–RO4"),
        ("Text grade discrimination", "Macro-F1, balanced accuracy, confusion and baseline improvement", "Expanded expert-labelled Grade 1/2 corpus", "RO4"),
        ("Software quality", "Static-analysis findings, passing tests and defined functional cases", "Flutter toolchain and test reports", "RO3–RO4"),
        ("Educational effectiveness", "Learning outcomes and user experience", "Future ethics-approved field study", "Out of current evidence scope"),
    ], font_size=8.0)

    doc.add_heading("3.11 Project Management Methodology", level=2)
    add_body(doc, "An Agile/Kanban approach adapted to a single researcher is used. This description is more accurate than claiming full Scrum while one person simultaneously acts as Product Owner, Scrum Master and development team. Work items move through Backlog, Ready, In Progress, Verification and Done. Weekly supervisor reviews provide governance, while each research item has an evidence-based definition of done.")
    add_table(doc, ["Work item", "Definition of done"], [
        ("Literature source", "Original metadata verified; method, result, limitation and relevance recorded."),
        ("Model experiment", "Executable notebook, data version, seed, environment, metrics and model hash archived."),
        ("Integration feature", "Functional test passes on Android; screenshot/log stored; failure and fallback paths tested."),
        ("Thesis claim", "Linked to evidence/citation; split terminology correct; limitation stated."),
        ("Supervisor action", "Feedback recorded, change made and confirmation documented."),
    ])

    doc.add_heading("3.12 Project Timeline", level=2)
    add_table(doc, ["Period", "Activity", "Deliverable/status"], [
        ("Completed", "Problem refinement, application implementation, initial model training/integration", "Grade 1–2 prototype and preliminary metrics"),
        ("Week 1", "Supervisor review of revised scope, RQ, objectives and survey treatment", "Signed feedback matrix"),
        ("Week 2", "Recover exact CNN notebook; create dataset/model manifests and SHA-256 records", "Reproducible model evidence"),
        ("Week 3", "Implement numeric-ID-to-Unicode mapping and tests for five letters", "End-to-end tracing acceptance"),
        ("Week 4", "Fix analyzer warnings/deprecation and replace stale widget test", "Clean or justified static/test report"),
        ("Weeks 5–6", "Expand and independently label balanced Grade 1/2 text corpus", "Versioned corpus and annotation agreement"),
        ("Week 7", "Run baseline/cross-validation/error analysis and physical-device latency tests", "Results evidence pack"),
        ("Week 8", "Draft Results and Discussion chapters after supervisor approval", "Chapters 4–5 draft"),
    ], font_size=8.4)

    doc.add_heading("3.13 Ethical Considerations", level=2)
    add_bullets(doc, [
        "The current thesis does not claim a completed child-participant effectiveness study.",
        "Any future work with minors requires institutional approval, school authorization, guardian consent and age-appropriate child assent before collection.",
        "The legal/ethical status of the preliminary teacher responses and associated consent must be confirmed before treating them as formal primary research.",
        "Data collection must be minimized. Raw handwriting should not be retained by default; where retention is necessary, purpose, encryption, access, retention and deletion must be documented.",
        "Student identities should be replaced by pseudonymous identifiers and separated from research exports.",
        "Classifier outputs must not be presented as diagnoses of dyslexia, intelligence or learning ability.",
        "Feedback should be supportive, permit retrying and disclose when a fallback rather than the CNN was used.",
        "Generated adult guidance must be treated as assistance, not authoritative educational or clinical advice.",
    ])

    doc.add_heading("3.14 Reliability, Validity and Threats", level=2)
    add_table(doc, ["Area", "Threat", "Mitigation / reporting decision"], [
        ("Construct validity", "Classifying a glyph is not the same as evaluating pedagogically correct stroke formation.", "Use ‘letter classification,’ not ‘stroke-quality diagnosis’; develop verified paths and human rubric later."),
        ("Text construct validity", "Length features omit vocabulary, morphology, cohesion and reader knowledge.", "Treat model as proof-of-concept; add Sinhala-specific features and expert labels."),
        ("Internal validity", "Leakage, preprocessing mismatch or repeated validation tuning may inflate metrics.", "Freeze partitions, record seeds, group by source/writer and preserve exact preprocessing."),
        ("External validity", "Reference handwriting differs from Grade 1 finger traces; 26 authored texts represent one app.", "Do not generalize to classrooms; conduct later multi-site field evaluation."),
        ("Conclusion validity", "Small imbalanced text corpus makes accuracy unstable.", "Use baselines, macro measures and confidence intervals only after expansion."),
        ("Reliability", "Shipped model cannot currently be regenerated from the visible notebook.", "Recover notebook/environment and hash all artifacts."),
        ("Integration validity", "Numeric labels cannot match Unicode; geometric fallback can mask model failure.", "Implement mapping tests and log inference source/model version."),
        ("Survey validity", "Two respondents and missing raw/ethics evidence.", "Report counts as preliminary input; no population percentages or causal conclusions."),
    ], font_size=7.9)

    doc.add_heading("3.15 Chapter Summary", level=2)
    add_body(doc, "Chapter 3 established a pragmatist, deductive-with-inductive-iteration design-science methodology. It defined literature, preliminary requirement, image, text and software evidence; specified the CNN and logistic workflows; mapped evaluation to the objectives; and documented project management, ethics and validity controls. The methodology makes a clear distinction between available model evidence and uncompleted field, integration and software-quality work. The following administrative progress section records readiness for future Results and Discussion chapters without adding those chapters to this submission.")
    doc.add_page_break()


def progress_and_references(doc: Document) -> None:
    doc.add_heading("Research Progress toward Results and Discussion", level=1)
    add_callout(doc, "Administrative status section — not Chapter 4 or Chapter 5", "This section satisfies the interim progress-update requirement. It must not be cited as a completed Results/Discussion chapter, and it does not authorize claims beyond the evidence shown.", PALE_ORANGE)

    doc.add_heading("A. Results Evidence Currently Available", level=2)
    doc.add_picture(str(ASSETS / "cnn_metrics_progress.png"), width=Inches(6.35))
    add_caption(doc, "Figure P.1. CNN metrics currently available for the future Results chapter.")
    add_table(doc, ["Evidence", "Current finding", "Correct interpretation"], [
        ("CNN validation", "94.04% accuracy; macro precision 0.944; recall/F1 0.940; top-2 96.35%; top-3 97.12%; ECE 0.084", "Strong reference-dataset evidence; not child-field accuracy."),
        ("Repeatability", "Two runs around 94.10% and 94.04% validation accuracy", "Promising stability; exact seeds/environment must be recovered."),
        ("Text classifier", "69.2% training accuracy on 26 samples", "Proof-of-concept only; majority training baseline is 65.4%."),
        ("App integration", "TFLite service and threshold-based verdict code exist", "Not end-to-end trustworthy until label mapping tests pass."),
        ("Static analysis", "10 findings", "Engineering cleanup remains before claiming clean code quality."),
        ("Automated tests", "Stale default counter test fails", "Test suite coverage is currently inadequate and must be replaced."),
    ], font_size=8.2)

    confusion = EXTRACTED / "eebc8f07dcc9e5564ae940a1c535fbc5ea7b5a36.png"
    calibration = EXTRACTED / "50b61ea106e12610b1305730b6245fce22aa92b1.png"
    if confusion.exists():
        doc.add_picture(str(confusion), width=Inches(6.0))
        add_caption(doc, "Figure P.2. Existing 454-class validation confusion matrix from the supplied research-components document. Verify against the exact shipped model before final publication.")
    if calibration.exists():
        doc.add_picture(str(calibration), width=Inches(4.8))
        add_caption(doc, "Figure P.3. Existing validation reliability diagram (ECE = 0.084) from the supplied research-components document.")

    doc.add_heading("B. Discussion Themes Already Supported", level=2)
    add_bullets(doc, [
        "Dataset performance versus field validity: reference accuracy can be high while real child traces remain an untested distribution.",
        "Model quality versus product correctness: accurate logits do not create correct feedback if numeric labels are not mapped to Unicode.",
        "Interpretability versus capacity: the text model is easy to explain but too weakly evidenced for a production readability claim.",
        "Low-resource prioritization: additional expert-labelled Sinhala data is more valuable now than adopting a larger model.",
        "Offline intelligence versus cloud services: on-device inference supports connectivity and privacy goals, while adult AI services remain separate.",
        "Research integrity: limitations, failed tests and incomplete work should guide future actions rather than be hidden.",
    ])

    doc.add_heading("C. Required Work before Writing Final Results and Discussion", level=2)
    add_numbered(doc, [
        "Obtain supervisor confirmation of the Grade 1–2 scope and whether the preliminary teacher input may be retained as formal primary data.",
        "Recover and execute the exact notebook that produced the shipped TFLite model; archive dataset/environment/model hashes.",
        "Implement and test the 454-class numeric-ID-to-Unicode mapping, beginning with all five exposed tracing letters.",
        "Replace approximate unsupported claims with outputs produced by the exact final model and frozen data split.",
        "Expand the Grade 1/2 text corpus and obtain independent educator annotations before cross-validated evaluation.",
        "Resolve static-analysis findings and replace the stale widget test with classifier, mapping, reading-level and critical-widget tests.",
        "Measure TFLite model load time, median/p95 inference latency and memory on a physical target Android device.",
        "Proceed to child/teacher/parent field evaluation only after documented ethics approval and consent procedures.",
    ])

    doc.add_heading("Supervisor Discussion and Confirmation Record", level=1)
    add_table(doc, ["Discussion point", "Supervisor decision / feedback", "Student action"], [
        ("Confirm final target: Grade 1 and Grade 2 only", "", ""),
        ("Confirm single research question and four objectives", "", ""),
        ("Confirm treatment of two-teacher preliminary survey", "", ""),
        ("Confirm CNN validation terminology and evidence", "", ""),
        ("Confirm text classifier is presented as proof-of-concept", "", ""),
        ("Confirm progress section format and permission to proceed to Results/Discussion", "", ""),
    ], font_size=8.5)
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(18)
    p.add_run("Supervisor name: ______________________________   Signature: ____________________   Date: ____________")
    p = doc.add_paragraph()
    p.add_run("Student signature: ______________________________   Date: ____________________")
    doc.add_page_break()

    doc.add_heading("References — IEEE Style", level=1)
    refs = [
        '[1] UNICEF Sri Lanka, “MOE and UNICEF spearhead national initiative to recover lost learning for 1.6 million primary school children across Sri Lanka,” Aug. 16, 2023. [Online]. Available: https://www.unicef.org/srilanka/press-releases/moe-and-unicef-spearhead-national-initiative-recover-lost-learning-16-million. [Accessed: Aug. 19, 2026].',
        '[2] World Bank, “Sri Lanka Learning Poverty Brief,” version 2, Apr. 2024. [Online]. Available: https://documents1.worldbank.org/curated/en/099090524113181787/pdf/P1792091cc4ce70d01bda7185ee313a94c7.pdf. [Accessed: Aug. 19, 2026].',
        '[3] Ministry of Education, Higher Education and Vocational Education, Sri Lanka, “Transform Education: Transform Sri Lanka,” 2025. [Online]. Available: https://moe.gov.lk/wp-content/uploads/2025/07/Education-Reforms-Sri-Lanka-PPT.pdf. [Accessed: Aug. 19, 2026].',
        '[4] G. F. Bautista, P. Ghesquière, and J. Torbeyns, “Stimulating preschoolers’ early literacy development using educational technology: A systematic literature review,” Int. J. Child-Comput. Interact., vol. 39, Art. no. 100620, Mar. 2024, doi: 10.1016/j.ijcci.2023.100620.',
        '[5] P. B. Gough and W. E. Tunmer, “Decoding, reading, and reading disability,” Remedial Spec. Educ., vol. 7, no. 1, pp. 6–10, 1986, doi: 10.1177/074193258600700104.',
        '[6] J. Mariyathas, V. Shanmuganathan, and B. Kuhaneswaran, “Sinhala handwritten character recognition using convolutional neural network,” in Proc. 5th Int. Conf. Inf. Technol. Res. (ICITR), 2020, pp. 1–6, doi: 10.1109/ICITR51448.2020.9310914.',
        '[7] W. V. S. K. Wasalthilake and T. Thangathurai, “Improved handwritten character recognition for Sinhala language based on convolutional neural networks,” in Proc. IEEE 7th Int. Conf. Convergence Technol. (I2CT), 2022, doi: 10.1109/I2CT54291.2022.9824233.',
        '[8] M. L. Karunarathne, C. P. Wijesiriwardana, K. M. I. Nishantha, and W. G. C. W. Kumara, “Efficiency and accuracy in Sinhala handwritten character recognition: A Gabor-initialized CNN perspective,” Sri Lankan J. Technol., vol. 5, no. 1, pp. 13–24, Jun. 2024. [Online]. Available: https://seu.ac.lk/sljot/publication/v5n1/003.pdf.',
        '[9] J. M. Imperial and E. Kochmar, “BasahaCorpus: An expanded linguistic resource for readability assessment in Central Philippine languages,” in Proc. 2023 Conf. Empirical Methods Natural Language Process. (EMNLP), Singapore, 2023, pp. 6302–6309, doi: 10.18653/v1/2023.emnlp-main.388.',
        '[10] J. M. Imperial and E. Kochmar, “Automatic readability assessment for closely related languages,” in Findings Assoc. Comput. Linguistics: ACL 2023, Toronto, Canada, 2023, pp. 5371–5386, doi: 10.18653/v1/2023.findings-acl.331.',
        '[11] T. Naous, M. J. Ryan, A. Lavrouk, M. Chandra, and W. Xu, “ReadMe++: Benchmarking multilingual language models for multi-domain readability assessment,” in Proc. 2024 Conf. Empirical Methods Natural Language Process. (EMNLP), Miami, FL, USA, 2024, pp. 12230–12266, doi: 10.18653/v1/2024.emnlp-main.682.',
        '[12] F. Liu, T. Jin, and J. S. Y. Lee, “Automatic readability assessment for sentences: Neural, hybrid and large language models,” Lang. Resources Eval., vol. 59, pp. 2265–2296, 2025, doi: 10.1007/s10579-024-09800-5.',
        '[13] D. Kazakov, S. Minkov, R. Margova, I. Temnikova, and I. Emanuilov, “Towards creating a Bulgarian readability index,” in Proc. 1st Workshop Advancing NLP for Low-Resource Languages, Varna, Bulgaria, 2025, pp. 192–200, doi: 10.26615/978-954-452-100-4-018.',
        '[14] X. Yang, J. Yang, and X. Li, “Chinese automatic readability assessment using adaptive pre-training and linguistic feature fusion,” in Proc. 31st Int. Conf. Comput. Linguistics (COLING), Abu Dhabi, UAE, 2025, pp. 9013–9024. [Online]. Available: https://aclanthology.org/2025.coling-main.605/.',
        '[15] I. Pilán, S. Vajjala, and E. Volodina, “A readable read: Automatic assessment of language learning materials based on linguistic complexity,” Int. J. Comput. Linguistics Appl., vol. 7, no. 1, pp. 143–159, 2016.',
        '[16] J. Lee et al., “On-device neural net inference with mobile GPUs,” in Workshop Efficient Deep Learning for Computer Vision, CVPR, 2019. [Online]. Available: https://arxiv.org/abs/1907.01989.',
        '[17] C. Guo, G. Pleiss, Y. Sun, and K. Q. Weinberger, “On calibration of modern neural networks,” in Proc. 34th Int. Conf. Mach. Learn., vol. 70, 2017, pp. 1321–1330.',
        '[18] R. R. Selvaraju, M. Cogswell, A. Das, R. Vedantam, D. Parikh, and D. Batra, “Grad-CAM: Visual explanations from deep networks via gradient-based localization,” in Proc. IEEE Int. Conf. Comput. Vis. (ICCV), 2017, pp. 618–626.',
        '[19] K. Peffers, T. Tuunanen, M. A. Rothenberger, and S. Chatterjee, “A design science research methodology for information systems research,” J. Manage. Inf. Syst., vol. 24, no. 3, pp. 45–77, 2007, doi: 10.2753/MIS0742-1222240302.',
        '[20] J. W. Creswell and J. D. Creswell, Research Design: Qualitative, Quantitative, and Mixed Methods Approaches, 5th ed. Thousand Oaks, CA, USA: SAGE, 2018.',
        '[21] F. Pedregosa et al., “Scikit-learn: Machine learning in Python,” J. Mach. Learn. Res., vol. 12, pp. 2825–2830, 2011.',
        '[22] S. L. Amal, “Sinhala Letter and Modifications,” Kaggle dataset, 2020. [Online]. Available: https://www.kaggle.com/datasets/sathiralamal/sinhala-letter-454. [Accessed: Aug. 19, 2026].',
    ]
    for ref in refs:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Cm(0.8)
        p.paragraph_format.first_line_indent = Cm(-0.8)
        p.paragraph_format.line_spacing = 1.0
        p.paragraph_format.space_after = Pt(5)
        p.add_run(ref)

    doc.add_heading("Final Pre-Submission Checklist", level=1)
    add_bullets(doc, [
        "Supervisor has confirmed the Grade 1–2 scope and signed the discussion record.",
        "Institutional cover-page, declaration, supervisor name and formatting requirements have been applied.",
        "Raw teacher responses, consent and ethics evidence are attached—or survey claims are explicitly retained only as informal requirements input.",
        "All CNN metrics are reproduced from the exact shipped model and frozen split.",
        "Numeric label-to-Unicode mapping and five-letter end-to-end tests pass.",
        "Static-analysis findings are corrected or justified, and the stale widget test is replaced.",
        "The text classifier is not described as validated until the corpus and evaluation are improved.",
        "IEEE citations appear in first-appearance order and match the reference list.",
        "No sentence claims proven classroom effectiveness, clinical diagnosis or Grade 3 support.",
        "Results and Discussion chapters are started only after the supervisor approves the updated evidence plan.",
    ])


def build() -> Path:
    OUT.mkdir(parents=True, exist_ok=True)
    make_diagrams()
    make_additional_diagrams()
    doc = setup_document()
    title_page(doc)
    front_matter(doc)
    chapter_one(doc)
    chapter_two(doc)
    chapter_three(doc)
    progress_and_references(doc)
    doc.save(DOCX)
    print(DOCX)
    return DOCX


if __name__ == "__main__":
    build()
