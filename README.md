# Cookbook Template

This is a copy-paste template for creating and publishing e-books (EPUB & PDF) from Markdown files.

## 1. Prerequisites

Before you begin, ensure you have the following command-line tools installed:

* [**Pandoc**](https://pandoc.org/): For converting between document formats.
* [**Calibre CLI**](https://calibre-ebook.com/download): Specifically for the `ebook-convert` command.
* [**pdfcpu**](https://pdfcpu.io/): For advanced PDF manipulation.
* [**ImageMagick**](https://imagemagick.org): For image processing and manipulation.

## 2. How to Use

### Step 1: Write Your Content

Place your book chapters as Markdown files (`.md`) inside the `/chapters` directory. They will be processed in alphanumeric order.

### Step 1.5: Generate a Simple Cover (Optional)

If you need a basic cover, you can generate `cover.png` and `cover.pdf` from your `epub.yaml` metadata using the `create_cover.ps1` script. This requires ImageMagick to be installed.

**On Windows (PowerShell):**

```powershell
./create_cover.ps1
```

### Step 2: Generate Your E-book

Run the generation script to create the e-book files in the `/build` directory.

**On Windows (PowerShell):**

```powershell
./gen.ps1
```

**On Linux or macOS:**

```bash
./gen.sh
```

## 3. Customization

You can customize your e-book by editing the following files:

* **/epub.yaml**: Edit this file to change your book's metadata (title, author, etc.).
* **/epub.css**: Modify this file to change the styling of your EPUB.
* **/images/cover.png**: Replace this with your desired book cover image.
* **/images/cover.pdf**: Replace this with your desired book cover image.
* **/images/back_cover.pdf**: Replace this with your desired book cover image.
* **/zb.theme**: Change the syntax highlighting style for code blocks. (option)

## 4. Advanced Usage

### Using the Gemini CLI to Draft Chapters

You can use the Gemini CLI to help draft content. For example, to create a new chapter about FastAPI:

```bash
gemini -p "write a chapter about getting started with FastAPI" > chapters/03_fastapi_getting_started.md
```

### Using Mermaid for Diagrams

This template supports [Mermaid](https://mermaid-js.github.io/mermaid/#/) for rendering diagrams from text.

First, install the Mermaid CLI:

```bash
npm install -g @mermaid-js/mermaid-cli
```

You can then use it to convert Mermaid syntax within your Markdown files into images. For more information, see the [Mermaid documentation](https://github.com/mermaid-js/mermaid-cli#usage) or consider using a [Pandoc Mermaid filter](https://github.com/raghur/mermaid-filter).
