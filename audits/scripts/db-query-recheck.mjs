#!/usr/bin/env node
// audits/scripts/db-query-recheck.mjs
// Reproduces the Category 4 DB Query Efficiency EXPLAIN ANALYZE measurements.
// Pre-requisites: PostgreSQL running, DB seeded.
// Usage: node audits/scripts/db-query-recheck.mjs

import { spawnSync } from 'child_process';
import fs from 'fs';

function getDbUrl() {
  try {
    const env = fs.readFileSync('api/.env.local', 'utf8');
    const match = env.match(/DATABASE_URL=(.+)/);
    if (match) return match[1].trim();
  } catch {}
  return process.env.DATABASE_URL || 'postgresql://localhost/ship_master';
}

function runExplain(dbUrl, label, sql) {
  const result = spawnSync('psql', [dbUrl, '-c', `EXPLAIN ANALYZE ${sql}`], {
    encoding: 'utf8',
    timeout: 15000,
  });
  if (result.status !== 0) throw new Error(`psql failed for "${label}": ` + (result.stderr || result.stdout));
  return result.stdout;
}

function extractExecutionTime(output) {
  const match = output.match(/Execution Time:\s+([\d.]+) ms/);
  return match ? parseFloat(match[1]) : null;
}

const TARGET_MS = 5;

// The merged search CTE query (post-optimization in search.ts)
const SEARCH_CTE_SQL = `
SELECT * FROM (
  WITH people AS (
    SELECT d.id, d.title, 'person'::text AS type,
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
  SELECT id, title, type::text, rank FROM docs
) combined
ORDER BY rank
LIMIT 20;
`;

// The accountability sprint batched query (post-optimization in accountability.ts)
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
  const redacted = dbUrl.replace(/:\/\/[^@]+@/, '://***@');
  console.log('=== Category 4 — DB Query Efficiency EXPLAIN ANALYZE ===');
  console.log(`DB: ${redacted}\n`);

  const results = [];

  // Search CTE
  console.log('Query 1: Search Content (merged CTE)...');
  const searchOut = runExplain(dbUrl, 'search-cte', SEARCH_CTE_SQL);
  const searchMs = extractExecutionTime(searchOut);
  const searchPass = searchMs !== null && searchMs < TARGET_MS;
  console.log(`  Execution Time: ${searchMs} ms — target <${TARGET_MS}ms: ${searchPass ? 'PASS ✅' : 'FAIL ❌'}`);
  results.push({ query: 'Search CTE (merged)', executionMs: searchMs, targetMs: TARGET_MS, pass: searchPass });

  // Accountability sprint
  console.log('\nQuery 2: Accountability Sprint (batched)...');
  const acctOut = runExplain(dbUrl, 'accountability', ACCOUNTABILITY_SQL);
  const acctMs = extractExecutionTime(acctOut);
  const acctPass = acctMs !== null && acctMs < TARGET_MS;
  console.log(`  Execution Time: ${acctMs} ms — target <${TARGET_MS}ms: ${acctPass ? 'PASS ✅' : 'FAIL ❌'}`);
  results.push({ query: 'Accountability Sprint (batched)', executionMs: acctMs, targetMs: TARGET_MS, pass: acctPass });

  const out = {
    capturedAt: new Date().toISOString(),
    db: redacted,
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
    results.filter(r => !r.pass).forEach(r =>
      console.log(`FAIL: ${r.query} — ${r.executionMs}ms (target <${r.targetMs}ms)`)
    );
  }
  console.log(`Result: ${outFile}`);
}

run().catch(e => { console.error(e); process.exit(1); });
