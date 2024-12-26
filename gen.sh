#!/bin/bash

echo '' > build/input.md

# Loop through all .md files in the chapters directory
for file in chapters/*.md; do
    echo "Processing $file"
    # Add a blank line before each chapter
    echo "" >> build/input.md
    # Append the content of the current file
    cat "$file" >> build/input.md
    # Add a blank line after each chapter
    echo "" >> build/input.md
done


pandoc --epub-cover-image=images/cover.png -o build\output.epub --syntax-definition dart.xml --css epub.css --toc -i epub.yaml build\input.md  

ebook-convert build\output.epub build\output.pdf --paper-size a4 --pdf-page-margin-left 48 --pdf-page-margin-right 48 --pdf-page-margin-top 72 --pdf-page-margin-bottom 72
