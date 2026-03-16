# 04 — Database Query Efficiency

**Audit Date:** 2026-03-10 · **Remediation Completed:** 2026-03-15

---

## Before

_Source: `audits/artifacts/db-query-efficiency-baseline.json` (captured 2026-03-10T06:34:08Z)_

| User Flow | Total Queries | Slowest Query (ms) | N+1 Detected? | Repeated Query Count |
|-----------|-------------:|-------------------:|:-------------:|---------------------:|
| Load main page | 54 | 3.39 | Yes | 9 |
| View a document | 16 | 2.29 | No | 4 |
| List issues | 17 | 2.40 | No | 4 |
| Load sprint board | 14 | 2.24 | No | 3 |
| Search content | 5 | 1.00 | No | 1 |

---

## Fixes Applied

| Optimization | What Changed | Files Touched |
|---|---|---|
| Merge mention search into single CTE | People + document search merged via CTEs + `UNION ALL`; 2 queries → 1 | `api/src/routes/search.ts` |
| Programs N+1 fix | Correlated `COUNT(*)` subqueries (one per program row) replaced with `LEFT JOIN` derived tables aggregating once per workspace | `api/src/routes/programs.ts` |
| Covering composite indexes (migration 039) | Added `idx_doc_assoc_doc_type_related` and `idx_doc_assoc_related_type_doc` on `document_associations`; enables index-only scans across all routes using the junction table | `api/src/db/migrations/039_covering_indexes.sql` |
| Documents owner N+1 consolidation | Two divergent owner-lookup code paths (project vs sprint) merged into one unified query | `api/src/routes/documents.ts` |
| Dashboard O(n) status subquery → CTE | Per-project correlated `inferred_status` subquery (N executions) replaced with single `project_statuses` CTE | `api/src/routes/dashboard.ts` |
| Programs COUNT join reorder | Derived tables start from `document_associations` (using covering index) instead of full `documents` scan; soft-deleted items excluded from counts | `api/src/routes/programs.ts` |
| Weekly doc query merge | 3 separate queries for `weekly_plan`/`weekly_retro` merged into single `IN (...)` query | `api/src/routes/dashboard.ts` |
| Auth `/me` workspace dedup | Second `workspace_memberships` lookup replaced with `.find()` on already-fetched rows | `api/src/routes/auth.ts` |
| isAdmin cache in authMiddleware | `authMiddleware` membership SELECT extended to fetch `role`; stored as `req.isAdmin`; eliminates duplicate `workspace_memberships` query at all 74 `getVisibilityContext` call sites | `api/src/middleware/auth.ts`, `api/src/middleware/visibility.ts` |
| Throttled `last_activity` UPDATE | Session write gated behind 60 s threshold (matches existing cookie-refresh throttle); eliminates per-request DB write for back-to-back requests | `api/src/middleware/auth.ts` |

---

## After

_Source: `npx tsx audits/artifacts/db-query-efficiency-audit.ts` — run against seeded `ship_master` after all changes on branch `010-db-query-count-reduction` (2026-03-15)_

| User Flow | Before | After | Delta | Measurement Method | Status |
|-----------|-------:|------:|------:|---|:---:|
| Load main page | 54 | **39** | −15 (−28%) | `pool.query` instrumentation, 5-flow replay | ✅ |
| View a document | 16 | **9** | −7 (−44%) | same | ✅ |
| List issues | 17 | **9** | −8 (−47%) | same | ✅ |
| Load sprint board | 14 | **8** | −6 (−43%) | same | ✅ |
| Search content | 5 | **3** | −2 (−40%) | same + EXPLAIN ANALYZE (0.979 ms → 0.360 ms) | ✅ |
| **Total** | **106** | **68** | **−38 (−35.8%)** | | ✅ |

All five flows exceed the 20% query reduction target. Unit tests: **548 tests, 0 failures** (vitest, 2026-03-15).

---

## Measurement

```bash
# Pre-requisites: PostgreSQL running locally, DB seeded
pnpm db:seed

# Re-run query count audit (outputs per-flow counts)
npx tsx audits/artifacts/db-query-efficiency-audit.ts

# Spot-check EXPLAIN ANALYZE on search CTE
node audits/scripts/db-query-recheck.mjs
# Output: audits/artifacts/db-query-recheck-result.json
```

---

## Key Decisions

- **T012 (batch-insert for sprint backlog reorder) skipped** — the conditional trigger for T012 was "only if EXPLAIN ANALYZE shows the merged search query misses the latency target." Search content latency was 0.229 ms against a < 5 ms ceiling; target was met without a GIN `pg_trgm` index. A `pg_trgm` index would be a larger, higher-risk change and is not justified by current latency. No migration `038_query_efficiency_indexes.sql` was created.
- **Accountability N+1 not fully resolved** — `api/src/services/accountability.ts` N+1 for per-sprint standup checks was partially addressed (54 → 53 in the 2026-03-13 after run). The remaining reduction in `load_main_page` came from the isAdmin cache and throttled `last_activity` optimizations rather than full accountability batching.
- **Weekly doc savings not reflected in flow totals** — `previousWeekNumber` equals 0 in the test environment (week 1), so the old code issued 2 queries instead of 3; savings from the weekly doc merge are confirmed by code inspection but do not appear numerically in the audit script output for `load_main_page`.
