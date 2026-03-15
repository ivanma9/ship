# 03 — API Response Time

**Category:** API Response Time
**Before Date:** 2026-03-10
**After Date:** 2026-03-12
**Source:** `audits/api-response-time.md`

**How to Reproduce:**
```bash
# Pre-requisites: pnpm dev running (API on :3000), DB seeded
node audits/scripts/api-benchmark.mjs
# Output: audits/artifacts/api-benchmark-result.json
```

Response times were measured using ApacheBench (`ab`) and `k6` against a local API (`http://127.0.0.1:3000`) with local PostgreSQL at a seeded data volume of 572 documents, 104 issues, 26 users, and 35 sprints. Benchmarks were run at three concurrency levels (c10, c25, c50). Results below use c50 as the primary comparison tier, consistent with the audit deliverable definition. P50/P95/P99 values are from the `ab` tool unless noted.

---

## Before — c50 Benchmark (AB)

_Source: `audits/api-response-time.md`, "Full Baseline Results (AB)"_

| Endpoint | P50 (ms) | P95 (ms) | P99 (ms) |
|----------|--------:|---------:|---------:|
| `/api/documents?type=wiki` | 101 | 123 | 131 |
| `/api/issues` | 87 | 105 | 116 |
| `/api/projects` | 42 | 54 | 58 |
| `/api/weeks` | 39 | 46 | 53 |
| `/api/programs` | 30 | 36 | 40 |

### Before — Full Concurrency Matrix (AB, P50/P95/P99 ms)

| Endpoint | c10 | c25 | c50 |
|----------|-----|-----|-----|
| `/api/documents?type=wiki` | 22 / 35 / 47 | 51 / 65 / 73 | 101 / 123 / 131 |
| `/api/issues` | 17 / 28 / 41 | 41 / 55 / 61 | 87 / 105 / 116 |
| `/api/projects` | 9 / 14 / 20 | 21 / 69 / 82 | 42 / 54 / 58 |
| `/api/programs` | 6 / 10 / 12 | 15 / 20 / 21 | 30 / 36 / 40 |
| `/api/weeks` | 8 / 12 / 15 | 20 / 25 / 28 | 39 / 46 / 53 |

---

## After — Optimization Results (Branch: 005-api-latency-list-endpoints, 2026-03-12)

_Source: `audits/api-response-time.md`, "Before / After Benchmark"_

### Changes Applied

| Change | Detail |
|--------|--------|
| Migration 038 — `idx_documents_list_active_type` | Composite partial index on `(workspace_id, document_type, position ASC, created_at DESC) WHERE archived_at IS NULL AND deleted_at IS NULL` |
| Migration 038 — `idx_documents_person_workspace_user` | Composite partial index on `(workspace_id, (properties->>'user_id')) WHERE document_type = 'person'`; converts Nested Loop Join to Hash Join |
| `/api/issues` list query | Removed `d.content` from SELECT (not needed for list view) |

### After — P95 Benchmark Comparison (AB)

| Endpoint | Concurrency | Before P95 (ms) | After P95 (ms) | Delta | Target | Pass |
|----------|-------------|----------------:|---------------:|------:|--------|------|
| `/api/documents?type=wiki` | c10 | 35 | 3 | −91% | — | — |
| `/api/documents?type=wiki` | c25 | 65 | 5 | −92% | — | — |
| `/api/documents?type=wiki` | c50 | 123 | **8** | **−94%** | ≤98ms | PASS |
| `/api/issues` | c10 | 28 | 2 | −93% | — | — |
| `/api/issues` | c25 | 55 | 6 | −89% | — | — |
| `/api/issues` | c50 | 105 | **7** | **−93%** | ≤84ms | PASS |

### EXPLAIN ANALYZE Evidence

| Query | Before | After |
|-------|--------|-------|
| Wiki execution time | 1.4 ms | 0.6 ms |
| Wiki buffer hits | 24 | 7 |
| Issues execution time | 2.78 ms | 1.25 ms |
| Issues buffer hits | 2,527 | 32 |

---

## Summary

Both primary targets were met without requiring pagination fallbacks. The `/api/documents?type=wiki` P95 at c50 dropped from 123 ms to 8 ms (−94%); the `/api/issues` P95 at c50 dropped from 105 ms to 7 ms (−93%). The improvement came from two new composite partial indexes (migration 038) and removing the `content` column from the issues list query, reducing buffer hits from 2,527 to 32 on the issues path.

## Test Status

All unit tests pass: **547 tests across 36 test files**, 0 failures (vitest, 2026-03-15).
