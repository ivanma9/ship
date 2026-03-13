# API Response-Time Audit

Canonical record for Category 3 API response-time results.

## Scope

- Repository: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`
- Data volume used:
  - Documents: 572
  - Issues: 104
  - Users: 26
  - Sprints: 35
- Endpoints tested (common frontend flows):
  - `/api/documents?type=wiki`
  - `/api/issues`
  - `/api/projects`
  - `/api/programs`
  - `/api/weeks`
- Concurrency levels:
  - `c10` = 10 concurrent requests
  - `c25` = 25 concurrent requests
  - `c50` = 50 concurrent requests

## Method

- Ran authenticated benchmarks against local API `http://127.0.0.1:3000` with local PostgreSQL.
- Enabled `E2E_TEST=1` during runs to avoid rate-limit (`429`) contamination.
- Used two tools:
  - ApacheBench (`ab`) for baseline
  - `k6` for validation
- Reported P50/P95/P99 in milliseconds for each concurrency level.

## Audit deliverable Key Result (c50)

At 50-concurrency load, `/api/documents?type=wiki` and `/api/issues` are the slowest list endpoints and remain the primary optimization targets.

Metric format for this table: `(ab/k6)` in milliseconds.


| Audit Deliverable | Endpoint                   | P50             | P95             | P99             |
| ----------------- | -------------------------- | --------------- | --------------- | --------------- |
| 1                 | `/api/documents?type=wiki` | (101/110.92) ms | (123/138.65) ms | (131/153.41) ms |
| 2                 | `/api/issues`              | (87/97.48) ms   | (105/120.60) ms | (116/134.52) ms |
| 3                 | `/api/projects`            | (42/46.65) ms   | (54/57.40) ms   | (58/62.79) ms   |
| 4                 | `/api/weeks`               | (39/45.19) ms   | (46/54.22) ms   | (53/60.29) ms   |
| 5                 | `/api/programs`            | (30/34.79) ms   | (36/46.14) ms   | (40/49.59) ms   |


## Full Baseline Results (AB)


| Endpoint                   | c10 P50/P95/P99 (ms) | c25 P50/P95/P99 (ms) | c50 P50/P95/P99 (ms) |
| -------------------------- | -------------------- | -------------------- | -------------------- |
| `/api/documents?type=wiki` | 22/35/47             | 51/65/73             | 101/123/131          |
| `/api/issues`              | 17/28/41             | 41/55/61             | 87/105/116           |
| `/api/projects`            | 9/14/20              | 21/69/82             | 42/54/58             |
| `/api/programs`            | 6/10/12              | 15/20/21             | 30/36/40             |
| `/api/weeks`               | 8/12/15              | 20/25/28             | 39/46/53             |


## Full Validation Results (k6)


| Endpoint                   | c10 P50/P95/P99 (ms) | c25 P50/P95/P99 (ms) | c50 P50/P95/P99 (ms) |
| -------------------------- | -------------------- | -------------------- | -------------------- |
| `/api/documents?type=wiki` | 23.94/39.01/47.83    | 59.59/99.51/150.83   | 110.92/138.65/153.41 |
| `/api/issues`              | 17.72/32.80/59.52    | 48.70/108.85/140.73  | 97.48/120.60/134.52  |
| `/api/projects`            | 9.16/15.49/37.93     | 23.09/30.85/35.79    | 46.65/57.40/62.79    |
| `/api/programs`            | 6.60/9.84/13.20      | 17.40/38.64/47.49    | 34.79/46.14/49.59    |
| `/api/weeks`               | 8.34/16.34/23.61     | 20.97/30.33/35.69    | 45.19/54.22/60.29    |


## Notes

- Discarded one earlier AB run due to heavy rate-limiting and non-2xx responses.
- This file replaces earlier split API response-time and k6 report files.

## Improvement Plan

- Goal: reduce P95 by 20% on at least two endpoints under identical benchmark conditions.
- Primary targets (AB c50 baseline):
  - `/api/documents?type=wiki`: `123ms` -> `<=98ms`
  - `/api/issues`: `105ms` -> `<=84ms`

1. Reduce list-endpoint payload size.
2. Add targeted database indexes for current list query filters and sorts.
3. Re-run the same benchmark matrix (`c10/c25/c50`) with the same seeded volume.
4. Record before/after P95 deltas in this file.
5. If either target is missed, apply pagination/default limits and rerun.

## Optimization Results (Branch: 005-api-latency-list-endpoints, 2026-03-12)

### Changes Applied

1. **Migration 038** (`038_api_list_latency_indexes.sql`):
   - `idx_documents_list_active_type`: composite partial index on `(workspace_id, document_type, position ASC, created_at DESC) WHERE archived_at IS NULL AND deleted_at IS NULL` — enables planner to use Index Scan instead of filtering 250+ rows.
   - `idx_documents_person_workspace_user`: composite partial index on `(workspace_id, (properties->>'user_id')) WHERE document_type = 'person'` — converts Nested Loop Join (104 × 11 scans = 1040 extra rows) to Hash Join (single pass, 32 buffer hits vs 2527).
2. **`/api/issues` list query**: Removed `d.content` from SELECT (content is only needed for individual issue detail view, not list view).

### EXPLAIN ANALYZE Evidence

| Query | Before | After |
|-------|--------|-------|
| Wiki: execution time | 1.4ms | 0.6ms |
| Wiki: buffer hits | 24 | 7 |
| Issues: execution time | 2.78ms | 1.25ms |
| Issues: buffer hits | 2527 | 32 |

### Before / After Benchmark (AB, local PostgreSQL, seeded data)

| Endpoint | Concurrency | Before P95 (ms) | After P95 (ms) | Delta | Target | Pass |
|----------|-------------|-----------------|----------------|-------|--------|------|
| `/api/documents?type=wiki` | c10 | 35 | 3 | -91% | — | — |
| `/api/documents?type=wiki` | c25 | 65 | 5 | -92% | — | — |
| `/api/documents?type=wiki` | c50 | 123 | 8 | **-94%** | ≤98ms | ✅ PASS |
| `/api/issues` | c10 | 28 | 2 | -93% | — | — |
| `/api/issues` | c25 | 55 | 6 | -89% | — | — |
| `/api/issues` | c50 | 105 | 7 | **-93%** | ≤84ms | ✅ PASS |

Fallback pagination/default limits were **not needed** — direct DB and payload optimizations met both targets.

Artifacts: `audits/artifacts/api-latency-list-endpoints-before.json`, `audits/artifacts/api-latency-list-endpoints-after.json`


### Rollout / Rollback

**Rollout** (already deployed to branch):
1. Migration `038_api_list_latency_indexes.sql` — apply via `pnpm db:migrate`.
2. API change: `d.content` removed from list SELECT in `api/src/routes/issues.ts`.
3. OpenAPI schemas updated (`documents.ts`, `issues.ts`) — no consumer changes needed.

**Rollback** (if latency regression or contract issues arise):
```sql
DROP INDEX IF EXISTS idx_documents_list_active_type;
DROP INDEX IF EXISTS idx_documents_person_workspace_user;
DELETE FROM schema_migrations WHERE version = '038_api_list_latency_indexes';
```
Then revert the `d.content` removal in `api/src/routes/issues.ts` list query (add `d.content,` back to SELECT at line ~126) and restore previous OpenAPI schema fields.
