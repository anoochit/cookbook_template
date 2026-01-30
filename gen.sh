#!/bin/bash

# Remove all files in the build directory
rm -f build/*

# Combine full book for epub
echo "EPUB input"
touch "build/epub_input.md"
for f in chapters/*.md; do
    echo "Processing $f"
    echo "" >> "build/epub_input.md"
    cat "$f" >> "build/epub_input.md"
    echo "" >> "build/epub_input.md"
done

# Combine full book for sample epub
echo "EPUB input"
touch "build/sample_epub_input.md"
for f in chapters/*.md; do
    if [[ "$(basename "$f")" =~ ^(00|01) ]]; then
        echo "Processing $f"
        echo "" >> "build/sample_epub_input.md"
        cat "$f" >> "build/sample_epub_input.md"
        echo "" >> "build/sample_epub_input.md"
    fi
done

# Combine full book for pdf
echo "PDF input"
touch "build/pdf_input.md"
for f in chapters/*.md; do
    if [[ "$(basename "$f")" != "00_preface.md" ]]; then
        echo "Processing $f"
        echo "" >> "build/pdf_input.md"
        cat "$f" >> "build/pdf_input.md"
        echo "" >> "build/pdf_input.md"
    fi
done

# Build EPUB
echo "Building EPUB..."
pandoc -o "build/ebook.epub" --top-level-division=chapter --epub-cover-image="images/cover.png" --css="epub.css" -i "epub.yaml" "build/epub_input.md"

# Build EPUB3
echo "Building EPUB3..."
ebook-convert "build/ebook.epub" "build/ebook_epub3.epub" --epub-version 3 --embed-all-fonts

# Build Sample EPUB
echo "Building EPUB..."
pandoc -o "build/sample_ebook.epub" --top-level-division=chapter --epub-cover-image="images/cover.png" --css="epub.css" -i "epub.yaml" "build/sample_epub_input.md"

# Build Sample EPUB3
echo "Building EPUB3..."
ebook-convert "build/sample_ebook.epub" "build/sample_ebook_epub3.epub" --epub-version 3 --embed-all-fonts

# Build preface EPUB preface
echo "Building preface EPUB..."
pandoc -o "build/preface.epub" --top-level-division=chapter --css="epub.css" -i "epub.yaml" "chapters/00_preface.md"

# Build content EPUB content
echo "Building content EPUB..."
pandoc -o "build/output.epub" --top-level-division=chapter --css="epub.css" "build/pdf_input.md"

# PDF settings
pdfSansFamily="Bai Jamjuree"
pdfMonoFamily="DejaVu Sans Mono"
pdfStandardFont="sans"
pdfDefaultFontSize=20
pdfMonoFontSize=20
pdfPageMarginLeft=48
pdfPageMarginRight=48
pdfPageMarginTop=72
pdfPageMarginBottom=108
paperSize="a4"

# Build preface PDF
echo "Building preface PDF..."
ebook-convert "build/preface.epub" "build/preface.pdf" --extra-css "calibre_extra_css.css" --filter-css --insert-blank-line --paper-size "$paperSize" --embed-all-fonts --pdf-sans-family "$pdfSansFamily" --pdf-mono-family "$pdfMonoFamily" --pdf-standard-font "$pdfStandardFont" --pdf-default-font-size "$pdfDefaultFontSize"  --pdf-mono-font-size "$pdfMonoFontSize" --pdf-page-margin-left "$pdfPageMarginLeft" --pdf-page-margin-right "$pdfPageMarginRight" --pdf-page-margin-top "$pdfPageMarginTop" --pdf-page-margin-bottom "$pdfPageMarginBottom"

# Build content PDF
echo "Building content PDF..."
ebook-convert "build/output.epub" "build/output.pdf" --extra-css "calibre_extra_css.css" --filter-css --insert-blank-line --pdf-add-toc --toc-title "สารบัญ" --paper-size "$paperSize" --embed-all-fonts --pdf-sans-family "$pdfSansFamily" --pdf-mono-family "$pdfMonoFamily" --pdf-standard-font "$pdfStandardFont" --pdf-default-font-size "$pdfDefaultFontSize"  --pdf-mono-font-size "$pdfMonoFontSize" --pdf-page-margin-left "$pdfPageMarginLeft" --pdf-page-margin-right "$pdfPageMarginRight" --pdf-page-margin-top "$pdfPageMarginTop" --pdf-page-margin-bottom "$pdfPageMarginBottom"

# Get total number of pages in the PDF
pdfPath="./build/output.pdf"
pdfInfo=$(pdfcpu info "$pdfPath")
pageCount=$(echo "$pdfInfo" | grep "Page count:" | awk '{print $3}')

echo "Total number of pages: $pageCount"

# Split page content and toc
echo "Splitting content and TOC..."
read -p "Enter the page number to split at: " pageNumber
pdfcpu split -m page "./build/output.pdf" "./build/" "$pageNumber"

# Stamp page number in content dynamically using page count
echo "Stamping page numbers..."
endPage=$pageNumber 
pdfFilePath="./build/output_1-$((endPage-1)).pdf"
outputFilePath="./build/output_stamp_1-$((endPage-1)).pdf"

pdfcpu stamp add -mode text -- "%p" "points:14,scale:1.0 abs,pos:br,rot:0,ma:60" "$pdfFilePath" "$outputFilePath"

# Merge PDF cover, preface, toc, content, and back cover
echo "Merging PDFs..."
mergedFilePath="./build/ebook.pdf"
coverFilePath="./images/cover.pdf"
prefaceFilePath="./build/preface.pdf"
outputFilePathSplit="./build/output_$pageNumber-$pageCount.pdf"
outputStampFilePath="./build/output_stamp_1-$((endPage - 1)).pdf"
backCoverFilePath="./images/back_cover.pdf"

# Merge the PDFs
pdfcpu merge "$mergedFilePath" "$coverFilePath" "$prefaceFilePath" "$outputFilePathSplit" "$outputStampFilePath" "$backCoverFilePath"

# Remove blank page (if exists)
read -p "Enter the page number to remove: " pageNumberToRemove
pdfcpu pages rem -pages "$pageNumberToRemove" "./build/ebook.pdf"
echo "Optimize PDFs..."

# Paths
pdfPath="./build/ebook.pdf"
samplePath="./build/sample_ebook.pdf"

# Get PDF info
pdfInfo=$(pdfcpu info "$pdfPath")

# Extract page count
pageCount=$(echo "$pdfInfo" | grep "Page count:" | awk '{print $3}')

# Calculate 10% of pages (at least 1 page)
samplePages=$(echo "($pageCount * 0.1)/1" | bc)
if [ "$samplePages" -lt 1 ]; then
    samplePages=1
fi


# Page range (first 10%)
pageRange="1-$samplePages"

echo "Total pages   : $pageCount"
echo "Sample pages  : $samplePages ($pageRange)"

# Create sample PDF
pdfcpu trim -pages "$pageRange" "$pdfPath" "$samplePath"

# delete all files in build directory except for ebook.pdf, sample_ebook.pdf, ebook_epub3.epub and sample_ebook_epub3.epub
find build/ -type f -not -name "ebook.pdf" -not -name "sample_ebook.pdf" -not -name "ebook_epub3.epub" -not -name "sample_ebook_epub3.epub" -delete

echo "All done!"
echo "Build completed successfully!"
echo "You can find the output files in the build directory."
