

@REM Generate full EPUB 
pandoc --top-level-division=chapter --highlight-style zb.theme ^
--css epub.css ^
-f gfm -t epub ^
-o build/ebook.epub ^
--epub-cover-image=images/cover.png ^
-i title.txt ^
chapters/chapter1.md ^
chapters/chapter2.md 

@REM Generate interior PDF
ebook-convert build/ebook.epub build/ebook.pdf ^
--paper-size a4  ^
--pdf-sans-family "Bai Jamjuree" ^
--pdf-standard-font "sans" ^
--pdf-default-font-size 18 ^
--pdf-page-margin-left 36 ^
--pdf-page-margin-right 36 ^
--pdf-page-margin-top 72 ^
--pdf-page-margin-bottom 96 ^
--chapter-mark pagebreak ^
--page-breaks-before / 
