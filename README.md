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

### Step 3: Using the Rust CLI (Alternative)

An alternative way to generate your e-book is to use the provided Rust CLI application. This application provides more structured commands for building your book.

#### Prerequisites for Rust CLI

*   **Rust Toolchain**: Install the Rust programming language and Cargo (Rust's package manager) from [rustup.rs](https://rustup.rs/).

#### How to Use the Rust CLI

1.  **Navigate to the `cookbook_generator` directory:**

    ```bash
    cd cookbook_generator
    ```

2.  **Initialize the configuration file (if not already present):**

    This command creates a `config.txt` file with default build parameters.

    ```bash
    cargo run init
    ```

    You can then edit `cookbook_generator/config.txt` to customize PDF generation parameters like font families, sizes, and margins.

3.  **Build the e-book:**

    This command compiles your markdown chapters into EPUB and PDF formats.

    ```bash
    cargo run build
    ```

    You will be prompted for page numbers to split and remove from the PDF. To skip these prompts and use default values (which might not be ideal for all books), you can use the `--skip-prompts` flag:

    ```bash
    cargo run build -- --skip-prompts
    ```

    The generated files will be in the `cookbook_generator/build` directory.

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
