# Reproducibility Gaps — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure every audit category has a concrete, runnable command that reproduces its key measurement, and add a standardized "How to Reproduce" section to all 7 deliverable files.

**Architecture:** Two new scripts cover the two hard gaps (Cat 3 and Cat 4). Then all 7 deliverables get a standardized reproduction block at the top. No changes to application code — audit scripts only.

**Tech Stack:** Node.js (ESM), ApacheBench (`/usr/sbin/ab`, already installed), Playwright (already installed), psql (already installed), existing `pnpm` commands.

---

## Context: Current State per Category

| # | Category | Reproduce Command Exists? | Gap |
|---|----------|:-------------------------:|-----|
| 1 | Type Safety | ✅ | None — `node scripts/type-violation-scan.cjs` |
| 2 | Bundle Size | ✅ | None — `pnpm build && node web/scripts/check-bundle-budget.mjs` |
| 3 | API Response Time | ❌ | No script — `ab` was run manually, results frozen in JSON |
| 4 | DB Query Efficiency | ❌ | No script — instrumented captures frozen in JSON, EXPLAIN ANALYZE was manual |
| 5 | Test Coverage | ✅ | None — `pnpm --filter @ship/api test:coverage` |
| 6 | Runtime Errors | ✅ | None — `node audits/artifacts/category6-console-recheck.mjs` |
| 7 | Accessibility | ⚠️ | Path mismatch in docs; script exists at wrong reference path |

---

## Task 1: Create `audits/scripts/api-benchmark.mjs` (Category 3)

This script reproduces the Cat 3 ApacheBench measurements. It logs in via the API, obtains a session cookie, then runs `ab` at c10/c25/c50 for each of the 5 key endpoints and prints a structured comparison against the documented targets.

**Files:**
- Create: `audits/scripts/api-benchmark.mjs`

**Step 1: Write the script**

```js
#!/usr/bin/env node
// audits/scripts/api-benchmark.mjs
// Reproduces the Category 3 API Response Time benchmark.
// Pre-requisites: pnpm dev running (API on :3000, web on :5173), seeded DB.
// Usage: node audits/scripts/api-benchmark.mjs

import { execSync, spawnSync } from 'child_process';
import fs from 'fs';
import https from 'https';
import http from 'http';

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

// Login and get session cookie via curl
function login() {
  const result = spawnSync('curl', [
    '-s', '-c', COOKIE_FILE, '-b', COOKIE_FILE,
    '-X', 'POST', `${API}/api/auth/login`,
    '-H', 'Content-Type: application/json',
    '-d', JSON.stringify({ email: EMAIL, password: PASSWORD }),
  ], { encoding: 'utf8' });
  if (result.status !== 0) throw new Error('Login curl failed: ' + result.stderr);
  const body = JSON.parse(result.stdout);
  if (!body.user) throw new Error('Login failed — no user in response: ' + result.stdout);
  console.log('Logged in as:', body.user.email);
}

// Parse ab output to extract p50/p95/p99
function parseAb(output) {
  const pct = {};
  for (const line of output.split('\n')) {
    const m = line.match(/^\s+(\d+)%\s+(\d+)/);
    if (m) pct[parseInt(m[1])] = parseInt(m[2]);
  }
  return {
    p50: pct[50] ?? null,
    p95: pct[95] ?? null,
    p99: pct[99] ?? null,
  };
}

// Run ab benchmark for one endpoint + concurrency level
function runAb(path, c, n) {
  // Extract session cookie value from curl cookie file
  const cookieContent = fs.readFileSync(COOKIE_FILE, 'utf8');
  const sidMatch = cookieContent.match(/connect\.sid\s+(\S+)/);
  const sessionMatch = cookieContent.match(/session_id\s+(\S+)/);
  const cookieHeader = [
    sidMatch ? `connect.sid=${sidMatch[1]}` : null,
    sessionMatch ? `session_id=${sessionMatch[1]}` : null,
  ].filter(Boolean).join('; ');

  const result = spawnSync('ab', [
    '-n', String(n),
    '-c', String(c),
    '-H', `Cookie: ${cookieHeader}`,
    '-q',
    `${API}${path}`,
  ], { encoding: 'utf8', timeout: 60000 });

  if (result.status !== 0 && result.status !== null) {
    console.warn(`  ab exited ${result.status} for ${path} c${c}`);
  }
  return parseAb(result.stdout + result.stderr);
}

async function run() {
  console.log('=== Category 3 — API Response Time Benchmark ===');
  console.log(`API: ${API}`);
  console.log('');

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

  const out = {
    capturedAt: new Date().toISOString(),
    api: API,
    results,
    summary: { pass: targets.pass, fail: targets.fail },
  };

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
```

**Step 2: Run it to verify it works**

```bash
cd /Users/ivanma/Desktop/gauntlet/ShipShape/ship && node audits/scripts/api-benchmark.mjs
```

Expected: All 5 endpoints benchmarked, targets for `/api/documents?type=wiki` and `/api/issues` show `PASS ✅`. Takes ~2 minutes.

If it fails to login, run `pnpm db:seed` first and ensure `pnpm dev` is running.

**Step 3: Add "How to Reproduce" block to `audits/deliverables/03-api-response-time.md`**

Add this directly after the header block (after line 9, before the first `---`):

```markdown
**How to Reproduce:**
```bash
# Pre-requisites: pnpm dev running (API on :3000), DB seeded
node audits/scripts/api-benchmark.mjs
# Output: audits/artifacts/api-benchmark-result.json
```
```

**Step 4: Commit**

```bash
git add audits/scripts/api-benchmark.mjs audits/deliverables/03-api-response-time.md
git commit -m "feat(audit): add automated api-benchmark.mjs for cat3 reproducibility

Why: The Cat3 API response time measurements had no re-run script —
results were frozen in JSON artifacts only. This script reproduces
the ab benchmark at c10/c25/c50 for all 5 key endpoints."
```

---

## Task 2: Create `audits/scripts/db-query-recheck.mjs` (Category 4)

This script reproduces the two key Cat 4 EXPLAIN ANALYZE measurements (search CTE and accountability sprint query). It connects to PostgreSQL directly via `psql` and runs the same queries with `EXPLAIN ANALYZE`.

The query count captures (5 user flows) are not re-scripted here — those required server-side `pool.query` instrumentation and the frozen artifacts serve as the reference. This script covers the EXPLAIN ANALYZE evidence which is the more rigorous measurement.

**Files:**
- Create: `audits/scripts/db-query-recheck.mjs`

**Step 1: Write the script**

```js
#!/usr/bin/env node
// audits/scripts/db-query-recheck.mjs
// Reproduces the Category 4 EXPLAIN ANALYZE measurements.
// Pre-requisites: PostgreSQL running, ship DB seeded.
// Usage: node audits/scripts/db-query-recheck.mjs

import { spawnSync } from 'child_process';
import fs from 'fs';

// Read DATABASE_URL from api/.env.local
function getDbUrl() {
  try {
    const env = fs.readFileSync('api/.env.local', 'utf8');
    const match = env.match(/DATABASE_URL=(.+)/);
    if (match) return match[1].trim();
  } catch {}
  return process.env.DATABASE_URL || 'postgresql://localhost/ship_master';
}

function runExplain(dbUrl, sql) {
  const result = spawnSync('psql', [dbUrl, '-c', `EXPLAIN ANALYZE ${sql}`], {
    encoding: 'utf8',
    timeout: 15000,
  });
  if (result.status !== 0) throw new Error('psql failed: ' + result.stderr);
  return result.stdout;
}

function extractExecutionTime(explainOutput) {
  const match = explainOutput.match(/Execution Time:\s+([\d.]+) ms/);
  return match ? parseFloat(match[1]) : null;
}

const TARGET_MS = 5;

// The merged search CTE query (post-optimization)
const SEARCH_CTE_SQL = `
SELECT * FROM (
  WITH people AS (
    SELECT d.id, d.title, 'person' AS type,
           RANK() OVER (ORDER BY d.updated_at DESC) as rank
    FROM documents d
    WHERE d.workspace_id = (SELECT id FROM workspaces LIMIT 1)
      AND d.document_type = 'person'
      AND d.deleted_at IS NULL
      AND d.title ILIKE '%a%'
    LIMIT 10
  ),
  docs AS (
    SELECT d.id, d.title, d.document_type AS type,
           RANK() OVER (ORDER BY d.updated_at DESC) as rank
    FROM documents d
    WHERE d.workspace_id = (SELECT id FROM workspaces LIMIT 1)
      AND d.document_type IN ('wiki', 'issue', 'project', 'sprint')
      AND d.deleted_at IS NULL
      AND d.title ILIKE '%a%'
    LIMIT 10
  )
  SELECT id, title, type, rank FROM people
  UNION ALL
  SELECT id, title, type, rank FROM docs
) combined
ORDER BY rank
LIMIT 20;
`;

// The accountability sprint batched query (post-optimization)
const ACCOUNTABILITY_SQL = `
SELECT da.document_id AS issue_id, da.related_id AS sprint_id
FROM document_associations da
JOIN documents sprint ON sprint.id = da.related_id
  AND sprint.document_type = 'sprint'
  AND sprint.workspace_id = (SELECT id FROM workspaces LIMIT 1)
WHERE da.relationship_type = 'sprint'
  AND sprint.deleted_at IS NULL
LIMIT 100;
`;

async function run() {
  const dbUrl = getDbUrl();
  console.log('=== Category 4 — DB Query Efficiency EXPLAIN ANALYZE ===');
  console.log(`DB: ${dbUrl.replace(/:\/\/[^@]+@/, '://***@')}`);
  console.log('');

  const results = [];

  // Search CTE
  console.log('Running: Search Content (merged CTE query)...');
  const searchOutput = runExplain(dbUrl, SEARCH_CTE_SQL);
  const searchMs = extractExecutionTime(searchOutput);
  const searchPass = searchMs !== null && searchMs < TARGET_MS;
  console.log(`  Execution Time: ${searchMs} ms — target <${TARGET_MS}ms: ${searchPass ? 'PASS ✅' : 'FAIL ❌'}`);
  results.push({ query: 'Search CTE (merged)', executionMs: searchMs, targetMs: TARGET_MS, pass: searchPass });

  // Accountability sprint query
  console.log('\nRunning: Accountability Sprint (batched query)...');
  const acctOutput = runExplain(dbUrl, ACCOUNTABILITY_SQL);
  const acctMs = extractExecutionTime(acctOutput);
  const acctPass = acctMs !== null && acctMs < TARGET_MS;
  console.log(`  Execution Time: ${acctMs} ms — target <${TARGET_MS}ms: ${acctPass ? 'PASS ✅' : 'FAIL ❌'}`);
  results.push({ query: 'Accountability Sprint (batched)', executionMs: acctMs, targetMs: TARGET_MS, pass: acctPass });

  const out = {
    capturedAt: new Date().toISOString(),
    db: dbUrl.replace(/:\/\/[^@]+@/, '://***@'),
    results,
    allPassed: results.every(r => r.pass),
  };

  fs.mkdirSync('audits/artifacts', { recursive: true });
  const outFile = 'audits/artifacts/db-query-recheck-result.json';
  fs.writeFileSync(outFile, JSON.stringify(out, null, 2));

  console.log('\n=== Summary ===');
  if (out.allPassed) {
    console.log('All targets PASSED ✅');
  } else {
    results.filter(r => !r.pass).forEach(r => console.log(`FAIL: ${r.query} — ${r.executionMs}ms (target <${r.targetMs}ms)`));
  }
  console.log(`Result: ${outFile}`);
}

run().catch(e => { console.error(e); process.exit(1); });
```

**Step 2: Run it to verify it works**

```bash
cd /Users/ivanma/Desktop/gauntlet/ShipShape/ship && node audits/scripts/db-query-recheck.mjs
```

Expected output:
```
Search CTE (merged):        Execution Time: ~0.229 ms — PASS ✅
Accountability Sprint:      Execution Time: ~0.109 ms — PASS ✅
All targets PASSED ✅
```

**Step 3: Add "How to Reproduce" block to `audits/deliverables/04-database-query-efficiency.md`**

Add after the header block (after line 8, before the first `---`):

```markdown
**How to Reproduce (EXPLAIN ANALYZE):**
```bash
# Pre-requisites: PostgreSQL running, DB seeded
node audits/scripts/db-query-recheck.mjs
# Output: audits/artifacts/db-query-recheck-result.json
```

**Note on query counts:** User flow query counts (5 flows) were captured via server-side `pool.query` instrumentation. Reference artifacts: `audits/artifacts/db-query-efficiency-baseline.json` (before) and `audits/artifacts/db-query-efficiency-after.json` (after).
```

**Step 4: Commit**

```bash
git add audits/scripts/db-query-recheck.mjs audits/deliverables/04-database-query-efficiency.md
git commit -m "feat(audit): add automated db-query-recheck.mjs for cat4 reproducibility

Why: The Cat4 EXPLAIN ANALYZE measurements had no re-run script.
This script re-runs both key queries (search CTE and accountability
sprint) and confirms both meet the <5ms latency target."
```

---

## Task 3: Fix Path Mismatch in `07-accessibility-compliance.md`

**Files:**
- Modify: `audits/deliverables/07-accessibility-compliance.md`

**Step 1: Find the wrong path reference**

Search for `audits/accessibility/run-a11y-audit.mjs` in the file. The script actually lives at `audits/artifacts/accessibility/run-a11y-audit.mjs`.

**Step 2: Fix it**

Replace:
```
`audits/accessibility/run-a11y-audit.mjs`
```
With:
```
`audits/artifacts/accessibility/run-a11y-audit.mjs`
```

Also verify the "How to Reproduce" command in that file uses the correct path:
```bash
SHIP_BASE_URL=http://localhost:5173 node audits/artifacts/accessibility/run-a11y-audit.mjs
```

**Step 3: Commit**

```bash
git add audits/deliverables/07-accessibility-compliance.md
git commit -m "docs(audit): fix a11y audit script path reference in cat7 deliverable

Why: Deliverable referenced audits/accessibility/ but script is at
audits/artifacts/accessibility/ — wrong path would break reproduction."
```

---

## Task 4: Add "How to Reproduce" Sections to All 7 Deliverables

Add a standardized block near the top of each deliverable that doesn't already have one. Check each file first — if it already has a clear `**Reproducibility:**` line (like 01-type-safety.md), only add it if the format is inconsistent.

**Files to update:**
- `audits/deliverables/01-type-safety.md` — has `**Reproducibility:**` inline; standardize to block format
- `audits/deliverables/02-bundle-size.md` — check and add if missing
- `audits/deliverables/03-api-response-time.md` — done in Task 1
- `audits/deliverables/04-database-query-efficiency.md` — done in Task 2
- `audits/deliverables/05-test-coverage-quality.md` — check and add if missing
- `audits/deliverables/06-runtime-errors-edge-cases.md` — check and add if missing
- `audits/deliverables/07-accessibility-compliance.md` — check and add if missing

**Standardized block format** (add after the `**Sources:**` line in each file's header):

For Cat 01:
```markdown
**How to Reproduce:**
```bash
node scripts/type-violation-scan.cjs
# CI gate: node scripts/check-type-ceiling.mjs
```
```

For Cat 02:
```markdown
**How to Reproduce:**
```bash
pnpm build
node web/scripts/check-bundle-budget.mjs
# Output: PASS/FAIL with gzip size vs 275 KB budget
```
```

For Cat 05:
```markdown
**How to Reproduce:**
```bash
pnpm --filter @ship/api test:coverage
pnpm --filter @ship/web test:coverage
# E2E fixed-wait count: grep -c "waitForTimeout" e2e/*.spec.ts
```
```

For Cat 06:
```markdown
**How to Reproduce:**
```bash
# Console error count (page traversal):
node audits/artifacts/category6-console-recheck.mjs
# Collision/divergence test:
node audits/artifacts/category6-collision-recheck.mjs
```
```

For Cat 07:
```markdown
**How to Reproduce:**
```bash
# Pre-requisites: pnpm dev running on :5173, DB seeded
SHIP_BASE_URL=http://localhost:5173 node audits/artifacts/accessibility/run-a11y-audit.mjs
```
```

**Step 1: Read each file to find the exact insertion point**

For each file, read the top 15 lines to find where `**Sources:**` ends.

**Step 2: Insert the block after `**Sources:**`**

Use the Edit tool on each file.

**Step 3: Commit all 5 remaining deliverables at once**

```bash
git add audits/deliverables/01-type-safety.md \
        audits/deliverables/02-bundle-size.md \
        audits/deliverables/05-test-coverage-quality.md \
        audits/deliverables/06-runtime-errors-edge-cases.md \
        audits/deliverables/07-accessibility-compliance.md
git commit -m "docs(audit): add How to Reproduce sections to all 7 deliverables

Why: Every audit category now has a concrete, runnable command at the
top of its deliverable so measurements can be independently verified."
```
