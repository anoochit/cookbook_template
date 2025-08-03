# Remove all files in the build directory
Remove-Item -Path "build\*" -Force

# Combine full book for epub
Write-Host "EPUB input"
New-Item -Path "build\epub_input.md" -ItemType File -Force
foreach ($f in Get-ChildItem -Path "chapters\*.md") {
    Write-Host "Processing $($f.FullName)"
    Add-Content -Path "build\epub_input.md" -Value "`r`n"
    Get-Content $f.FullName | Out-File -Append -FilePath "build\epub_input.md"
    Add-Content -Path "build\epub_input.md" -Value "`r`n"
}

# Combine full book for sample epub
Write-Host "EPUB input"
New-Item -Path "build\sample_epub_input.md" -ItemType File -Force
foreach ($f in Get-ChildItem -Path "chapters\*.md") {
    # Check if the file name starts with "00" or "01"
    if ($f.Name -match "^(00|01)") {
        Write-Host "Processing $($f.FullName)"
        Add-Content -Path "build\sample_epub_input.md" -Value "`r`n"
        Get-Content $f.FullName | Out-File -Append -FilePath "build\sample_epub_input.md"
        Add-Content -Path "build\sample_epub_input.md" -Value "`r`n"
    }
}

# Combine full book for pdf
Write-Host "PDF input"
New-Item -Path "build\pdf_input.md" -ItemType File -Force
foreach ($f in Get-ChildItem -Path "chapters\*.md") {
    if ($f.Name -ne "00_preface.md") {
        Write-Host "Processing $($f.FullName)"
        Add-Content -Path "build\pdf_input.md" -Value "`r`n"
        Get-Content $f.FullName | Out-File -Append -FilePath "build\pdf_input.md"
        Add-Content -Path "build\pdf_input.md" -Value "`r`n"
    }
}

# Build EPUB
Write-Host "Building EPUB..."
pandoc -o "build\ebook.epub" --top-level-division=chapter --epub-cover-image="images\cover.png" --css="epub.css" -i "epub.yaml" "build\epub_input.md"

# Build EPUB3
Write-Host "Building EPUB3..."
ebook-convert "build\ebook.epub" "build\ebook_epub3.epub" --epub-version 3 --embed-all-fonts

# Build Sample EPUB
Write-Host "Building EPUB..."
pandoc -o "build\sample_ebook.epub" --top-level-division=chapter --epub-cover-image="images\cover.png" --css="epub.css" -i "epub.yaml" "build\sample_epub_input.md"


# Build Sample EPUB3
Write-Host "Building EPUB3..."
ebook-convert "build\sample_ebook.epub" "build\sample_ebook_epub3.epub" --epub-version 3 --embed-all-fonts

# Build preface EPUB preface
Write-Host "Building preface EPUB..."
pandoc -o "build\preface.epub" --top-level-division=chapter --css="epub.css" -i "epub.yaml" "chapters\00_preface.md"

# Build content EPUB content
Write-Host "Building content EPUB..."
pandoc -o "build\output.epub" --top-level-division=chapter --css="epub.css" "build\pdf_input.md"

# Build preface PDF
Write-Host "Building preface PDF..."
ebook-convert "build\preface.epub" "build\preface.pdf" --extra-css "calibre_extra_css.css" --filter-css --insert-blank-line --paper-size a4 --embed-all-fonts --pdf-sans-family "Bai Jamjuree" --pdf-mono-family "DejaVu Sans Mono" --pdf-standard-font "sans" --pdf-default-font-size 22 --pdf-mono-font-size 16 --pdf-page-margin-left 64 --pdf-page-margin-right 64 --pdf-page-margin-top 72 --pdf-page-margin-bottom 108

# Build content PDF
Write-Host "Building content PDF..."
ebook-convert "build\output.epub" "build\output.pdf" --extra-css "calibre_extra_css.css" --filter-css --insert-blank-line --pdf-add-toc --toc-title "Table of Contents" --paper-size a4 --embed-all-fonts --pdf-sans-family "Bai Jamjuree" --pdf-mono-family "DejaVu Sans Mono" --pdf-standard-font "sans" --pdf-default-font-size 22 --pdf-mono-font-size 16 --pdf-page-margin-left 64 --pdf-page-margin-right 64 --pdf-page-margin-top 72 --pdf-page-margin-bottom 108

# # Split page content and toc
# Write-Host "Splitting content and TOC..."
# pdfcpu split -m page ".\build\output.pdf" ".\build\" 96

# Get total number of pages in the PDF
$pdfPath = ".\build\output.pdf"
$pdfInfo = pdfcpu info $pdfPath
$pageCount = ($pdfInfo | Select-String -Pattern "Page count: (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value })

Write-Host "Total number of pages: $pageCount"

# Split page content and toc
Write-Host "Splitting content and TOC..."
$pageNumber = Read-Host "Enter the page number to split at"
pdfcpu split -m page ".\build\output.pdf" ".\build\" $pageNumber

# # Stamp page number in content
# Write-Host "Stamping page numbers..."
# pdfcpu stamp add -mode text -- "%p" "points:14,scale:1.0 abs,pos:br,rot:0,ma:60" ".\build\output_1-95.pdf" ".\build\output_stamp_1-95.pdf"

# Stamp page number in content dynamically using page count
Write-Host "Stamping page numbers..."
$endPage = $pageNumber # Using the total page count from the variable
$pdfFilePath = ".\build\output_1-" + ($endPage-1) + ".pdf"
$outputFilePath = ".\build\output_stamp_1-" + ($endPage-1) + ".pdf"

pdfcpu stamp add -mode text -- "%p" "points:14,scale:1.0 abs,pos:br,rot:0,ma:60" $pdfFilePath $outputFilePath

# # Merge PDF cover, preface, toc, content, and back cover
# Write-Host "Merging PDFs..."
# pdfcpu merge ".\build\ebook.pdf" ".\images\cover.pdf" ".\build\preface.pdf" ".\build\output_96-102.pdf" ".\build\output_stamp_1-95.pdf" ".\images\back_cover.pdf"


# Merge PDF cover, preface, toc, content, and back cover
Write-Host "Merging PDFs..."
$mergedFilePath = ".\build\ebook.pdf"
$coverFilePath = ".\images\cover.pdf"
$prefaceFilePath = ".\build\preface.pdf"
$outputFilePath = ".\build\output_$pageNumber-$pageCount.pdf"
$outputStampFilePath = ".\build\output_stamp_1-" + ($endPage - 1) + ".pdf"
$backCoverFilePath = ".\images\back_cover.pdf"

# Merge the PDFs
pdfcpu merge $mergedFilePath $coverFilePath $prefaceFilePath $outputFilePath $outputStampFilePath $backCoverFilePath


# # Remove blank page (if exists)
# Write-Host "Removing blank page..."
# pdfcpu pages rem -pages 108 ".\build\ebook.pdf"

# Remove blank page (if exists)
$pageNumber = Read-Host "Enter the page number to remove"
pdfcpu pages rem -pages $pageNumber ".\build\ebook.pdf"
Write-Host "Optimize PDFs..."

# Make PDF sample book for 5 pages
Write-Host "Make PDF sample book for 40 pages..."
pdfcpu trim -pages 1-5 .\build\ebook.pdf .\build\sample_ebook.pdf

# delete all files in build directory except for ebook.pdf, sample_ebook.pdf, ebook_epub3.epub and sample_ebook_epub3.epub
Get-ChildItem -Path "build\*" | Where-Object { $_.Name -notmatch "ebook\.pdf|sample_ebook\.pdf|ebook_epub3\.epub|sample_ebook_epub3\.epub" } | Remove-Item -Force

Write-Host "All done!"
Write-Host "Build completed successfully!"
Write-Host "You can find the output files in the build directory."
