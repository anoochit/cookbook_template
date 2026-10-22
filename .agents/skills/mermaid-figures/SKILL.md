---
name: mermaid-figures
description: Create and update the book's diagrams by keeping Mermaid source in separate .mmd files and rendering them to PNG images that are embedded in the chapters. Use when adding, editing, or auditing diagrams in chapters/.
version: "1.0.0"
license: MIT
compatibility: Requires Node.js and a global install of mermaid-cli (@mermaid-js/mermaid-cli)
tags: [documentation, mermaid, diagram, images, ebook]
triggers: ["*.md", "images/*", "chapters/*"]
references:
  - references/mermaid-config.json
---

# Mermaid Figures Skill

This skill controls how diagrams in the book are rendered to PNG images
embedded in the actual chapters, instead of using inline ` ```mermaid ` blocks.

## Rules That Must Not Be Broken

1. **Never put a ` ```mermaid ` block in a chapter file** — chapters may only reference PNG images.
2. **File names are bound to the figure number** — `images/figX-Y.png` = chapter X, figure Y (the Mermaid source lives at `images/figX-Y.mmd`).
3. **Always include descriptive alt text and an explanatory paragraph directly below the image**:

   ```markdown
   ![<descriptive alt text>](images/fig1-1.png)

   <prose paragraph explaining the mechanism, steps, and relationships between the components in the image>
   ```

   - The alt text must say what the image shows; do not rely on a generic prefix such as "Diagram..." alone.
   - **Caption lines** (e.g. `*Figure 1.1: ...*`) are **no longer used**.
4. **The image style must be a vertical flowchart** (`flowchart TD` / `graph TD`), because horizontal
   diagrams get scaled down until they are unreadable on e-reader screens.

## File Layout

| File | Role |
|---|---|
| `images/figX-Y.mmd` | Mermaid source for figure X.Y (edit here when changing a diagram) |
| `images/figX-Y.png` | Rendered image referenced by the chapters (built from the `.mmd`) |
| `references/mermaid-config.json` | mermaid-cli theme (Google Sans font, white background) |

> The two file-name styles differ on purpose: the `.mmd` uses `figX-Y.mmd` (hyphenated) while the
> `.png` uses `figX-Y.png` (unhyphenated), to stay consistent with the book's existing convention.

## Adding a New Diagram

1. Write a ` ```mermaid ` block in the target chapter, then write an image reference with descriptive
   alt text below the block, followed by an explanatory paragraph:

   ```markdown
   ```mermaid
   flowchart TD
       A[...] --> B[...]
   ```

   ![<descriptive alt text>](images/fig1-5.png)

   <prose paragraph explaining the mechanism, steps, and relationships between the components in the image>
   ```

2. Extract the block into a `.mmd` file (the image reference you already wrote is preserved):

   ```bash
   node .agents/skills/mermaid-figures/scripts/extract-mermaid.js --dry-run   # preview first
   node .agents/skills/mermaid-figures/scripts/extract-mermaid.js
   ```

3. Render the image:

   ```bash
   node .agents/skills/mermaid-figures/scripts/render-mermaid.js --jobs 4
   ```

## Editing an Existing Diagram

1. Edit `images/figX-Y.mmd` directly (never edit the `.png`).
2. Re-render — render only the chapter you changed for speed:

   ```bash
   node .agents/skills/mermaid-figures/scripts/render-mermaid.js --chapter 1 --jobs 4
   ```

   Filter options:

   | Option | Meaning |
   |---|---|
   | (none) | Render every diagram in the book |
   | `--chapter N` | Render only chapter N, e.g. `--chapter 1` |
   | `--figure N.M` | Render only figure N.M, e.g. `--figure 1.2` |
   | `--jobs N` | Number of parallel render jobs (default 4) |

### Image Resolution (Important for PDF/EPUB)

`references/mermaid-config.json` sets `useMaxWidth: false` so each diagram is rendered at its
**natural proportions** (not stretched to fill a 1600px frame), and `--scale 4` then enlarges it
to a resolution high enough for print (~200 DPI when scaled to the full page width).

> If you change `useMaxWidth` back to `true`, you must raise `--scale` accordingly,
> otherwise the effective image resolution drops by half.

## Validation

```bash
node .agents/skills/mermaid-figures/scripts/verify-figures.js
```

This script checks that every image reference has matching `.png` and `.mmd` files, that the alt text
actually describes the diagram, that an explanatory paragraph sits below the image, that no legacy
caption lines remain, and that no mermaid blocks are left behind in the chapters.

## Mermaid Syntax Warnings

Label text containing `{`, `}` or `#[` **must be wrapped in double quotes**, otherwise the
parser treats it as a shape and the render fails.

```mermaid
flowchart TD
    Good["Resolve {user_name} from Session State"]
    AlsoGood["#[entrypoint] fn process_workflow"]
    Bad[Resolve {user_name} from Session State]
```

## Building the Book After Editing

```bash
make gen
```

Output lands in `build/ebook_epub3.epub` and `build/output.pdf`.
