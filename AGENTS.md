# AGENTS.md — Book Project Guidelines for "GORM: ORM in Go for beginners"

Welcome to the **"GORM: ORM in Go for beginners"** repository. This document provides instructions and guidelines for AI agents that assist in writing, editing, and building this technical book.

---

## 1. Project Overview

- **Book Title:** `GORM: ORM in Go for beginners`
- **Topic:** 
- **Outline & Mapping:** Defined in `toc.md`, with explicit document citations per chapter.

---

## 2. Repository Layout

```text
.
├── toc.md                      # Table of contents and doc references per chapter
├── config.txt                  # Font and PDF compilation settings
├── Makefile                    # Build automation (`make gen`)
├── chapters/                   # Markdown chapter source files
│   ├── 00_preface.md           # Publisher foreword & author preface
│   ├── 01_introduction.md
│   └── ...
├── example/                    # Runnable example programs shown in the chapters
│   └── <title>/                # One directory per chapter title (e.g. example/setup/)
│       ├── main.go             # The complete program printed in that chapter
│       ├── go.mod              # Standalone module so `go run .` works
│       └── go.sum
├── images/                     # Figures, diagrams, cover images, and vector assets
│   ├── figX-Y.mmd             # Mermaid source for figure X.Y
│   └── figX-Y.png              # Rendered figure X.Y (referenced by chapters)
├── .agents/skills/             # Agent skills used while writing and building the book
│   ├── technical-book-writer/  # Writing and editing guidelines (SKILL.md)
│   └── mermaid-figures/        # Diagram workflow: scripts, config, references
└── build/                      # Output directory for generated PDF and EPUB files
```

---

## 3. Writing & Editorial Standards

Follow the **`technical-book-writer`** skill guidelines together with the project-specific formatting rules below.

### Formatting & Heading Rules

- **Chapter Lead Paragraph:** Every chapter MUST begin with a 2–4 sentence introductory lead paragraph immediately after the `# Chapter <X>: <Title>` header and before the first `##` section heading. This lead establishes the problem context, relevance, and goals of the chapter.
- **No Horizontal Dividers:** Do NOT insert horizontal dividers (`---`) between sections or headings in chapter files.
- **No Topic Numbers in Headings:** Do NOT put topic numbers in section headings (e.g. write `## What is an AI Agent...`, not `## 1.1 What is an AI Agent...`).
- **No Document Citation Lines in Chapters:** Do NOT include source document citation lines (e.g. `> **Reference:** ...`) inside chapter markdown files. Citations belong exclusively in `toc.md`.
- **Chapter Summary Format:** Use `## Summary` as the standard heading for chapter summaries. Write summaries as cohesive prose paragraphs rather than bulleted lists.

### Diagrams & Visuals

- **Ebook-Optimized Mermaid Diagrams:** Always use vertical **Mermaid flowcharts** (`flowchart TD` / `graph TD`) as the primary format. Avoid horizontal `sequenceDiagram` blocks: wide sequence diagrams shrink, clip, or become unreadable on small ebook/e-reader screens. Vertical flowcharts stack steps cleanly and read well in both EPUB and PDF.
- **Mandatory Diagram Explanations:** Every diagram MUST be accompanied by:
  1. A descriptive alt text inside the image reference (`![<descriptive alt text>](images/fig1-1.png)`) that names what the figure shows.
  2. A detailed explanatory prose paragraph immediately below the image, describing what the diagram illustrates — the execution steps, component relationships, or data flow shown in the visual.

  Caption lines (`*Figure X.Y: ...*`) are **no longer used**; the alt text plus the explanatory paragraph now carry that role.
- **Pre-rendered Images, Not Live Mermaid:** Chapters reference **pre-rendered PNG images**, not inline ` ```mermaid ` blocks. The Mermaid source lives in `images/figX-Y.mmd` and the rendered image is `images/figX-Y.png`, where the first `N` is the chapter number and the second `N` is the figure sequence within that chapter. Each chapter therefore contains:

  ```markdown
  ![Fig X.Y <descriptive alt text>](images/fig1-1.png)

  <prose paragraph explaining the mechanism, steps, and relationships between the components in the image>
  ```

  The figure number in the file name MUST match the chapter and figure sequence (`images/fig1-1.png` = chapter 1, figure 1), and the alt text MUST describe the image rather than repeating a generic prefix.
- **Regenerating Diagrams:** The `mermaid-figures` Agent Skill in `.agents/skills/mermaid-figures/` owns this workflow. When a diagram changes, edit its `.mmd` source and re-render:

  ```bash
  node .agents/skills/mermaid-figures/scripts/render-mermaid.js --chapter 1 --jobs 4
  ```

  Drop `--chapter` to re-render everything. `scripts/extract-mermaid.js` pulls a new inline ` ```mermaid
` block out of a chapter into `images/figX-Y.mmd` and keeps the image reference the author wrote below it; `scripts/render-mermaid.js` renders every `.mmd` to PNG with `mermaid-cli` using `references/mermaid-config.json` (Bai Jamjuree font, white background, natural proportions with `useMaxWidth: false`, and 4x scale for print resolution); `scripts/verify-figures.js` checks that every image reference has descriptive alt text, an explanatory paragraph below it, and matching PNG and MMD source files.
- **Mermaid Syntax Pitfalls:** Label text containing `{`, `}`, or `#[` MUST be wrapped in double quotes (e.g. `A["Resolve {user_name}"]`), or the Mermaid parser will reject the diagram.

### Tone & Style

- **Tone:** Professional, technical, clear, direct, and practical (engineer-to-engineer).
- **Language:** Thai is the primary explanatory language. Keep standard engineering and product terms in **English** (e.g. `Runner`, `LlmAgent`, `CustomAgent`, `SharedState`, `Content`, `Part`, `MCP`, `ACP`, `A2A`, `AWP`, `OpenTelemetry`, `Axum`, `Tokio`, and so on).
- **Prose Quality:** Simple language, deep ideas. Avoid excessive jargon, fluff, and marketing superlatives.

### Structure & Information Architecture

Each chapter should follow this flow:

```text
Lead Paragraph → Context → Problem → Concept → Architecture → Implementation → Code Example → Production Considerations → Summary
```

### Technical Accuracy & Code Examples

- **Verify Before Writing:** Check every API, command, default value, and configuration against the official GORM documentation cited for that chapter in `toc.md` before putting it in prose or code. Never invent APIs, commands, flags, or default values.
- **Complete Programs Live in `example/<title>/`:** Every complete, runnable program printed in a chapter MUST also be checked in under `example/<title>/`, where `<title>` is the chapter title in lower case with spaces replaced by hyphens. Chapter 2 (`# Chapter 2: Setup`) → `example/setup/`; Chapter 3 (`Declaring Models and Conventions`) → `example/declaring-models-and-conventions/`.
- **Standalone Modules:** Each example directory is its own Go module (`go.mod`, `go.sum`, `main.go`) that runs with `go run .` from inside the directory. If an example needs a C toolchain (CGO) or any other build prerequisite, state it in the chapter prose.
- **Chapter and Example Stay in Sync:** A code block in a chapter MUST match the checked-in example source character for character (unless the block deliberately shows only a fragment). When either side changes, update the other in the same edit.
- **Tell the Reader Where the Code Is:** Reference `example/<title>/` in the chapter prose so readers can find, run, and modify the full program.
- **Fragments Stay Inline:** Partial snippets — one call, an alternate import, a config fragment — live only in the chapter; they do not get their own directory.
- **No Generated Artifacts:** Never commit files a program produces at runtime (for example SQLite `*.db` files); add them to `.gitignore`.

---

## 4. Workflows & Commands

### Building the Book

To build the book into EPUB and PDF formats:

```powershell
# PowerShell / Windows
make gen
```

or

```bash
cookbook_generator build
```

The output files are generated under the `build/` directory.

### Editing Chapters

- Keep changes in `chapters/<chapter_filename>.md`.
- Ensure all chapter titles and section structures align with `toc.md`.
- Maintain terminology consistency across all chapters.

### Running a Chapter Example

Each `example/<title>/` directory is a self-contained Go module:

```bash
cd example/setup
go run .
```

Use `go build ./...` or `go vet ./...` to type-check an example without running it. Prerequisites that go beyond the Go toolchain (such as CGO for `gorm.io/driver/sqlite`) must be documented in the chapter that owns the example.

### Git Commit & Push Policy

- **Automatic Commit & Push:** After every change or update (chapters, TOC, configuration, or documentation), automatically run `git add .`, `git commit -m "<conventional_commit_message>"`, and `git push`.
- Use the conventional commits format (e.g. `feat(ch02): write chapter 2 core types and runner`, `docs: update AGENTS.md guidelines`).

---

## 5. Golden Rules for AI Agents

1. **Strict Formatting Compliance:** Follow the formatting rules exactly — always include a lead paragraph under the chapter title; no `---` dividers in chapters; no topic numbers in headings; no citation lines in chapters; use `## Summary` with prose paragraphs.
2. **Vertical Mermaid Flowcharts First:** Prefer vertical `flowchart TD` diagrams over wide `sequenceDiagram` blocks for ebook compatibility.
3. **Mandatory Diagram Alt Text & Explanations:** Every diagram needs descriptive alt text in its image reference and an explanatory prose paragraph directly below it. No caption lines.
4. **Auto Git Commit & Push:** Automatically run `git add .`, `git commit`, and `git push` after completing changes or updates.
5. **Preserve Technical Meaning:** Never alter technical facts or code correctness when polishing prose.
6. **Examples Are Checked In:** Every complete program printed in a chapter must exist under `example/<title>/`, build as a standalone Go module, and stay identical to the code block in the chapter.
