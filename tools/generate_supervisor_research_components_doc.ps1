param(
  [string]$OutputPath = (Join-Path (Get-Location) 'NenaPotha_AI_Research_Components_Supervisor_Guide.docx')
)

$ErrorActionPreference = 'Stop'

$wdAlignLeft = 0
$wdAlignCenter = 1
$wdAlignJustify = 3
$wdCollapseEnd = 0
$wdPageBreak = 7
$wdFormatDocumentDefault = 16
$wdStyleNormal = -1
$wdStyleHeading1 = -2
$wdStyleHeading2 = -3
$wdStyleTitle = -63
$wdStyleSubtitle = -75

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

try {
  $document = $word.Documents.Add()
  $selection = $word.Selection

  $section = $document.Sections.Item(1)
  $section.PageSetup.PaperSize = 7
  $section.PageSetup.TopMargin = $word.CentimetersToPoints(2.2)
  $section.PageSetup.BottomMargin = $word.CentimetersToPoints(2.0)
  $section.PageSetup.LeftMargin = $word.CentimetersToPoints(2.2)
  $section.PageSetup.RightMargin = $word.CentimetersToPoints(2.2)

  $normal = $document.Styles.Item($wdStyleNormal)
  $normal.Font.Name = 'Aptos'
  $normal.Font.Size = 10.5
  $normal.ParagraphFormat.SpaceAfter = 6
  $normal.ParagraphFormat.LineSpacingRule = 1

  function Add-Text {
    param(
      [string]$Text,
      [int]$Style = $wdStyleNormal,
      [int]$Alignment = $wdAlignLeft,
      [bool]$Bold = $false,
      [double]$Size = 0,
      [double]$SpaceAfter = 6
    )
    $selection.Style = $document.Styles.Item($Style)
    $selection.ParagraphFormat.Alignment = $Alignment
    $selection.ParagraphFormat.SpaceAfter = $SpaceAfter
    $selection.Font.Bold = [int]$Bold
    if ($Size -gt 0) { $selection.Font.Size = $Size }
    $selection.TypeText($Text)
    $selection.TypeParagraph()
    $selection.Font.Bold = 0
    $selection.Font.Size = 10.5
    $selection.ParagraphFormat.Alignment = $wdAlignLeft
  }

  function Add-Body {
    param([string]$Text)
    Add-Text -Text $Text -Style $wdStyleNormal -Alignment $wdAlignJustify -SpaceAfter 8
  }

  function Add-Bullet {
    param([string]$Text)
    Add-Text -Text ("• " + $Text) -Style $wdStyleNormal -Alignment $wdAlignLeft -SpaceAfter 4
  }

  function Add-Table {
    param(
      [string[]]$Headers,
      [object[]]$Rows,
      [double]$FontSize = 8.5
    )
    $table = $document.Tables.Add($selection.Range, $Rows.Count + 1, $Headers.Count)
    $table.Style = 'Table Grid'
    $table.AllowAutoFit = $true
    $table.AutoFitBehavior(2)
    $table.Rows.Item(1).HeadingFormat = -1
    for ($column = 1; $column -le $Headers.Count; $column++) {
      $cell = $table.Cell(1, $column)
      $cell.Range.Text = $Headers[$column - 1]
      $cell.Range.Bold = 1
      $cell.Range.Font.Color = 16777215
      $cell.Shading.BackgroundPatternColor = 11162880
      $cell.VerticalAlignment = 1
    }
    for ($row = 0; $row -lt $Rows.Count; $row++) {
      for ($column = 0; $column -lt $Headers.Count; $column++) {
        $cell = $table.Cell($row + 2, $column + 1)
        $cell.Range.Text = [string]$Rows[$row][$column]
        $cell.VerticalAlignment = 0
        if (($row % 2) -eq 1) {
          $cell.Shading.BackgroundPatternColor = 15790320
        }
      }
    }
    $table.Range.Font.Name = 'Aptos'
    $table.Range.Font.Size = $FontSize
    $table.Range.ParagraphFormat.SpaceAfter = 2
    $selection.SetRange($table.Range.End, $table.Range.End)
    $selection.TypeParagraph()
  }

  function Add-PageBreak {
    $selection.InsertBreak($wdPageBreak)
  }

  $logoPath = Join-Path (Get-Location) 'assets\images\branding\nenapotha_logo.png'
  if (Test-Path -LiteralPath $logoPath) {
    $selection.ParagraphFormat.Alignment = $wdAlignCenter
    $logo = $selection.InlineShapes.AddPicture($logoPath)
    $logo.LockAspectRatio = -1
    $logo.Width = $word.CentimetersToPoints(3.3)
    $selection.TypeParagraph()
  }

  Add-Text -Text 'NenaPotha AI' -Style $wdStyleTitle -Alignment $wdAlignCenter -Bold $true -Size 30 -SpaceAfter 4
  Add-Text -Text 'Research Components and Feature Justification' -Style $wdStyleSubtitle -Alignment $wdAlignCenter -Size 18 -SpaceAfter 10
  Add-Text -Text 'Supervisor Presentation and Discussion Guide' -Style $wdStyleNormal -Alignment $wdAlignCenter -Bold $true -Size 13 -SpaceAfter 24
  Add-Text -Text 'Scope: Grade 1 and Grade 2 Early-Literacy Learning' -Style $wdStyleNormal -Alignment $wdAlignCenter -Size 11 -SpaceAfter 6
  Add-Text -Text 'Student Name: ______________________________' -Style $wdStyleNormal -Alignment $wdAlignCenter -Size 11 -SpaceAfter 6
  Add-Text -Text 'Registration Number: _______________________' -Style $wdStyleNormal -Alignment $wdAlignCenter -Size 11 -SpaceAfter 6
  Add-Text -Text 'Date: 23 September 2026' -Style $wdStyleNormal -Alignment $wdAlignCenter -Size 11 -SpaceAfter 12
  Add-Text -Text 'This document separates the core research contributions from supporting application features and states the current evidence and limitations honestly.' -Style $wdStyleNormal -Alignment $wdAlignCenter -Size 10 -SpaceAfter 6

  Add-PageBreak

  Add-Text -Text '1. Executive Summary' -Style $wdStyleHeading1 -Bold $true -Size 17
  Add-Body 'NenaPotha AI is a bilingual, child-friendly mobile learning system designed to support early literacy among Grade 1 and Grade 2 learners. It combines Sinhala handwritten-letter recognition, grade-level text-difficulty classification, hybrid letter-tracing evaluation, structured learning activities, and progress-based personalised recommendations. The project is not presented as a collection of unrelated application features. Each feature responds to a defined educational or technical problem and contributes either directly to the research investigation or indirectly to the usability and delivery of the research components.'
  Add-Body 'The system is intentionally designed as a low-cost solution. Core recognition and recommendation functions operate locally where practical, reducing dependence on paid services and continuous internet access. This is important for real-world use in Sri Lankan homes and schools where devices, connectivity, and budgets may be limited.'

  Add-Text -Text '2. Research Problem' -Style $wdStyleHeading1 -Bold $true -Size 17
  Add-Body 'Young learners do not all develop letter knowledge, handwriting, vocabulary, and reading comprehension at the same rate. A conventional learning application may present the same content to every learner, provide little immediate feedback on handwriting, and give parents or teachers limited evidence about repeated weaknesses. Sinhala-focused intelligent learning support is also less widely available than support for English.'
  Add-Body 'The project therefore investigates how a bilingual mobile system can provide age-appropriate literacy activities, automatically assess selected learning evidence, record progress, identify weak areas, and recommend suitable next practice for Grade 1 and Grade 2 learners.'

  Add-Text -Text '3. Research Aim' -Style $wdStyleHeading1 -Bold $true -Size 17
  Add-Body 'To design, implement, and evaluate a bilingual AI-assisted mobile learning system that supports Grade 1 and Grade 2 early-literacy development through Sinhala handwritten-letter recognition, level-appropriate text classification, hybrid tracing feedback, structured practice, and progress-based personalised guidance.'

  Add-Text -Text '4. Proposed Working Research Question' -Style $wdStyleHeading1 -Bold $true -Size 17
  Add-Body 'How can an AI-assisted bilingual mobile application support and evaluate early-literacy development among Grade 1 and Grade 2 learners through Sinhala handwritten-letter recognition, grade-appropriate text classification, structured practice, and progress-based personalised guidance?'
  Add-Body 'Note: The final wording of the research question must remain consistent with the version approved by the supervisor and stated in Chapter 1.'

  Add-PageBreak

  Add-Text -Text '5. Core Research Components' -Style $wdStyleHeading1 -Bold $true -Size 17
  Add-Body 'The following four components form the central research contribution. Supporting features such as stories, text-to-speech, navigation, and visual design enable these components but should not be described as independent AI models.'

  Add-Text -Text '5.1 Sinhala Handwritten-Letter Recognition' -Style $wdStyleHeading2 -Bold $true -Size 14
  Add-Body 'A custom Convolutional Neural Network (CNN) recognises supported Sinhala handwritten letters. The purpose is to give a learner immediate evidence about the identity of the letter written during practice.'
  Add-Bullet 'Input: an image generated from the learner’s handwritten strokes.'
  Add-Bullet 'Processing: local CNN inference using the trained TensorFlow Lite model.'
  Add-Bullet 'Output: predicted class, mapped Sinhala Unicode letter, model confidence, and inference information.'
  Add-Bullet 'Research reason: manual checking is not always immediately available. Automatic recognition can provide prompt feedback and measurable evidence.'
  Add-Bullet 'Current evidence: the custom CNN achieved 88.61% held-out test accuracy.'
  Add-Bullet 'Boundary: this result does not mean the model is 100% correct, and confidence must not be described as handwriting similarity.'

  Add-Text -Text '5.2 Grade 1/Grade 2 Text-Difficulty Classification' -Style $wdStyleHeading2 -Bold $true -Size 14
  Add-Body 'The text classifier investigates whether Sinhala reading material can be categorised according to Grade 1 or Grade 2 difficulty. It supports the selection of content that is neither unnecessarily easy nor excessively difficult for the learner.'
  Add-Bullet 'Input: a Sinhala text sample.'
  Add-Bullet 'Output: predicted Grade 1 or Grade 2 difficulty.'
  Add-Bullet 'Research reason: age-inappropriate material can reduce comprehension, confidence, and engagement.'
  Add-Bullet 'Current evidence: approximately 69.2% training accuracy from 26 labelled samples.'
  Add-Bullet 'Boundary: this is a proof-of-concept, not a production-grade classifier. The current result is training accuracy and must not be reported as test accuracy.'
  Add-Bullet 'Future requirement: a substantially larger expert-labelled dataset and a genuinely independent evaluation set.'

  Add-Text -Text '5.3 Hybrid Letter-Tracing Evaluation' -Style $wdStyleHeading2 -Bold $true -Size 14
  Add-Body 'The tracing evaluator separates two different questions: “Which letter does the handwriting resemble?” and “How closely does the shape follow the standard glyph?” CNN classification answers the first question, while a standard-glyph shape-comparison algorithm answers the second. Combining them provides more meaningful feedback than displaying CNN confidence as if it were shape similarity.'
  Add-Bullet 'Input: the learner’s recorded stroke points.'
  Add-Bullet 'Output: shape-similarity percentage, CNN identity evidence where supported, and a pass/fail decision.'
  Add-Bullet 'Research reason: a classifier can be confident about a class even when the handwriting quality is poor. Shape comparison directly evaluates tracing quality.'
  Add-Bullet 'Reliability control: the light guide is visual only and is never included in the evaluated learner image.'
  Add-Bullet 'Consistency control: showing or hiding the guide cannot change the result for the same untouched stroke.'
  Add-Bullet 'Boundary: this hybrid rule requires further validation with samples written by real children and reviewed by teachers.'

  Add-Text -Text '5.4 Progress-Based Personalised Learning' -Style $wdStyleHeading2 -Bold $true -Size 14
  Add-Body 'The progress component records learning attempts and analyses task scores, tracing similarity, repeated errors, activity completion, and weak items. A transparent rule-based Smart Learning Coach then recommends a suitable next activity.'
  Add-Bullet 'Input: stored task attempts and learner performance summaries.'
  Add-Bullet 'Output: weak-area identification, a short learning plan, and recommended next practice.'
  Add-Bullet 'Research reason: learners need different levels of repetition and support. Recommendations should follow recorded evidence rather than random suggestions.'
  Add-Bullet 'Design reason: the rule-based approach is free, explainable, predictable, and suitable for offline use.'
  Add-Bullet 'Boundary: the Smart Learning Coach is an adaptive decision component. It must not be falsely presented as a newly trained generative-AI model.'

  Add-PageBreak

  Add-Text -Text '6. Research Component Summary' -Style $wdStyleHeading1 -Bold $true -Size 17
  $componentRows = @(
    @('1. CNN Letter Recognition', 'Handwritten stroke image', 'Predicted Sinhala letter and confidence', 'Immediate automated identity feedback', '88.61% held-out test accuracy'),
    @('2. Text-Difficulty Classifier', 'Sinhala reading text', 'Grade 1 or Grade 2', 'Select level-appropriate reading content', 'Proof-of-concept, 26 samples, ~69.2% training accuracy'),
    @('3. Hybrid Tracing Evaluator', 'Learner stroke points', 'Shape score plus identity evidence', 'Assess both shape quality and letter identity', 'Functional consistency verified. Child and teacher validation required'),
    @('4. Personalised Learning', 'Saved performance history', 'Weak areas and next activity', 'Evidence-based adaptive practice', 'Transparent offline rule-based logic')
  )
  Add-Table -Headers @('Component', 'Input', 'Output', 'Purpose', 'Current Evidence/Status') -Rows $componentRows -FontSize 8

  Add-Text -Text '7. Feature-by-Feature Justification' -Style $wdStyleHeading1 -Bold $true -Size 17
  $featureRows = @(
    @('Sinhala letter lessons', 'Connect each letter with its sound, picture, and example word to support early letter knowledge.'),
    @('English letter lessons', 'Support both Sinhala- and English-medium learners and extend the usefulness of the application.'),
    @('Separate interface and learning languages', 'Allow an English-interface learner to study Sinhala and a Sinhala-interface learner to study English.'),
    @('Letter tracing', 'Develop letter formation and visual-motor practice rather than only passive recognition.'),
    @('CNN recognition', 'Provide immediate identity feedback without requiring a teacher to inspect every attempt.'),
    @('Shape-similarity percentage', 'Measure closeness to the standard glyph. CNN confidence is not a similarity percentage.'),
    @('Show/hide tracing guide', 'Move from supported tracing to independent recall while keeping assessment input unchanged.'),
    @('Grade 1 staged tasks', 'Progress from simple visual recognition to picture-letter association and mastery tasks.'),
    @('Grade 2 advanced tasks', 'Increase cognitive demand through pillam, words, sentences, and reading comprehension.'),
    @('70% sequential unlocking', 'Require minimum mastery of prerequisite skills before advancing to a harder level.'),
    @('Stories and comprehension', 'Measure meaning-making and reading comprehension, not only letter or word recognition.'),
    @('Text-to-speech', 'Support sound-letter association, pronunciation, and independent use by young learners.'),
    @('Progress tracking', 'Create longitudinal evidence from attempts, scores, similarities, and repeated mistakes.'),
    @('Smart Learning Coach', 'Convert recorded evidence into understandable next-step recommendations.'),
    @('Parent/teacher progress view', 'Help adults identify weak areas and provide targeted support.'),
    @('Child-friendly interface', 'Use large controls, clear pictures, simple wording, and colour to reduce cognitive and interaction barriers.'),
    @('Local/offline processing', 'Reduce cost, latency, paid-API dependency, and continuous-internet requirements.')
  )
  Add-Table -Headers @('Feature', 'Reason for Inclusion') -Rows $featureRows -FontSize 8.5

  Add-PageBreak

  Add-Text -Text '8. What Makes This a Research Project?' -Style $wdStyleHeading1 -Bold $true -Size 17
  Add-Body 'The project becomes research through its problem definition, research question, designed intervention, measurable components, evaluation evidence, and critical interpretation—not merely because it contains many features.'
  Add-Bullet 'Defined educational problem: limited personalised and immediate early-literacy support, particularly for Sinhala.'
  Add-Bullet 'Proposed intervention: an integrated bilingual AI-assisted learning system for Grade 1 and Grade 2.'
  Add-Bullet 'Technical investigation: CNN recognition, grade-level classification, hybrid tracing evaluation, and progress-driven adaptation.'
  Add-Bullet 'Measurable variables: model accuracy, shape similarity, task performance, completion, repeated mistakes, weak items, and usability.'
  Add-Bullet 'Evaluation: model testing, functional testing, consistency testing, and future teacher/child usability evaluation.'
  Add-Bullet 'Contribution: integration of explainable, low-cost components into one child-centred literacy workflow.'

  Add-Text -Text '9. Core Research vs Supporting Features' -Style $wdStyleHeading1 -Bold $true -Size 17
  $boundaryRows = @(
    @('Core research components', 'CNN letter recognition, Grade 1/2 text classifier, hybrid tracing assessment, and progress-based personalised recommendation.'),
    @('Supporting educational features', 'Letter lessons, stories, comprehension questions, staged tasks, and mastery progression.'),
    @('Supporting usability features', 'Bilingual interface, learning-language selector, text-to-speech, pictures, navigation, colours, and large controls.'),
    @('Infrastructure', 'Authentication, cloud data storage where used, local persistence, model loading, and activity-history storage.')
  )
  Add-Table -Headers @('Category', 'Included Elements') -Rows $boundaryRows -FontSize 9
  Add-Body 'Important defence statement: Not every application feature is claimed as a separate research contribution. Supporting features deliver the research intervention safely and meaningfully, while the four core components are the principal technical investigation.'

  Add-Text -Text '10. Evidence and Honest Limitations' -Style $wdStyleHeading1 -Bold $true -Size 17
  $evidenceRows = @(
    @('Custom CNN', '88.61% held-out test accuracy', 'Useful but imperfect. Child handwriting may differ from the training distribution.'),
    @('Text classifier', '26 labelled samples, ~69.2% training accuracy', 'Proof-of-concept only. No production claim and no “test accuracy” claim.'),
    @('Grade scope', 'Grade 1 and Grade 2', 'Grade 3 excluded because available data were insufficient for defensible modelling.'),
    @('Tracing evaluator', 'Functional and consistency testing', 'Needs expert-labelled child-writing samples for educational validation.'),
    @('Personalisation', 'Rule-based use of recorded task evidence', 'Needs longitudinal classroom/user evaluation to quantify learning impact.'),
    @('Current testing', 'Static analysis, automated tests, and emulator validation', 'Software correctness does not by itself prove educational effectiveness.')
  )
  Add-Table -Headers @('Area', 'Current Evidence', 'Correct Interpretation / Limitation') -Rows $evidenceRows -FontSize 8.5

  Add-PageBreak

  Add-Text -Text '11. Sixty-Second Supervisor Explanation' -Style $wdStyleHeading1 -Bold $true -Size 17
  Add-Body '“NenaPotha AI is a bilingual early-literacy support system for Grade 1 and Grade 2 learners. It is not a collection of random features. My research has four core components. First, a custom CNN recognises supported Sinhala handwritten letters and achieved 88.61% held-out test accuracy. Second, a proof-of-concept text classifier investigates Grade 1 and Grade 2 reading difficulty, although its current 26-sample dataset is too small for a production claim. Third, the hybrid tracing evaluator separates CNN identity confidence from actual standard-glyph shape similarity. Fourth, the progress component analyses recorded attempts and provides transparent, personalised next-step recommendations. Stories, text-to-speech, staged tasks, bilingual controls, and the child-friendly UI are supporting features that deliver these research components in a practical learning environment.”'

  Add-Text -Text '12. Likely Supervisor Questions and Strong Answers' -Style $wdStyleHeading1 -Bold $true -Size 17
  $qaRows = @(
    @('What are your research components?', 'The custom Sinhala letter CNN, Grade 1/2 text-difficulty classifier, hybrid tracing evaluator, and progress-based personalised learning component.'),
    @('Why use a CNN?', 'Images contain spatial patterns such as curves and strokes. A CNN learns these local visual features and is therefore suitable for handwritten-character classification.'),
    @('Why not use CNN confidence as the tracing score?', 'Confidence estimates belief in a predicted class. It does not measure geometric similarity to the standard letter. Therefore, identity and shape are evaluated separately.'),
    @('Why include guide visibility?', 'It supports scaffolding: children first trace with guidance and later practise from memory. The guide never enters the evaluation image.'),
    @('Why only Grade 1 and Grade 2?', 'The scope follows the defensible data available. Grade 3 data were insufficient, so including it would produce unreliable claims.'),
    @('Is the text classifier production-ready?', 'No. It is explicitly a proof-of-concept based on 26 labelled samples. A larger expert-labelled dataset is required.'),
    @('Is the Smart Learning Coach generative AI?', 'No. It is a transparent rule-based adaptive component that uses recorded learner evidence. This makes it predictable, free, and explainable.'),
    @('What is novel?', 'The contribution is the integrated bilingual workflow combining local Sinhala handwriting recognition, honest shape-based tracing feedback, level-oriented content support, and evidence-based personalisation.'),
    @('How will you evaluate educational value?', 'Through model metrics, software/consistency testing, task-performance analysis, and—subject to approval—teacher and child usability or pilot evaluation.'),
    @('Why is the UI part important?', 'Young learners cannot benefit from an accurate model if controls are confusing. Large targets, pictures, simple language, and limited cognitive load make the intervention usable, but UI alone is not claimed as the main research contribution.')
  )
  Add-Table -Headers @('Question', 'Recommended Answer') -Rows $qaRows -FontSize 8.2

  Add-Text -Text '13. Final Defence Statement' -Style $wdStyleHeading1 -Bold $true -Size 17
  Add-Body '“The value of this work is not that every component is individually unprecedented. Its contribution is a carefully scoped, measurable, and low-cost integration for Grade 1 and Grade 2 literacy learning. I distinguish verified results from proof-of-concept results, avoid overstating model performance, and identify the larger datasets and real-user evaluation required for future development.”'

  $footer = $document.Sections.Item(1).Footers.Item(1).Range
  $footer.Text = 'NenaPotha AI | Research Components and Feature Justification'
  $footer.Font.Name = 'Aptos'
  $footer.Font.Size = 8
  $footer.Font.Color = 8421504
  $footer.ParagraphFormat.Alignment = $wdAlignCenter

  $absoluteOutput = [System.IO.Path]::GetFullPath($OutputPath)
  $document.SaveAs2($absoluteOutput, $wdFormatDocumentDefault)
  $document.Close()
  Write-Output $absoluteOutput
}
finally {
  if ($document -ne $null) {
    try { $document.Close(0) } catch {}
  }
  $word.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}
