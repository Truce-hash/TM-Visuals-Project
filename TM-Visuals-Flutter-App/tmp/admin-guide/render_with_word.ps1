$ErrorActionPreference='Stop'
$base=(Resolve-Path '.').Path
$inputPath=Join-Path $base 'output/docx/TM_Visuals_Admin_Features_Code_Guide.docx'
$pdfPath=Join-Path $base 'tmp/admin-guide/render/TM_Visuals_Admin_Features_Code_Guide.pdf'
New-Item -ItemType Directory -Force -Path (Split-Path $pdfPath) | Out-Null
$word=$null
$document=$null
try {
    $word=New-Object -ComObject Word.Application
    $word.Visible=$false
    $word.DisplayAlerts=0
    $word.AutomationSecurity=3
    $document=$word.Documents.Open($inputPath,$false,$true,$false)
    $document.Repaginate()
    $pageCount=$document.ComputeStatistics(2)
    $document.ExportAsFixedFormat($pdfPath,17)
    Write-Output "Rendered with Microsoft Word: $pageCount pages"
} finally {
    if($null -ne $document){$document.Close(0);[void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($document)}
    if($null -ne $word){$word.Quit();[void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($word)}
}
