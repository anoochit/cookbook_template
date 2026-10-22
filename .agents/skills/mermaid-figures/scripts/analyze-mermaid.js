/**
 * Reports the Mermaid blocks and captions found in every chapter.
 *
 * Usage: node .agents/skills/mermaid-figures/scripts/analyze-mermaid.js
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

const chaptersDir = path.join(findRepoRoot(__dirname), 'chapters');
const files = fs.readdirSync(chaptersDir).filter(f => f.endsWith('.md')).sort();

let total = 0;
const report = [];

for (const file of files) {
    const full = path.join(chaptersDir, file);
    const lines = fs.readFileSync(full, 'utf8').split(/\r?\n/);
    const blocks = [];

    for (let i = 0; i < lines.length; i++) {
        if (lines[i].trim() === '```mermaid') {
            let j = i + 1;
            while (j < lines.length && lines[j].trim() !== '```') j++;
            if (j >= lines.length) { report.push(`${file}: UNCLOSED block at line ${i+1}`); continue; }
            blocks.push({ start: i, end: j, body: lines.slice(i + 1, j) });
            i = j;
        }
    }

    blocks.forEach((b, idx) => {
        total++;
        // scan forward for caption within 5 lines
        let caption = null, capIdx = -1, gap = 0;
        for (let k = b.end + 1; k < Math.min(b.end + 6, lines.length); k++) {
            const t = lines[k].trim();
            if (t === '') { gap++; continue; }
            const m = t.match(/^\*ไดอะแกรมที่\s*([\d]+)\.([\d]+)\s*[:.]?\s*(.*?)\*$/);
            if (m) { caption = m; capIdx = k; }
            break;
        }
        if (!caption) {
            report.push(`${file} block#${idx + 1} (line ${b.start + 1}): NO CAPTION within 5 lines -> next: ${JSON.stringify(lines[b.end + 1] || '')}`);
        } else {
            const figNo = `${caption[1]}.${caption[2]}`;
            const chNo = file.slice(0, 2);
            if (caption[1] !== String(Number(chNo))) {
                report.push(`${file} block#${idx + 1}: caption ${figNo} does not match chapter number ${chNo}`);
            }
            report.push(`  OK ${file} ${figNo} gap=${gap} desc="${caption[3].slice(0, 60)}"`);
        }
    });
}

console.log(`TOTAL MERMAID BLOCKS: ${total}`);
console.log(report.filter(r => !r.startsWith('  OK')).join('\n'));
console.log('--- issues above (empty = all good) ---');
