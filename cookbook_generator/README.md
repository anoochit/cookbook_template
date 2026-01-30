# Cookbook Generator

This is a command-line tool for generating cookbooks from markdown chapters. It produces EPUB and PDF formats.

## Prerequisites

Before you can build the cookbook, you need to have the following tools installed and available in your system's PATH:

*   [Rust](https://www.rust-lang.org/tools/install)
*   [Zig](https://ziglang.org/download/) (for cross-compilation)
*   [Pandoc](https://pandoc.org/installing.html)
*   [Calibre Command-Line Tools (`ebook-convert`)](https://calibre-ebook.com/download)
*   [pdfcpu](https://pdfcpu.io/install)

## Build Instructions

This project is set up for cross-platform compilation.

### On Windows

Open a PowerShell terminal and run the build script:

```powershell
.\build.ps1
```

### On Linux or macOS

Open a terminal and run the build script:

```bash
chmod +x build.sh
./build.sh
```

The build scripts will compile the `cookbook_generator` for Windows, Linux, and macOS, and place the executables in the `dist` directory.

## Usage

The `cookbook_generator` has two main commands: `init` and `build`.

### `init`

The `init` command creates a default `config.txt` file in the current directory. This file contains various settings for the PDF output.

```bash
cookbook_generator init
```

### `build`

The `build` command generates the cookbook from the markdown chapters in the `chapters` directory.

```bash
cookbook_generator build [OPTIONS]
```

**Options:**

*   `--skip-prompts`: Skips interactive prompts for page numbers.
*   `--config <PATH>`: Specifies the path to the configuration file. Defaults to `config.txt`.

### Example Workflow

1.  **Initialize the configuration**:
    ```bash
    ./dist/windows/cookbook_generator.exe init
    ```
    (or the appropriate executable for your platform)

2.  **Customize the configuration**: Edit the `config.txt` file to your liking.

3.  **Build the cookbook**:
    ```bash
    ./dist/windows/cookbook_generator.exe build
    ```
