#!/bin/bash

> build/combined.md

# Loop through all .md files in the chapters directory
for file in chapters/*.md; do
    echo "Processing $file"
    # Add a blank line before each chapter
    echo "" >> build/combined.md
    # Append the content of the current file
    cat "$file" >> build/combined.md
    # Add a blank line after each chapter
    echo "" >> build/combined.md
done

# Generate full EPUB 
pandoc --toc --top-level-division=chapter --highlight-style zb.theme \
--css epub.css \
-f gfm -t epub \
-o build/ebook.epub \
--epub-cover-image=images/cover.png \
-i title.txt \
build/combined.md

#  Generate interior PDF
ebook-convert build/ebook.epub build/ebook.pdf \
--paper-size a4  \
--pdf-sans-family "Bai Jamjuree" \
--pdf-standard-font "sans" \
--pdf-default-font-size 18 \
--pdf-page-margin-left 36 \
--pdf-page-margin-right 36 \
--pdf-page-margin-top 72 \
--pdf-page-margin-bottom 96 \
--chapter-mark pagebreak \
--page-breaks-before / 
