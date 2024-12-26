ECHO OFF
 
@REM combine full book
echo. > build\input.md 
for %%f in (chapters\*.md) do (
    echo Processing %%f
    echo. >> build\input.md
    type "%%f" >> build\input.md
    echo. >> build\input.md
)

pandoc --epub-cover-image=images/cover.png -o build\output.epub --syntax-definition dart.xml --css epub.css --toc -i epub.yaml build\input.md  

ebook-convert build\output.epub build\output.pdf --paper-size a4 --pdf-page-margin-left 48 --pdf-page-margin-right 48 --pdf-page-margin-top 72 --pdf-page-margin-bottom 72
