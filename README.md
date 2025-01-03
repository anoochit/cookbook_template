# Cookbook template

A Copy-Paste publishing e-book template.

## How to use 

CLI tools

 * [Pandoc](https://pandoc.org/)
 * [Calibre](https://calibre-ebook.com/) CLI (aka ebook-convert)

Edit for your book info and style in these files

 * [epub.yaml](/epub.yaml) is for EPUB metadata
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

## Mermaid diagrame

You might use mmdc from mermaid-cli to pre process markdown document to generate diagrame image and new markdown file.

```bash
npm install -g @mermaid-js/mermaid-cli
```

There are 2 usecases:

1. Convert Mermaid diagrams into images (No Markdown document)

```bash
mmdc -i <MARKDOWN_DOC_FILENAME>.md -o IMAGE_NAME_PREFIX.png
```

2. Convert Mermaid diagrams into images with Markdown document using them

```
mmdc -i <MARKDOWN_DOC_FILENAME>.md --outputFormat=png \
     -o <ANOTHER_MARKDOWN_DOC_FILENAME>.md
```

Or using pandoc filter: https://github.com/raghur/mermaid-filter
