# 04 — Database Query Efficiency

**Category:** Database Query Efficiency
**Before Date:** 2026-03-10
**After Date:** 2026-03-13
**Sources:** `audits/database-query-efficiency-audit-2026-03-10.md`, `audits/artifacts/db-query-efficiency-baseline.json`, `audits/artifacts/db-query-efficiency-after.json`

**How to Reproduce (EXPLAIN ANALYZE):**
```bash
# Pre-requisites: PostgreSQL running, DB seeded
node audits/scripts/db-query-recheck.mjs
# Output: audits/artifacts/db-query-recheck-result.json
```

**Note on query counts:** User flow query counts (5 flows) were captured via server-side `pool.query` instrumentation. Reference artifacts: `audits/artifacts/db-query-efficiency-baseline.json` (before) and `audits/artifacts/db-query-efficiency-after.json` (after).

Query counts were measured by instrumenting `pool.query` at the API layer and replaying five authenticated user flows. Each flow was executed against a locally running API and PostgreSQL instance with seeded data.

---

## Before — Query Counts per User Flow

_Source: `audits/artifacts/db-query-efficiency-baseline.json` (captured 2026-03-10T06:34:08Z)_

| User Flow | Total Queries | Slowest Query (ms) | N+1 Detected? | Repeated Query Count |
|-----------|-------------:|-------------------:|:-------------:|---------------------:|
| Load main page | 54 | 3.39 | Yes | 9 |
| View a document | 16 | 2.29 | No | 4 |
| List issues | 17 | 2.40 | No | 4 |
| Load sprint board | 14 | 2.24 | No | 3 |
| Search content | 5 | 1.00 | No | 1 |

### Before — EXPLAIN ANALYZE (Search Content Flow)

| Sub-query | Execution Time |
|-----------|---------------:|
| People search (separate query) | 0.251 ms |
| Document search (separate query) | 0.728 ms |
| Combined (two queries total) | 0.979 ms |

### Before — Identified Inefficiencies

| Issue | Location |
|-------|----------|
| N+1: per-sprint standup checks and issue counts | `api/src/services/accountability.ts` — `checkMissingStandups`, `checkSprintAccountability` |
| Extra round-trip: people and documents searched separately | `api/src/routes/search.ts` — mention search |
| Sequential scan: `%ILIKE%` on `documents.title` | `api/src/routes/search.ts` |

---

## After — Query Counts per User Flow

_Source: `audits/artifacts/db-query-efficiency-after.json` (captured 2026-03-13T01:11:57Z)_

| User Flow | Before Queries | After Queries | Delta | Notes |
|-----------|---------------:|--------------:|------:|-------|
| Load main page | 54 | 53 | −1 (−1.9%) | N+1 partially reduced |
| View a document | 16 | 16 | 0 | Unchanged |
| List issues | 17 | 17 | 0 | Unchanged |
| Load sprint board | 14 | 14 | 0 | Unchanged |
| Search content | 5 | **4** | **−1 (−20%)** | People + docs merged into one CTE query |
| Accountability action-items | — | 13 | new flow measured | Added in after run |

### After — EXPLAIN ANALYZE (Search Content — Combined Query)

| Query | Execution Time |
|-------|---------------:|
| New combined CTE (single query) | 0.360 ms |
| Before (two queries) | 0.979 ms |
| **Delta** | **−63.2%** |

### After — Changes Applied

| Change | Location |
|--------|----------|
| Merged people and document mention search into single SQL with CTEs + `UNION ALL` | `api/src/routes/search.ts` |

**Note:** The N+1 pattern in `accountability.ts` (Load main page: 54 → 53 queries) was partially addressed. Full batching of per-sprint standup checks was deferred. The Load main page still shows `nPlusOneDetected: true` with 9 repeated queries in the after artifact.

---

## Summary

The search content flow was the primary target and met the 20% query reduction goal: 5 queries → 4 queries (−20%) by merging the people and document search into a single combined CTE query, reducing execution time by 63.2% (0.979 ms → 0.360 ms). The N+1 pattern on the main page was reduced by 1 query but the pattern remains present. Other flows (view document, list issues, sprint board) were unchanged.

---

## 2026-03-14 Re-Baseline and EXPLAIN ANALYZE (T001, T002)

_Source: `audits/artifacts/db-query-efficiency-baseline.json` (re-captured 2026-03-14T16:33:08Z after fresh seed)_

### Re-Baseline — Query Counts per User Flow

| User Flow | Total Queries | Slowest Query (ms) | N+1 Detected? | Repeated Query Count |
|-----------|-------------:|-------------------:|:-------------:|---------------------:|
| Load main page | 52 | 4.12 | Yes | 9 |
| View a document | 16 | 2.49 | No | 4 |
| List issues | 17 | 4.11 | No | 4 |
| Load sprint board | 16 | 1.98 | No | 3 |
| Accountability action-items | 12 | 1.38 | No | 2 |
| Search content | 4 | 1.40 | No | 1 |

**Observation:** Search content is already at 4 queries (the post-optimization level). The accountability flow dropped from 13 to 12 queries vs the 2026-03-13 after run. The main page N+1 (9 repeated queries) persists.

### EXPLAIN ANALYZE — Search Content (Merged CTE Query)

Run against `ship_master` with seeded data on 2026-03-14:

```
Execution Time: 0.229 ms
Planning Time:  1.537 ms
Plan: Sort → Append → (WindowAgg+IncrementalSort on person bitmap scan) + (WindowAgg+IncrementalSort on doc seq scan)
```

| Metric | Value |
|--------|------:|
| Execution time | 0.229 ms |
| Planning time | 1.537 ms |
| Plan type | Bitmap Index Scan (people) + Seq Scan (documents, 4 types) |
| Result rows | 0 (empty seeded search; plan is stable) |

**Assessment:** 0.229 ms execution time is well within the latency target (< 5 ms). The plan uses `idx_documents_person_user_id` bitmap index for person lookups and a seq scan for documents (appropriate given the small local dataset and `ILIKE '%a%'` wildcard that precludes B-tree prefix optimization). The plan is **stable** across runs.

### EXPLAIN ANALYZE — Accountability Hotspot (Sprint Batched Query)

Run against `ship_master` with seeded data on 2026-03-14:

```
Execution Time: 0.109 ms
Planning Time:  2.086 ms
Plan: Hash Right Join (document_associations ⋈ sprint documents)
```

| Metric | Value |
|--------|------:|
| Execution time | 0.109 ms |
| Planning time | 2.086 ms |
| Plan type | Hash Right Join (sprint docs → document_associations) |
| Result rows | 0 (empty for this workspace/sprint combination) |

**Assessment:** 0.109 ms is well within target. The plan uses a Hash Join between documents and document_associations — correct and stable for this query shape.

### T012 Decision — Conditional Title-Search Index

**Outcome: T012 SKIPPED / N/A**

Evidence:
- Search content flow latency: 0.229 ms (target: < 5 ms) — **target met**
- Accountability sprint query latency: 0.109 ms — **target met**
- Both plans are stable (consistent across repeated audit runs: 2026-03-13 after2.json and 2026-03-14 re-baseline)
- The `%ILIKE%` wildcard in title search means a B-tree title index would not be used by the planner; a GIN `pg_trgm` index would be needed, which is a larger change with more risk and is not justified by current latency

**No migration `038_query_efficiency_indexes.sql` is needed.** The conditional in T012 ("only if repeated seeded runs or EXPLAIN ANALYZE show the merged search query misses the latency target") is not triggered.
