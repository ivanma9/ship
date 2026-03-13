import { readdirSync, statSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { gzipSync } from 'node:zlib';

const distDir = resolve(process.cwd(), 'dist');

if (!existsSync(distDir)) {
  console.error('dist directory not found. Run build first.');
  process.exit(1);
}

function walk(dir) {
  let total = 0;
  const entries = readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      total += walk(fullPath);
    } else if (entry.isFile()) {
      total += statSync(fullPath).size;
    }
  }
  return total;
}

const totalBytes = walk(distDir);
const totalKb = (totalBytes / 1024).toFixed(2);
const totalMb = (totalBytes / (1024 * 1024)).toFixed(2);

// Compute entryChunkGzipKb: gzip size of the largest .js in dist/assets/
const distAssetsDir = join(distDir, 'assets');
let entryChunkGzipKb = null;
let entryChunkName = null;
if (existsSync(distAssetsDir)) {
  const jsFiles = readdirSync(distAssetsDir).filter(f => f.endsWith('.js'));
  let largestSize = 0;
  let largestFile = null;
  for (const file of jsFiles) {
    const fullPath = join(distAssetsDir, file);
    const content = readFileSync(fullPath);
    if (content.length > largestSize) {
      largestSize = content.length;
      largestFile = { name: file, content };
    }
  }
  if (largestFile) {
    const gzipped = gzipSync(largestFile.content);
    entryChunkGzipKb = Number((gzipped.length / 1024).toFixed(2));
    entryChunkName = largestFile.name;
  }
}

const payload = {
  generatedAt: new Date().toISOString(),
  distDir,
  totalBytes,
  totalKb: Number(totalKb),
  totalMb: Number(totalMb),
  entryChunkGzipKb,
  entryChunkName,
};

writeFileSync(join(distDir, 'bundle-size.json'), `${JSON.stringify(payload, null, 2)}\n`);
writeFileSync(
  join(distDir, 'bundle-size.txt'),
  `generatedAt=${payload.generatedAt}\ntotalBytes=${totalBytes}\ntotalKb=${totalKb}\ntotalMb=${totalMb}\nentryChunkGzipKb=${entryChunkGzipKb}\nentryChunkName=${entryChunkName}\n`
);

console.log(`Total dist output: ${totalBytes} bytes (${totalKb} KB, ${totalMb} MB)`);
console.log(`Saved: ${join(distDir, 'bundle-size.json')}`);
console.log(`Saved: ${join(distDir, 'bundle-size.txt')}`);
