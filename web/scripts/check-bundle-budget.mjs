import { readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { gzipSync } from 'node:zlib';

// Budget config
// Baseline (2026-03-09 audit): 587.59 KB gzip
// Post-optimization (2026-03-13, after 006-bundle-size-reduction): 259.97 KB gzip
// Budget = Math.ceil(actual * 1.05 / 5) * 5 = 275 KB
const BUDGETS = {
  entryChunkMaxGzipKb: 275,
};

const distAssetsDir = resolve(process.cwd(), 'dist', 'assets');

let files;
try {
  files = readdirSync(distAssetsDir).filter(f => f.endsWith('.js'));
} catch {
  console.error('dist/assets directory not found. Run build first.');
  process.exit(1);
}

if (files.length === 0) {
  console.error('No .js files found in dist/assets/. Run build first.');
  process.exit(1);
}

// Find the largest JS file (entry chunk heuristic: largest chunk)
let largestFile = null;
let largestSize = 0;

for (const file of files) {
  const fullPath = join(distAssetsDir, file);
  const content = readFileSync(fullPath);
  if (content.length > largestSize) {
    largestSize = content.length;
    largestFile = { name: file, content };
  }
}

// Gzip in memory
const gzipped = gzipSync(largestFile.content);
const gzipKb = gzipped.length / 1024;

const budget = BUDGETS.entryChunkMaxGzipKb;

if (gzipKb > budget) {
  console.error(
    `BUDGET EXCEEDED: ${largestFile.name} = ${gzipKb.toFixed(2)} KB gzip (budget: ${budget} KB)`
  );
  process.exit(1);
} else {
  console.log(
    `Bundle budget OK: ${largestFile.name} = ${gzipKb.toFixed(2)} KB gzip (budget: ${budget} KB)`
  );
  process.exit(0);
}
