#!/usr/bin/env node
// audits/scripts/api-benchmark.mjs
// Reproduces the Category 3 API Response Time benchmark.
// Pre-requisites: pnpm dev running (API on :3000), DB seeded.
// Usage: node audits/scripts/api-benchmark.mjs

import { spawnSync } from 'child_process';
import fs from 'fs';

// Locate ab binary (macOS: /usr/sbin/ab, Linux: /usr/bin/ab)
const AB_PATH = process.env.AB_PATH ||
  (() => {
    for (const p of ['/usr/sbin/ab', '/usr/bin/ab']) {
      try { fs.accessSync(p, fs.constants.X_OK); return p; } catch {}
    }
    throw new Error('ApacheBench (ab) not found. Install apache2-utils or set AB_PATH env var.');
  })();

const API = process.env.API_URL || 'http://127.0.0.1:3000';
const EMAIL = 'dev@ship.local';
const PASSWORD = 'admin123';
const COOKIE_FILE = '/tmp/ship-benchmark-cookies.txt';
const OUT_FILE = 'audits/artifacts/api-benchmark-result.json';

const ENDPOINTS = [
  { path: '/api/documents?type=wiki', targetP95c50: 98 },
  { path: '/api/issues',              targetP95c50: 84 },
  { path: '/api/projects',            targetP95c50: null },
  { path: '/api/weeks',               targetP95c50: null },
  { path: '/api/programs',            targetP95c50: null },
];

const CONCURRENCY_LEVELS = [
  { c: 10,  n: 200 },
  { c: 25,  n: 500 },
  { c: 50,  n: 1000 },
];

function login() {
  // Step 1: fetch CSRF token (also sets session cookie)
  const csrfResult = spawnSync('curl', [
    '-s', '-c', COOKIE_FILE, '-b', COOKIE_FILE,
    `${API}/api/csrf-token`,
  ], { encoding: 'utf8' });
  if (csrfResult.status !== 0) throw new Error('CSRF fetch failed: ' + csrfResult.stderr);
  const csrfBody = JSON.parse(csrfResult.stdout);
  const csrfToken = csrfBody.token;
  if (!csrfToken) throw new Error('No CSRF token in response: ' + csrfResult.stdout);

  // Step 2: login with CSRF token header
  const result = spawnSync('curl', [
    '-s', '-c', COOKIE_FILE, '-b', COOKIE_FILE,
    '-X', 'POST', `${API}/api/auth/login`,
    '-H', 'Content-Type: application/json',
    '-H', `x-csrf-token: ${csrfToken}`,
    '-d', JSON.stringify({ email: EMAIL, password: PASSWORD }),
  ], { encoding: 'utf8' });
  if (result.status !== 0) throw new Error('Login curl failed: ' + result.stderr);
  const body = JSON.parse(result.stdout);
  const user = body.user ?? body.data?.user;
  if (!user) throw new Error('Login failed — no user in response: ' + result.stdout);
  console.log('Logged in as:', user.email);
}

function parseAb(output) {
  const pct = {};
  for (const line of output.split('\n')) {
    const m = line.match(/^\s+(\d+)%\s+(\d+)/);
    if (m) pct[parseInt(m[1])] = parseInt(m[2]);
  }
  return { p50: pct[50] ?? null, p95: pct[95] ?? null, p99: pct[99] ?? null };
}

function getCookieHeader() {
  const cookieContent = fs.readFileSync(COOKIE_FILE, 'utf8');
  const sidMatch = cookieContent.match(/connect\.sid\s+(\S+)/);
  const sessionMatch = cookieContent.match(/session_id\s+(\S+)/);
  return [
    sidMatch ? `connect.sid=${sidMatch[1]}` : null,
    sessionMatch ? `session_id=${sessionMatch[1]}` : null,
  ].filter(Boolean).join('; ');
}

function runAb(path, c, n) {
  const cookieHeader = getCookieHeader();
  const result = spawnSync(AB_PATH, [
    '-n', String(n),
    '-c', String(c),
    '-H', `Cookie: ${cookieHeader}`,
    '-q',
    `${API}${path}`,
  ], { encoding: 'utf8', timeout: 60000 });
  return parseAb(result.stdout + result.stderr);
}

async function run() {
  console.log('=== Category 3 — API Response Time Benchmark ===');
  console.log(`API: ${API}\n`);

  login();

  const results = [];
  const targets = { pass: [], fail: [] };

  for (const ep of ENDPOINTS) {
    console.log(`\nEndpoint: ${ep.path}`);
    for (const { c, n } of CONCURRENCY_LEVELS) {
      process.stdout.write(`  c${c} (n=${n})... `);
      const { p50, p95, p99 } = runAb(ep.path, c, n);
      const isTarget = c === 50 && ep.targetP95c50 !== null;
      const pass = isTarget ? p95 <= ep.targetP95c50 : null;
      console.log(`p50=${p50}ms p95=${p95}ms p99=${p99}ms${isTarget ? ` → target ≤${ep.targetP95c50}ms: ${pass ? 'PASS ✅' : 'FAIL ❌'}` : ''}`);
      const row = { endpoint: ep.path, concurrency: c, n, p50_ms: p50, p95_ms: p95, p99_ms: p99 };
      if (isTarget) { row.target_ms = ep.targetP95c50; row.passed = pass; }
      results.push(row);
      if (isTarget) (pass ? targets.pass : targets.fail).push(`${ep.path} c${c}`);
    }
  }

  const out = { capturedAt: new Date().toISOString(), api: API, results, summary: targets };
  fs.mkdirSync('audits/artifacts', { recursive: true });
  fs.writeFileSync(OUT_FILE, JSON.stringify(out, null, 2));

  console.log('\n=== Summary ===');
  if (targets.fail.length === 0) {
    console.log('All targets PASSED ✅');
  } else {
    console.log('FAILED targets:', targets.fail.join(', '));
  }
  console.log(`Result: ${OUT_FILE}`);
}

run().catch(e => { console.error(e); process.exit(1); });
