# Cookbook template

A Copy-Paste publishing e-book template.

## How to use 

CLI tools

 * Pandoc
 * Calibre CLI (aka ebook-convert)

Edit for your book info and style in these files

 * [title.txt](/title.txt) is for EPUB metadata
 * [epub.css](/epub.css) is EPUB document style
 * [zb.theme](/zb.theme) is a syntax highlight style for source code
 * [gen.sh](/gen.sh) and [gen.bat](/gen.bat) is a script for generate book
 * [cover.png](/images/cover.png) is a book cover

Generate e-book files

```bash
gen.sh
```

OR

```cmd
gen.bat
```