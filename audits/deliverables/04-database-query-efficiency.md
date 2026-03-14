# 04 — Database Query Efficiency

**Category:** Database Query Efficiency
**Before Date:** 2026-03-10
**After Date:** 2026-03-13
**Sources:** `audits/database-query-efficiency-audit-2026-03-10.md`, `audits/artifacts/db-query-efficiency-baseline.json`, `audits/artifacts/db-query-efficiency-after.json`

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
