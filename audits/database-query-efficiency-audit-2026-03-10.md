# Database Query Efficiency Audit (Category 4)

Date: 2026-03-10  
Scope: Ship unified document model query efficiency  
Method: Instrumented `pool.query` at the API layer and replayed five authenticated user flows.

## Summary

- Baseline query counts were captured for five core flows.
- Two concrete inefficiencies were found: an N+1 pattern in action-items and an extra round-trip in mention search.
- Proposed changes are **not applied yet**. If applied, they reduce Search content from 5 to 4 queries (20%).
- In the audited search query family, estimated execution time drops from 0.979 ms to 0.360 ms (~63.2% faster).

## Audit Deliverable


| User Flow         | Total Queries | Slowest Query (ms) | N+1 Detected? |
| ----------------- | ------------- | ------------------ | ------------- |
| Load main page    | 54            | 3.39 ms            | Yes           |
| View a document   | 16            | 2.29 ms            | No            |
| List issues       | 17            | 2.40 ms            | No            |
| Load sprint board | 14            | 2.24 ms            | No            |
| Search content    | 5             | 1.00 ms            | No            |


## Inefficiencies Identified

1. `GET /api/accountability/action-items` has N+1 behavior in `checkMissingStandups` and `checkSprintAccountability` (`api/src/services/accountability.ts`).
  - Each sprint triggered separate queries for standup existence, last standup date, and issue counts.
2. `GET /api/search/mentions` executes separate database queries for people and documents (`api/src/routes/search.ts`).
  - This adds one extra query to each search request.
3. Search by title uses `%ILIKE%` on `documents.title`.
  - `EXPLAIN ANALYZE` shows a sequential scan on content documents for this dataset.

## Proposed Improvements (Not Applied)

- In `api/src/services/accountability.ts`:
  - Batch per-sprint standup checks and last-standup lookups into set-based queries.
  - Batch sprint issue counts instead of querying once per sprint.
- In `api/src/routes/search.ts`:
  - Merge people and document search into one SQL statement (CTEs + `UNION ALL`) while preserving per-source limits.

## Projected Metrics (If Applied)


| User Flow         | Total Queries (Before) | Total Queries (Projected) | Improvement |
| ----------------- | ---------------------- | ------------------------- | ----------- |
| Load main page    | 54                     | 53                        | 1.9%        |
| View a document   | 16                     | 16                        | 0.0%        |
| List issues       | 17                     | 17                        | 0.0%        |
| Load sprint board | 14                     | 14                        | 0.0%        |
| Search content    | 5                      | 4                         | **20.0%**   |


Target status: **Would be met if applied** (20% reduction in one audited flow: Search content).

Calculation:

- Baseline Search content flow: 5 queries
- Projected Search content flow: 4 queries
- Reduction: `(5 - 4) / 5 = 0.20` -> **20%**

## EXPLAIN ANALYZE Snapshot

Query family: Search content (`/api/search/mentions?q=pro`)

### Before (Two DB Queries)

- `old_people`: Execution Time **0.251 ms**
- `old_docs`: Execution Time **0.728 ms**
- Combined execution time: **0.979 ms**

Plan highlights:

- `old_people`: Bitmap Heap Scan on `documents` filtered by `document_type='person'`
- `old_docs`: Seq Scan on `documents` with `title ILIKE '%pro%'`

### After (Single Combined DB Query)

- `new_combined`: Execution Time **0.360 ms**

Plan highlights:

- Single `Append` plan with `people` and `content_docs` subqueries
- Same filter semantics and per-subquery limits preserved

Execution-time delta (query family):

- **0.979 ms -> 0.360 ms (~63.2% faster)**

## Files Changed

- `audits/artifacts/db-query-efficiency-audit.ts` (audit runner)
- `audits/artifacts/db-query-efficiency-baseline.json`
- `audits/artifacts/db-query-efficiency-after.json`
- `audits/artifacts/db-query-efficiency-after2.json`
- `audits/database-query-efficiency-audit-2026-03-10.md`

