# Cookbook template

A Copy-Paste publishing e-book template.

## How to use 

CLI tools

 * Pandoc
 * Calibre CLI (aka ebook-convert)

Edit for your book info and style in these files

 * title.txt is for EPUB metadata
 * epub.css is EPUB document style
 * zb.theme is a sytax highlight style for source code
 * gen.sh and gen.bat is a script for generate book

Generate e-book files

```bash
gen.sh
```

OR

```cmd
gen.bat
```