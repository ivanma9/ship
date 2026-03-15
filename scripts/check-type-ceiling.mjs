#!/usr/bin/env node
/**
 * check-type-ceiling.mjs
 *
 * CI ratchet: fails if core type violations exceed the current ceiling.
 * Run after type-violation-scan.cjs to enforce that violations can only go down.
 *
 * Usage:
 *   node scripts/check-type-ceiling.mjs
 *
 * To update the ceiling after legitimate improvements:
 *   node scripts/type-violation-scan.cjs --json | node -e \
 *     "const r=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); \
 *      console.log(r.core)" \
 *   # then update CEILING below
 */

import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ── Ceiling — update this after each improvement sprint ──────────────────────
const CEILING = 878; // measured 2026-03-15 after Phase 5 API layer type hardening (baseline was 1143)
// ─────────────────────────────────────────────────────────────────────────────

const output = execSync(`node ${path.join(__dirname, 'type-violation-scan.cjs')} --json`, {
  cwd: path.resolve(__dirname, '..'),
  encoding: 'utf8',
});

const result = JSON.parse(output);
const current = result.core;

console.log(`Type violation ceiling check`);
console.log(`  Ceiling : ${CEILING}`);
console.log(`  Current : ${current}`);

if (current > CEILING) {
  console.error(`\n  FAIL: core violations (${current}) exceed ceiling (${CEILING})`);
  console.error(`  Fix violations or update CEILING with justification.`);
  process.exit(1);
} else {
  const delta = CEILING - current;
  console.log(`  PASS: ${delta === 0 ? 'at ceiling' : `${delta} below ceiling`}`);
}
