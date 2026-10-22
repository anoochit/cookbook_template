/**
 * Renders `images/figN-N.mmd` into `images/figN-N.png` with mermaid-cli.
 *
 * Usage:
 *   node .agents/skills/mermaid-figures/scripts/render-mermaid.js [--jobs N] [--chapter N] [--figure N.N]
 */
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

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
const imagesDir = path.join(root, 'images');
const configFile = path.join(__dirname, '..', 'references', 'mermaid-config.json');

function flagValue(name) {
    const i = process.argv.indexOf(name);
    return i >= 0 ? process.argv[i + 1] : undefined;
}

const jobsArg = process.argv.indexOf('--jobs');
const JOBS = jobsArg >= 0 ? Number(process.argv[jobsArg + 1]) : 4;
const CHAPTER = flagValue('--chapter');
const FIGURE = flagValue('--figure');

const sources = fs
    .readdirSync(imagesDir)
    .filter((f) => /^fig\d+-\d+\.mmd$/.test(f))
    .filter((f) => {
        const [, chap, seq] = f.match(/^fig(\d+)-(\d+)\.mmd$/);
        if (CHAPTER !== undefined && chap !== String(Number(CHAPTER))) return false;
        if (FIGURE !== undefined && `${chap}.${seq}` !== FIGURE) return false;
        return true;
    })
    .sort((a, b) => a.localeCompare(b, 'en', { numeric: true }));

function render(file) {
    return new Promise((resolve) => {
        const mmd = path.join(imagesDir, file);
        const png = path.join(imagesDir, file.replace(/^fig/, 'fig').replace(/\.mmd$/, '.png'));
        const args = [
            '-i', mmd,
            '-o', png,
            '-c', configFile,
            '-b', 'white',
            '--size', '1600',
            '-s', '4',
            '-q',
        ];
        const child = spawn('mmdc', args, { shell: true, stdio: ['ignore', 'ignore', 'pipe'] });
        let stderr = '';
        child.stderr.on('data', (d) => (stderr += d.toString()));
        child.on('close', (code) => {
            if (code !== 0) {
                console.error(`FAIL ${file} (exit ${code})\n${stderr.trim().split('\n').slice(-6).join('\n')}`);
                resolve(false);
            } else {
                resolve(true);
            }
        });
    });
}

async function main() {
    if (sources.length === 0) {
        console.error('No diagram sources matched the given filters.');
        process.exit(1);
    }
    const scope = CHAPTER !== undefined ? ` for chapter ${CHAPTER}` : FIGURE !== undefined ? ` for figure ${FIGURE}` : '';
    console.log(`rendering ${sources.length} diagram(s)${scope} with ${JOBS} parallel job(s)`);
    let done = 0;
    let failed = 0;
    const queue = sources.slice();

    const workers = Array.from({ length: Math.min(JOBS, sources.length) }, async () => {
        while (queue.length) {
            const file = queue.shift();
            const ok = await render(file);
            done++;
            if (!ok) failed++;
            if (done % 10 === 0 || done === sources.length) {
                console.log(`  ${done}/${sources.length} (${failed} failed)`);
            }
        }
    });

    await Promise.all(workers);
    console.log(failed ? `DONE with ${failed} failure(s)` : 'DONE - all diagrams rendered');
    process.exit(failed ? 1 : 0);
}

main();
