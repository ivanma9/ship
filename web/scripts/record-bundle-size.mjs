import { readdirSync, statSync, writeFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';

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

const payload = {
  generatedAt: new Date().toISOString(),
  distDir,
  totalBytes,
  totalKb: Number(totalKb),
  totalMb: Number(totalMb),
};

writeFileSync(join(distDir, 'bundle-size.json'), `${JSON.stringify(payload, null, 2)}\n`);
writeFileSync(
  join(distDir, 'bundle-size.txt'),
  `generatedAt=${payload.generatedAt}\ntotalBytes=${totalBytes}\ntotalKb=${totalKb}\ntotalMb=${totalMb}\n`
);

console.log(`Total dist output: ${totalBytes} bytes (${totalKb} KB, ${totalMb} MB)`);
console.log(`Saved: ${join(distDir, 'bundle-size.json')}`);
console.log(`Saved: ${join(distDir, 'bundle-size.txt')}`);
