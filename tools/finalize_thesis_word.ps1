param(
    [Parameter(Mandatory = $true)]
    [string]$DocxPath,

    [Parameter(Mandatory = $true)]
    [string]$PdfPath
)

$resolvedDocx = (Resolve-Path -LiteralPath $DocxPath).Path
$resolvedPdf = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $PdfPath))
$pdfDirectory = [System.IO.Path]::GetDirectoryName($resolvedPdf)
if (-not (Test-Path -LiteralPath $pdfDirectory)) {
    New-Item -ItemType Directory -Path $pdfDirectory -Force | Out-Null
}

$word = $null
$document = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $word.Options.UpdateFieldsAtPrint = $true

    $document = $word.Documents.Open($resolvedDocx, $false, $false)
    foreach ($field in @($document.Fields)) {
        [void]$field.Update()
    }
    foreach ($toc in @($document.TablesOfContents)) {
        [void]$toc.Update()
    }
    foreach ($story in @($document.StoryRanges)) {
        $range = $story
        while ($null -ne $range) {
            foreach ($field in @($range.Fields)) {
                [void]$field.Update()
            }
            $range = $range.NextStoryRange
        }
    }
    [void]$document.Repaginate()
    $document.Save()
    $document.ExportAsFixedFormat($resolvedPdf, 17)
    Write-Output "DOCX=$resolvedDocx"
    Write-Output "PDF=$resolvedPdf"
    Write-Output "PAGES=$($document.ComputeStatistics(2))"
}
finally {
    if ($null -ne $document) {
        $document.Close($false)
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($document)
    }
    if ($null -ne $word) {
        $word.Quit()
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($word)
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
