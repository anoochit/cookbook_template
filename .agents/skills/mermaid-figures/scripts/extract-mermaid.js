/**
 * Extracts Mermaid diagrams from every chapter into `images/fig-N-N.mmd`
 * and removes the fenced block, leaving the image reference `![desc](images/figN-N.png)`
 * that the author already wrote right below the block.
 *
 * Usage: node .agents/skills/mermaid-figures/scripts/extract-mermaid.js [--dry-run]
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
const dryRun = process.argv.includes('--dry-run');

// optional pandoc link attributes, e.g. ![alt](images/fig1-1.png){width=180}
const IMAGE_RE = /^!\[(.+?)\]\(images\/(fig(\d+)-(\d+)\.png)\)(\{[^}]*\})?$/;

const files = fs.readdirSync(chaptersDir).filter((f) => f.endsWith('.md')).sort();

let written = 0;
const manifest = [];

for (const file of files) {
    const full = path.join(chaptersDir, file);
    const lines = fs.readFileSync(full, 'utf8').split(/\r?\n/);
    const out = [];
    let i = 0;

    while (i < lines.length) {
        if (lines[i].trim() !== '```mermaid') {
            out.push(lines[i]);
            i++;
            continue;
        }

        // collect the fenced block
        const start = i;
        let j = i + 1;
        while (j < lines.length && lines[j].trim() !== '```') j++;
        if (j >= lines.length) {
            throw new Error(`${file}: unclosed mermaid block at line ${start + 1}`);
        }
        const body = lines.slice(start + 1, j);
        i = j + 1;

        // the image reference below the block carries the figure number and the alt text
        let refIdx = -1;
        let ref = null;
        for (let k = i; k < Math.min(i + 6, lines.length); k++) {
            const t = lines[k].trim();
            if (t === '') continue;
            const m = t.match(IMAGE_RE);
            if (m) {
                ref = m;
                refIdx = k;
            }
            break;
        }
        if (!ref) {
            throw new Error(
                `${file}: no image reference (e.g. ![คำบรรยาย](images/figN-M.png)) found below the mermaid block at line ${start + 1}`,
            );
        }

        const chap = ref[3];
        const seq = ref[4];
        const desc = ref[1].trim();
        const mmdName = `fig-${chap}-${seq}.mmd`;
        const pngName = `fig${chap}-${seq}.png`;

        // write the mermaid source
        const mmdPath = path.join(imagesDir, mmdName);
        const mmdContent = body.join('\n').replace(/\s+$/, '') + '\n';
        if (!dryRun) fs.writeFileSync(mmdPath, mmdContent, 'utf8');

        // replace the block with the image reference (keeping any pandoc attributes) and drop the original copy
        out.push(lines[refIdx].trim());
        i = refIdx + 1;

        written++;
        manifest.push({ file, fig: `${chap}.${seq}`, mmd: `images/${mmdName}`, png: `images/${pngName}`, desc });
    }

    if (!dryRun) {
        const trailing = out.length && out[out.length - 1] === '' ? '' : '\n';
        fs.writeFileSync(full, out.join('\n') + trailing, 'utf8');
    }
}

console.log(`${dryRun ? '[dry-run] ' : ''}extracted ${written} diagrams`);
for (const m of manifest) {
    console.log(`  ${m.file.padEnd(42)} fig ${m.fig.padEnd(6)} -> ${m.mmd} / ${m.png}`);
}
