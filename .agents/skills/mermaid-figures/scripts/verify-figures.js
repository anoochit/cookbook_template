/**
 * Verifies the figure convention used by every chapter:
 *   - the image reference points to an existing PNG,
 *   - the Mermaid source (`.mmd`) behind that PNG exists,
 *   - the alt text is descriptive,
 *   - an explanatory paragraph follows the image,
 *   - no leftover Mermaid blocks and no stale caption lines.
 *
 * Usage: node .agents/skills/mermaid-figures/scripts/verify-figures.js
 */
const fs = require('fs');
const path = require('path');

/** Walks up from this script until it finds the cookbook root (the folder holding `chapters/`). */
function findRepoRoot(start) {
    let dir = start;
    for (let i = 0; i < 8; i++) {
        if (fs.existsSync(path.join(dir, 'chapters'))) return dir;
        const parent = path.dirname(dir);
        if (parent === dir) break;
        dir = parent;
    }
    throw new Error('could not locate the cookbook root (a folder containing chapters/)');
}

const root = findRepoRoot(__dirname);
const chaptersDir = path.join(root, 'chapters');
const imagesDir = path.join(root, 'images');

// optional pandoc link attributes, e.g. ![alt](images/fig1-1.png){width=180}
const IMAGE_RE = /^!\[(.+?)\]\(images\/(fig(\d+)-(\d+)\.png)\)(\{[^}]*\})?$/;
const STALE_CAPTION_RE = /^\*ไดอะแกรมที่\s*\d+\.\d+.*\*$/;
const MIN_ALT_LENGTH = 8;
const MIN_EXPLANATION_LENGTH = 30;

const files = fs.readdirSync(chaptersDir).filter((f) => f.endsWith('.md')).sort();
const problems = [];
const referenced = new Set();
let checked = 0;

for (const file of files) {
    const lines = fs.readFileSync(path.join(chaptersDir, file), 'utf8').split(/\r?\n/);

    lines.forEach((line, i) => {
        const img = line.match(IMAGE_RE);
        if (!img) return;
        checked++;

        const alt = img[1].trim();
        const pngPath = path.join(imagesDir, img[2]);
        const mmdPath = path.join(imagesDir, `fig-${img[3]}-${img[4]}.mmd`);
        referenced.add(img[2]);
        referenced.add(`fig-${img[3]}-${img[4]}.mmd`);

        if (!fs.existsSync(pngPath)) problems.push(`${file}:${i + 1} missing PNG ${img[2]}`);
        if (!fs.existsSync(mmdPath)) problems.push(`${file}:${i + 1} missing MMD source fig${img[3]}-${img[4]}.mmd`);

        if (alt.length < MIN_ALT_LENGTH) {
            problems.push(`${file}:${i + 1} alt text is not descriptive (${alt.length} chars)`);
        }

        // the image must be followed by an explanatory paragraph
        let explained = false;
        for (let k = i + 1; k < Math.min(i + 4, lines.length); k++) {
            const t = lines[k].trim();
            if (t === '') continue;
            const isProse = !t.startsWith('#') && !t.startsWith('```') && !t.startsWith('![') && !t.startsWith('|');
            if (isProse && t.length >= MIN_EXPLANATION_LENGTH) explained = true;
            break;
        }
        if (!explained) problems.push(`${file}:${i + 1} image has no explanatory paragraph below`);
    });

    lines.forEach((line, i) => {
        if (line.trim() === '```mermaid') problems.push(`${file}:${i + 1} leftover mermaid block`);
        if (STALE_CAPTION_RE.test(line.trim())) {
            problems.push(`${file}:${i + 1} stale caption line (captions are no longer used)`);
        }
    });
}

console.log(`checked ${checked} image references across ${files.length} chapters`);

// figure assets that no chapter references any more
const orphans = fs
    .readdirSync(imagesDir)
    .filter((f) => /^fig-?\d+-\d+\.(png|mmd)$/.test(f))
    .filter((f) => !referenced.has(f))
    .sort();

if (orphans.length) {
    console.log(`\n${orphans.length} ORPHANED ASSET(S) - not referenced by any chapter:`);
    orphans.forEach((o) => console.log('  ' + o));
}

if (problems.length) {
    console.log(`\n${problems.length} PROBLEM(S):`);
    problems.forEach((p) => console.log('  ' + p));
    process.exit(1);
}
console.log('OK - alt text, explanatory paragraphs, PNG and MMD sources all in sync');
