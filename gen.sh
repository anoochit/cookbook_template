# Remove all files in the build directory
rm -rf build/*

export LC_ALL="en_US.UTF-8"
export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox"

# Combine full book for epub
echo "EPUB input"

touch build/epub_input.md
for f in chapters/*.md; do
  echo "Processing $f"
  echo "" >> build/epub_input.md
  cat "$f" >> build/epub_input.md
  echo "" >> build/epub_input.md
done

# Combine full book for sample epub
echo "EPUB input"
touch build/sample_epub_input.md
for f in chapters/*.md; do
  # Check if the file name starts with "00" or "01"
  if [[ "$f" =~ ^chapters/(00|01).* ]]; then
    echo "Processing $f"
    echo "" >> build/sample_epub_input.md
    cat "$f" >> build/sample_epub_input.md
    echo "" >> build/sample_epub_input.md
  fi
done

# Combine full book for pdf
echo "PDF input"
touch build/pdf_input.md
for f in chapters/*.md; do
  if [[ "$f" != "chapters/00_preface.md" ]]; then
    echo "Processing $f"
    echo "" >> build/pdf_input.md
    cat "$f" >> build/pdf_input.md
    echo "" >> build/pdf_input.md
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

# Build preface EPUB
echo "Building preface EPUB..."
pandoc -o "build/preface.epub" --top-level-division=chapter --css="epub.css" -i "epub.yaml" "chapters/00_preface.md"

# Build content EPUB
echo "Building content EPUB..."
pandoc -o "build/output.epub" --top-level-division=chapter --css="epub.css" "build/pdf_input.md"

# Build preface PDF
echo "Building preface PDF..."
ebook-convert "build/preface.epub" "build/preface.pdf" --extra-css "calibre_extra_css.css" --filter-css --insert-blank-line --paper-size a4 --embed-all-fonts --pdf-sans-family "Bai Jamjuree" --pdf-mono-family "DejaVu Sans Mono" --pdf-standard-font "sans" --pdf-default-font-size 20 --pdf-mono-font-size 20 --pdf-page-margin-left 64 --pdf-page-margin-right 64 --pdf-page-margin-top 72 --pdf-page-margin-bottom 108

# Build content PDF
echo "Building content PDF..."
ebook-convert "build/output.epub" "build/output.pdf" --extra-css "calibre_extra_css.css" --filter-css --insert-blank-line --pdf-add-toc --toc-title "สารบัญ" --paper-size a4 --embed-all-fonts --pdf-sans-family "Bai Jamjuree" --pdf-mono-family "DejaVu Sans Mono" --pdf-standard-font "sans" --pdf-default-font-size 20 --pdf-mono-font-size 20 --pdf-page-margin-left 64 --pdf-page-margin-right 64 --pdf-page-margin-top 72 --pdf-page-margin-bottom 108

# Get total number of pages in the PDF
pdfPath="./build/output.pdf"
pageCount=$(pdfcpu info "$pdfPath" | grep "Pages:" | awk '{print $2}')

echo "Total number of pages: $pageCount"

# Split page content and toc
echo "Splitting content and TOC..."
read -p "Enter the page number to split at: " pageNumber
pdfcpu split -m page "./build/output.pdf" "./build/" "$pageNumber"

# Stamp page number in content dynamically using page count
echo "Stamping page numbers..."
endPage="$pageNumber"
pdfFilePath="./build/output_1-$((endPage - 1)).pdf"
outputFilePath="./build/output_stamp_1-$((endPage - 1)).pdf"

pdfcpu stamp add -mode text -- "%p" "points:14,scale:1.0 abs,pos:br,rot:0,ma:60" "$pdfFilePath" "$outputFilePath"

# Merge PDF cover, preface, toc, content, and back cover
echo "Merging PDFs..."
mergedFilePath="./build/ebook.pdf"
coverFilePath="./images/cover.pdf"
prefaceFilePath="./build/preface.pdf"
outputFilePath="./build/output_$pageNumber-$pageCount.pdf"
outputStampFilePath="./build/output_stamp_1-$((endPage - 1)).pdf"
backCoverFilePath="./images/back_cover.pdf"

# Merge the PDFs
pdfcpu merge "$mergedFilePath" "$coverFilePath" "$prefaceFilePath" "$outputFilePath" "$outputStampFilePath" "$backCoverFilePath"


# Remove blank page (if exists)
echo "Removing blank page..."
read -p "Enter the page number to remove: " pageToRemove
pdfcpu pages rem -pages "$pageToRemove" "./build/ebook.pdf"
echo "Optimize PDFs..."

# Make PDF sample book for 20 pages
echo "Make PDF sample book for 20 pages..."
pdfcpu trim -pages 1-20 "./build/ebook.pdf" "./build/sample_ebook.pdf"

echo "All done!"
echo "Build completed successfully!"
echo "You can find the output files in the build directory."