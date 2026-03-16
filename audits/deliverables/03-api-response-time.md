# 03 — API Response Time

**Audit Date:** 2026-03-10 · **Remediation Completed:** 2026-03-12

## Before

_c50 concurrency, ApacheBench, local API on :3000, PostgreSQL seeded (572 docs, 104 issues, 26 users, 35 sprints)_

| Endpoint | P50 (ms) | P95 (ms) | P99 (ms) |
|----------|--------:|---------:|---------:|
| `/api/documents?type=wiki` | 101 | 123 | 131 |
| `/api/issues` | 87 | 105 | 116 |
| `/api/projects` | 42 | 54 | 58 |
| `/api/weeks` | 39 | 46 | 53 |
| `/api/programs` | 30 | 36 | 40 |

## Fixes Applied

| Change | Files Touched |
|--------|---------------|
| Migration 038 — composite partial index `idx_documents_list_active_type` on `(workspace_id, document_type, position ASC, created_at DESC) WHERE archived_at IS NULL AND deleted_at IS NULL` | `api/src/db/migrations/038_*.sql` |
| Migration 038 — composite partial index `idx_documents_person_workspace_user` on `(workspace_id, (properties->>'user_id')) WHERE document_type = 'person'`; converts Nested Loop Join to Hash Join | `api/src/db/migrations/038_*.sql` |
| `/api/issues` list query — removed `d.content` from SELECT (not needed for list view) | `api/src/routes/issues.ts` |

## After

| Endpoint | Before P95 c50 (ms) | After P95 c50 (ms) | Delta | Target | Status |
|----------|--------------------:|-------------------:|------:|--------|--------|
| `/api/documents?type=wiki` | 123 | **8** | −94% | ≤98 ms | PASS |
| `/api/issues` | 105 | **7** | −93% | ≤84 ms | PASS |

**EXPLAIN ANALYZE buffer hits (c50 path):**

| Query | Before | After | Measurement |
|-------|-------:|------:|-------------|
| Wiki execution time | 1.4 ms | 0.6 ms | `EXPLAIN (ANALYZE, BUFFERS)` |
| Wiki buffer hits | 24 | 7 | `EXPLAIN (ANALYZE, BUFFERS)` |
| Issues execution time | 2.78 ms | 1.25 ms | `EXPLAIN (ANALYZE, BUFFERS)` |
| Issues buffer hits | 2,527 | 32 | `EXPLAIN (ANALYZE, BUFFERS)` |

**Test status:** 548 tests across 37 test files, 0 failures (vitest, 2026-03-15).

## Measurement

```bash
# Pre-requisites: pnpm dev running (API on :3000), DB seeded
node audits/scripts/api-benchmark.mjs
# Output: audits/artifacts/api-benchmark-result.json
```

## Key Decisions

- Targets were set at 80% of the c50 P95 baseline (98 ms for wikis, 84 ms for issues); both were cleared by a wide margin without requiring pagination fallbacks.
- Removing `d.content` from the issues list query was the single largest contributor to the buffer-hit reduction (2,527 → 32), since the content column is wide TOAST data never displayed in list views.
