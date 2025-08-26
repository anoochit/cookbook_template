<#
.SYNOPSIS
    Create a book cover image using ImageMagick.
.DESCRIPTION
    This script generates a book cover image based on metadata from epub.yaml.
    It allows the user to specify the paper size (A4 or A6).
.PARAMETER PaperSize
    Specifies the paper size for the cover image. Valid values are "A4" or "A6".
.EXAMPLE
    .\create_cover.ps1 -PaperSize A4
#>
param (
    [ValidateSet("A4", "A6")]
    [string]$PaperSize = "A4"
)

# Install powershell-yaml if not present
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "powershell-yaml module not found. Installing..."
    Install-Module -Name powershell-yaml -Force -Scope CurrentUser
}

Import-Module powershell-yaml

try {
    # Read metadata from epub.yaml
    $metadata = Get-Content -Path "epub.yaml" | ConvertFrom-Yaml

    # Handle title array or simple string
    $title = ($metadata.title | Where-Object { $_.type -eq 'main' }).text
    if (-not $title) { $title = $metadata.title } # fallback if not array
    $subtitle = ($metadata.title | Where-Object { $_.type -eq 'subtitle' }).text

    # Define image dimensions based on paper size
    $width, $height = switch ($PaperSize) {
        "A4" { 2480, 3508 }
        "A6" { 1240, 1748 }
    }

    # Ensure output folder exists
    $outputDir = "images"
    if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir | Out-Null }
    $outputFile = Join-Path $outputDir "cover.png"
    $outputBackCoverFile = Join-Path $outputDir "back_cover.png"
    $outputPdf  = Join-Path $outputDir "cover.pdf"
    $outputBackCoverPdf = Join-Path $outputDir "back_cover.pdf"

    # Create a white background image
    magick -size "${width}x${height}" xc:white "$outputFile"
    magick -size "${width}x${height}" xc:white "$outputBackCoverFile"

    # Add title and subtitle (quoted to handle spaces)
    magick "$outputFile" `
        -gravity center `
        -pointsize 150 `
        -annotate +0-200 "$title" `
        -pointsize 80 `
        -annotate +0+100 "$subtitle" `
        "$outputFile"

    # Convert to PDF
    magick "$outputFile" "$outputPdf"
    magick "$outputBackCoverFile" "$outputBackCoverPdf"

    Write-Host "✅ Cover image created at $outputFile"
    Write-Host "✅ PDF version created at $outputPdf"
}
catch {
    Write-Error "An error occurred: $_"
}
