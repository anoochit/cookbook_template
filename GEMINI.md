# Directory Overview

This directory contains a template for creating and publishing e-books (EPUB and PDF). It uses Pandoc, Calibre, and pdfcpu to convert Markdown chapters into formatted e-book files.

## Key Files

*   `chapters/`: This directory holds the book's content, with each chapter as a separate Markdown file.
*   `images/`: Contains image assets for the book, such as the cover (`cover.png`, `cover.pdf`) and back cover (`back_cover.pdf`).
*   `epub.yaml`: The main configuration file for the e-book's metadata, including title, author, and language.
*   `epub.css` & `calibre_extra_css.css`: These files define the styling (CSS) for the EPUB and PDF outputs, controlling the appearance of text, headings, and other elements.
*   `zb.theme`: A JSON file that specifies the syntax highlighting theme for code blocks within the e-book.
*   `gen.ps1` (for Windows) & `gen.sh` (for Linux/macOS): These are the build scripts that automate the entire e-book generation process.
*   `build/`: This directory is where the final e-book files (`.epub`, `.pdf`) are generated. It is created when the generation script is run.

## Usage

This project is designed to be used from the command line.

### Prerequisites

Before generating an e-book, you must have the following command-line tools installed:
*   [Pandoc](https://pandoc.org/)
*   [Calibre Command-Line Tools (`ebook-convert`)](https://calibre-ebook.com/download)
*   [pdfcpu](https://pdfcpu.io/)

### Generation Process

1.  **Write Content:** Add or edit the Markdown files in the `chapters/` directory. The files are processed in alphanumeric order.
2.  **Update Metadata:** Modify `epub.yaml` to set the book's title, author, and other details.
3.  **Customize Style:** (Optional) Adjust the CSS in `epub.css` and `calibre_extra_css.css` to change the book's appearance.
4.  **Run the Script:** Execute the generation script from the project root.

    **On Windows:**
    ```powershell
    .\gen.ps1
    ```

    **On Linux or macOS:**
    ```bash
    ./gen.sh
    ```
The script will combine the chapters, apply the metadata and styling, and generate the final EPUB and PDF files in the `build/` directory. The script will prompt for page numbers to correctly split and merge the final PDF.
