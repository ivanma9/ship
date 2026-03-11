# Consolidated Audit Report

**Repository:** `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`  
**Consolidation Date:** 2026-03-10

This document consolidates all audit reports in a single reference. Audits are presented in the following order:

1. [Type Safety Audit](#1-type-safety-audit)
2. [Bundle Size Audit](#2-bundle-size-audit)
3. [API Response Time](#3-api-response-time)
4. [Database Query Efficiency](#4-database-query-efficiency)
5. [Test Coverage and Quality](#5-test-coverage-and-quality)
6. [Runtime Errors and Edge Cases](#6-runtime-errors-and-edge-cases)
7. [Accessibility Compliance](#7-accessibility-compliance)

---

## 1. Type Safety Audit

*Source: `audits/type-safety-audit-2026-03-09.md`*

### 1. Scope

- Category: Type Safety
- Repository: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`
- Audit scope:
  - Scanned TypeScript source in `api/`, `web/`, and `shared/` (`.ts`, `.tsx`, excluding `.d.ts`)
  - Primary counts come from an AST-based scan (not lint rule output)

### 2. Measurement Method

#### Strict mode check

- Tools: `rg`, `cat`
- Command:

```bash
for f in tsconfig.json api/tsconfig.json web/tsconfig.json shared/tsconfig.json; do
  echo "--- $f"
  rg -n '"strict"|"noImplicitAny"|"strictNullChecks"' "$f"
done
```

#### Type-safety count scan

- Tool: Node.js + TypeScript AST script
- Command:

```bash
node .tmp_type_safety_audit.cjs > /tmp/type_safety_results.json
```

- Categories counted:
  - `any`
  - `as` assertions
  - non-null assertions (`!`)
  - `@ts-ignore` / `@ts-expect-error`
  - untyped function parameters
  - missing explicit return types

#### Method limits

- `untyped params` and `missing return types` are risk proxies, not direct correctness bugs
- Counts include inference-heavy callback and test code, which can inflate totals

### 3. Baseline Numbers

| Baseline                                | Value | Unit        | Context |
| --------------------------------------- | ----- | ----------- | ------- |
| Total `any` types                       | 262   | occurrences | 320 scanned files in `api/`, `web/`, `shared/` |
| Total `as` assertions                   | 691   | occurrences | Same scope |
| Total non-null assertions (`!`)         | 329   | occurrences | Same scope |
| Total `@ts-ignore` / `@ts-expect-error` | 1     | occurrences | Same scope |
| Strict mode enabled                     | Yes   | boolean     | Root has `strict: true`; `api`/`shared` inherit; `web` sets `strict: true` |
| Strict mode error count                 | N/A   | errors      | Not run, because strict mode is already enabled |
| Untyped function parameters             | 1451  | occurrences | Additional proxy metric |
| Missing explicit return types           | 4454  | occurrences | Additional proxy metric |
| Combined measured violations            | 7188  | occurrences | Sum of all six categories |

#### Per-package breakdown

| Package   | `any` | `as` | `!` | `@ts-ignore/@ts-expect-error` | untyped params | missing return types | Total |
| --------- | ----- | ---- | --- | ----------------------------- | -------------- | -------------------- | ----- |
| `api/`    | 229   | 317  | 296 | 0                             | 283            | 1246                 | 2371  |
| `web/`    | 33    | 372  | 33  | 1                             | 1168           | 3208                 | 4815  |
| `shared/` | 0     | 2    | 0   | 0                             | 0              | 0                    | 2     |

#### Top 5 dense files

| File                                      | Total | `any` | `as` | `!` | `@ts-` directives | untyped params | missing return types |
| ----------------------------------------- | ----- | ----- | ---- | --- | ----------------- | -------------- | -------------------- |
| `web/src/components/IssuesList.tsx`       | 189   | 0     | 4    | 0   | 0                 | 47             | 138                  |
| `web/src/pages/App.tsx`                   | 180   | 0     | 1    | 0   | 0                 | 30             | 149                  |
| `api/src/routes/weeks.ts`                 | 159   | 11    | 26   | 48  | 0                 | 24             | 50                   |
| `web/src/hooks/useSessionTimeout.test.ts` | 159   | 0     | 2    | 0   | 0                 | 0              | 157                  |
| `web/src/pages/ReviewsPage.tsx`           | 150   | 0     | 6    | 4   | 0                 | 57             | 83                   |

#### Top 5 violation-dense files list (with counts)

1. `web/src/components/IssuesList.tsx`: 189
2. `web/src/pages/App.tsx`: 180
3. `api/src/routes/weeks.ts`: 159
4. `web/src/hooks/useSessionTimeout.test.ts`: 159
5. `web/src/pages/ReviewsPage.tsx`: 150

#### Improvement target conversion (25%)

- Expanded six-metric view: baseline `7188`; 25% reduction target `1797`
- Core-metric target (`any` + `as` + `!` + `@ts-*`) is defined in the Improvement Plan

### 4. Findings (Ranked)

1. **P1 weakness: `api/src/routes/weeks.ts` is the highest-risk API hotspot**
   - Evidence: 159 total in one file (11 `any`, 26 `as`, 48 `!`), file length 3156 lines
   - Why it matters: Cast/non-null-heavy request and query handling can fail at runtime when assumptions break
   - Scope: Week planning routes and related downstream calculations

2. **P1 weakness: `web/` holds most type-safety debt**
   - Evidence: `web/` has 1168 untyped params and 3208 missing return types; top dense files include `IssuesList.tsx`, `App.tsx`, and `ReviewsPage.tsx`
   - Why it matters: Refactors are harder and regressions are easier in core UI state/event flows
   - Scope: Main app shell, list flows, and review workflows

3. **P2 opportunity: suppression is low, assertion use is high**
   - Evidence: only 1 suppression directive, but 691 `as` assertions
   - Why it matters: Good enforcement baseline already exists; replacing high-risk assertions with guards should reduce risk quickly
   - Scope: API request parsing and web event/value coercion

4. **P2 weakness: proxy metrics are inflated by tests/callback-heavy files**
   - Evidence: `web/src/hooks/useSessionTimeout.test.ts` has 157 missing return types and appears in top-5 dense files
   - Why it matters: Raw counts can mislead prioritization if production and test paths are not separated
   - Scope: `web/` tests and callback-heavy modules

5. **P3 success: `shared/` is nearly clean**
   - Evidence: 2 total violations (2 `as`, zero in other categories)
   - Why it matters: Shared contracts are stable and can serve as the repo quality baseline
   - Scope: Shared types/contracts

### 5. Notable Successes

- Strict mode is enabled across repository configuration
- Suppression directives are effectively absent (1 total)
- `shared/` has very low violation density

### 6. Residual Risk Summary

- Highest-risk areas:
  - `api/src/routes/weeks.ts`
  - `web/src/pages/App.tsx`
  - `web/src/components/IssuesList.tsx`
  - `web/src/pages/ReviewsPage.tsx`
- Confidence:
  - Medium-high for hotspot ranking
  - Medium for absolute defect risk (two metrics are proxies)
- Blind spots:
  - No semantic lint rule pass (unsafe assignment/member access, etc.)
  - No production-vs-test filtering in baseline counts
  - No runtime trace validation

### 7. Improvement Plan

- Goal: Reduce core type-safety violations by at least 25% without behavior changes
- Core scope: `any` + `as` + `!` + `@ts-ignore/@ts-expect-error`
- Baseline: `1283`
- Target reduction: `321`
- Target total: `<= 962`

#### Phase 1: API hotspot hardening (target: -120)

- Primary files:
  - `api/src/routes/weeks.ts`
  - `api/src/routes/issues.ts`
- Work:
  - Replace `req.query` casts with typed parse helpers + runtime validation
  - Replace `req.workspaceId!` / `req.userId!` with explicit guards and typed narrowing
  - Replace `row: any` with row interfaces that match selected SQL columns
- Done when:
  - At least 120 core violations removed in target files
  - Existing API behavior preserved by tests

#### Phase 2: Web core flow typing (target: -110)

- Primary files:
  - `web/src/components/IssuesList.tsx`
  - `web/src/pages/App.tsx`
  - `web/src/pages/ReviewsPage.tsx`
- Work:
  - Replace event/value assertions with precise React and domain types
  - Replace non-null assertions with guard-based control flow
  - Add local interfaces where handler shapes leak
- Done when:
  - At least 110 core violations removed in target files
  - Existing UI tests pass and key list/review flows are unchanged

#### Phase 3: Test and mock typing cleanup (target: -70)

- Primary files:
  - `api/src/services/accountability.test.ts`
  - `api/src/__tests__/transformIssueLinks.test.ts`
- Work:
  - Replace `as any` mocks with typed builders and narrowed partials
  - Keep test logic and assertions unchanged
- Done when:
  - At least 70 core violations removed in target tests
  - Test behavior stays the same

#### Phase 4: Regression guardrails (target: -21+ and lock-in)

- Work:
  - Add CI check to block increases in core violation counts
  - Add policy checks for new `any`, non-null assertions, and suppressions (exceptions must be explicit)
- Done when:
  - Total reduction reaches at least `-321`
  - New PRs cannot increase counts without documented exceptions

#### Quality gates for every phase

- `pnpm type-check` passes
- `pnpm test` passes
- No superficial type fixes:
  - No `any -> unknown` swaps without proper narrowing
  - No new assertions without runtime safety checks
  - Types must match real API/DB/UI shapes

---

## 2. Bundle Size Audit

*Source: `audits/bundle-size-audit-2026-03-09.md`*

### 1. Scope

- Category: Frontend production bundle size.
- Repo: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`.
- In scope: `web/dist/index.html` and `web/dist/assets/*`.
- Out of scope: Analyzer artifacts (for example `bundle-report.html`).
- Clarification: "2.21 KB" was interpreted as `2.21 MB`.

### 2. Measurement Method

| Metric                       | Tool + command                                                             | How measured                                         | Limits                                           |
| ---------------------------- | -------------------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------ |
| Total shipped payload        | Node script over `web/dist/index.html` + `web/dist/assets/*`               | Exact byte sum of shipped files                      | Excludes non-shipped analyzer files              |
| Chunk sizes + count          | `pnpm --filter @ship/web run build:analyze`                                | Parsed Vite `dist/*` output (minified + gzip)        | Hash/chunk names vary by build                   |
| Dependency size attribution  | Parsed `const data = ...` from `web/dist/bundle-report.html`               | Aggregated `nodeParts.renderedLength` by npm package | Can slightly overcount some wrapped CJS paths    |
| Unused dependency candidates | Static import scan of `web/src/**/*.{ts,tsx,js,jsx}` vs `web/package.json` | Flags deps with no direct import match               | False positives possible for indirect/glob usage |

### 3. Audit Deliverable

| Metric                          | Value                                                         | Notes                                      |
| ------------------------------- | ------------------------------------------------------------- | ------------------------------------------ |
| Total production payload        | 2,321,505 bytes (2,267.09 KB, 2.21 MB)                        | Deployment baseline: shipped HTML + assets |
| Largest emitted chunk           | `dist/assets/index-C2vAyoQ1.js` = 2073.70 KB (gzip 587.59 KB) | From Vite output                           |
| Emitted files                   | 263                                                           | Count of Vite `dist/*` entries             |
| Dominant visualizer chunk share | 94.90% (`assets/index-C2vAyoQ1.js`)                           | Concentration signal, not deployment bytes |
| Visualizer center metrics       | Rendered 4.34 MB, gzip 1.06 MB, brotli 927.27 KB              | Used for diagnosis only                    |

### 4. Dependency Concentration

| Rank | Dependency           | Visualizer rendered size |
| ---- | -------------------- | ------------------------ |
| 1    | `emoji-picker-react` | 399.60 KB                |
| 2    | `highlight.js`       | 377.94 KB                |
| 3    | `yjs`                | 264.93 KB                |

Unused dependency candidates from static scan:

- `@tanstack/query-sync-storage-persister`
- `@uswds/uswds` (likely false positive due to glob-based usage)

### 5. Findings (Ranked)

1. **P1 - Oversized entry chunk.**
   Evidence: `index-C2vAyoQ1.js` is 2073.70 KB and holds 94.90% of visualizer share.  
   Impact: Slower first load and worse TTI on constrained devices/networks.

2. **P1 - A few packages account for a large share.**
   Evidence: `emoji-picker-react`, `highlight.js`, and `yjs` are top contributors.  
   Impact: High-leverage targets for lazy loading or footprint reduction.

3. **P2 - Code splitting is partially negated.**
   Evidence: Vite warns `upload.ts` and `FileAttachment.tsx` are both statically and dynamically imported.  
   Impact: Larger initial chunk than expected.

4. **P3 - Dependency hygiene opportunity.**
   Evidence: Static scan flagged at least one likely unused package.  
   Impact: Ongoing maintenance and bundle creep risk if left unchecked.

### 6. What Is Already Working

- The build emits many route/feature chunks (263 files), so the app is not fully monolithic.
- Improvement work can focus on the oversized entry chunk rather than rebuilding the bundling approach.

### 7. Risks and Unknowns

- No runtime RUM data yet (for example LCP/TTI by network/device class).
- Visualizer package aggregation can overcount some wrapper paths.
- Static unused-dependency scans can miss non-standard resolution patterns.

### 8. Boundary Reminder

- This audit is diagnostic only.
- No code or dependency fixes were applied in this pass.

### 9. Improvement Plan

- **Goal:** Reduce entry chunk size and improve first-load performance.
- **Targets:**
  1. Lazy-load `emoji-picker-react`, `highlight.js`, and `yjs` where feasible.
  2. Resolve Vite static/dynamic import conflicts for `upload.ts` and `FileAttachment.tsx`.
  3. Evaluate and remove `@tanstack/query-sync-storage-persister` if unused.
  4. Re-run `pnpm --filter @ship/web run build:analyze` and record before/after payload deltas.

---

## 3. API Response Time

*Source: `audits/api-response-time.md`*

Canonical record for Category 3 API response-time results.

### Scope

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

### Method

- Ran authenticated benchmarks against local API `http://127.0.0.1:3000` with local PostgreSQL.
- Enabled `E2E_TEST=1` during runs to avoid rate-limit (`429`) contamination.
- Used two tools:
  - ApacheBench (`ab`) for baseline
  - `k6` for validation
- Reported P50/P95/P99 in milliseconds for each concurrency level.

### Audit deliverable Key Result (c50)

At 50-concurrency load, `/api/documents?type=wiki` and `/api/issues` are the slowest list endpoints and remain the primary optimization targets.

Metric format for this table: `(ab/k6)` in milliseconds.

| Audit Deliverable | Endpoint                   | P50             | P95             | P99             |
| ----------------- | -------------------------- | --------------- | --------------- | --------------- |
| 1                 | `/api/documents?type=wiki` | (101/110.92) ms | (123/138.65) ms | (131/153.41) ms |
| 2                 | `/api/issues`              | (87/97.48) ms   | (105/120.60) ms | (116/134.52) ms |
| 3                 | `/api/projects`            | (42/46.65) ms   | (54/57.40) ms   | (58/62.79) ms   |
| 4                 | `/api/weeks`               | (39/45.19) ms   | (46/54.22) ms   | (53/60.29) ms   |
| 5                 | `/api/programs`            | (30/34.79) ms   | (36/46.14) ms   | (40/49.59) ms   |

### Full Baseline Results (AB)

| Endpoint                   | c10 P50/P95/P99 (ms) | c25 P50/P95/P99 (ms) | c50 P50/P95/P99 (ms) |
| -------------------------- | -------------------- | -------------------- | -------------------- |
| `/api/documents?type=wiki` | 22/35/47             | 51/65/73             | 101/123/131          |
| `/api/issues`              | 17/28/41             | 41/55/61             | 87/105/116           |
| `/api/projects`            | 9/14/20              | 21/69/82             | 42/54/58             |
| `/api/programs`            | 6/10/12              | 15/20/21             | 30/36/40             |
| `/api/weeks`               | 8/12/15              | 20/25/28             | 39/46/53             |

### Full Validation Results (k6)

| Endpoint                   | c10 P50/P95/P99 (ms) | c25 P50/P95/P99 (ms) | c50 P50/P95/P99 (ms) |
| -------------------------- | -------------------- | -------------------- | -------------------- |
| `/api/documents?type=wiki` | 23.94/39.01/47.83    | 59.59/99.51/150.83   | 110.92/138.65/153.41 |
| `/api/issues`              | 17.72/32.80/59.52    | 48.70/108.85/140.73 | 97.48/120.60/134.52 |
| `/api/projects`            | 9.16/15.49/37.93     | 23.09/30.85/35.79   | 46.65/57.40/62.79   |
| `/api/programs`            | 6.60/9.84/13.20      | 17.40/38.64/47.49   | 34.79/46.14/49.59   |
| `/api/weeks`               | 8.34/16.34/23.61     | 20.97/30.33/35.69   | 45.19/54.22/60.29   |

### Notes

- Discarded one earlier AB run due to heavy rate-limiting and non-2xx responses.
- This file replaces earlier split API response-time and k6 report files.

### Improvement Plan

- **Goal:** Reduce P95 by 20% on at least two endpoints under identical benchmark conditions.
- Primary targets (AB c50 baseline):
  - `/api/documents?type=wiki`: `123ms` -> `<=98ms`
  - `/api/issues`: `105ms` -> `<=84ms`

1. Reduce list-endpoint payload size.
2. Add targeted database indexes for current list query filters and sorts.
3. Re-run the same benchmark matrix (`c10/c25/c50`) with the same seeded volume.
4. Record before/after P95 deltas in this file.
5. If either target is missed, apply pagination/default limits and rerun.

---

## 4. Database Query Efficiency

*Source: `audits/database-query-efficiency-audit-2026-03-10.md`*

Date: 2026-03-10  
Scope: Ship unified document model query efficiency  
Method: Instrumented `pool.query` at the API layer and replayed five authenticated user flows.

### Summary

- Baseline query counts were captured for five core flows.
- Two concrete inefficiencies were found: an N+1 pattern in action-items and an extra round-trip in mention search.
- Proposed changes are **not applied yet**. If applied, they reduce Search content from 5 to 4 queries (20%).
- In the audited search query family, estimated execution time drops from 0.979 ms to 0.360 ms (~63.2% faster).

### Audit Deliverable

| User Flow         | Total Queries | Slowest Query (ms) | N+1 Detected? |
| ----------------- | ------------- | ------------------ | ------------- |
| Load main page    | 54            | 3.39 ms            | Yes           |
| View a document   | 16            | 2.29 ms            | No            |
| List issues       | 17            | 2.40 ms            | No            |
| Load sprint board | 14            | 2.24 ms            | No            |
| Search content    | 5             | 1.00 ms            | No            |

### Inefficiencies Identified

1. `GET /api/accountability/action-items` has N+1 behavior in `checkMissingStandups` and `checkSprintAccountability` (`api/src/services/accountability.ts`).
   - Each sprint triggered separate queries for standup existence, last standup date, and issue counts.
2. `GET /api/search/mentions` executes separate database queries for people and documents (`api/src/routes/search.ts`).
   - This adds one extra query to each search request.
3. Search by title uses `%ILIKE%` on `documents.title`.
   - `EXPLAIN ANALYZE` shows a sequential scan on content documents for this dataset.

### Projected Metrics (If Applied)

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

### EXPLAIN ANALYZE Snapshot

Query family: Search content (`/api/search/mentions?q=pro`)

#### Before (Two DB Queries)

- `old_people`: Execution Time **0.251 ms**
- `old_docs`: Execution Time **0.728 ms**
- Combined execution time: **0.979 ms**

Plan highlights:

- `old_people`: Bitmap Heap Scan on `documents` filtered by `document_type='person'`
- `old_docs`: Seq Scan on `documents` with `title ILIKE '%pro%'`

#### After (Single Combined DB Query)

- `new_combined`: Execution Time **0.360 ms**

Plan highlights:

- Single `Append` plan with `people` and `content_docs` subqueries
- Same filter semantics and per-subquery limits preserved

Execution-time delta (query family):

- **0.979 ms -> 0.360 ms (~63.2% faster)**

### Files Changed

- `audits/artifacts/db-query-efficiency-audit.ts` (audit runner)
- `audits/artifacts/db-query-efficiency-baseline.json`
- `audits/artifacts/db-query-efficiency-after.json`
- `audits/artifacts/db-query-efficiency-after2.json`
- `audits/database-query-efficiency-audit-2026-03-10.md`

### Improvement Plan

- **Goal:** Reduce query count and execution time for audited flows.
- **Proposed changes (not applied):**
  - In `api/src/services/accountability.ts`: Batch per-sprint standup checks and last-standup lookups into set-based queries; batch sprint issue counts instead of querying once per sprint.
  - In `api/src/routes/search.ts`: Merge people and document search into one SQL statement (CTEs + `UNION ALL`) while preserving per-source limits.
- **Target:** 20% reduction in Search content flow (5 → 4 queries); ~63% faster execution for that query family.
- **Exit criterion:** Re-run instrumented flows and confirm projected metrics.

---

## 5. Test Coverage and Quality

*Source: `audits/test-coverage-quality-audit-2026-03-10.md`*

### Audit Deliverable

| Metric                            | Your Baseline                                                                                                                                                                                                                              |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Total tests                       | 1,471 (API: 451 + Web: 151 + E2E: 869)                                                                                                                                                                                                     |
| Pass / Fail / Flaky               | 451 / 0 / 0 (pnpm test)                                                                                                                                                                                                                    |
| Suite runtime                     | 20.88 s (pnpm test)                                                                                                                                                                                                                        |
| Critical flows with zero coverage | 1) Concurrent same-document edit convergence with persisted reload verification 2) Offline edit queue replay exactly-once semantics after reconnect 3) RBAC revocation during active collaboration (write rejection + persistence check) |
| Code coverage % (if measured)     | web: 28.53% lines / 19.38% branches / api: 40.52% lines / 33.44% branches (Web measured with `coverage.reportOnFailure=true` while 13 tests fail)                                                                                          |

### 1. Scope and Intent

- Category: Category 5 - Test Coverage and Quality (Playwright E2E emphasis + test instrumentation readiness)
- Repository: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`
- Purpose: establish a trustworthy baseline, identify highest-risk blind spots, and prioritize coverage improvements.
- Assumptions:
  - `pnpm test` is the official baseline command (currently `@ship/api` Vitest tests).
  - E2E audit used Playwright specs/config analysis without executing all 869 E2E tests.
  - Total tests = API + Web + E2E across all suites.
  - This audit is diagnostic only; no remediation changes were made.

### 2. Measurement Method

| Metric                             | Tool / Command                                                             | How Measured                                                                | Limitation                                             |
| ---------------------------------- | -------------------------------------------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------ |
| Baseline determinism               | `for i in 1 2 3; do /usr/bin/time -p pnpm -s test -- --reporter=dot; done` | Compared pass/fail consistency and runtime spread across 3 consecutive runs | API test path only; excludes Playwright E2E            |
| E2E suite size                     | `pnpm exec playwright test --list`                                         | Counted listed tests and spec files                                         | Inventory only; not execution quality                  |
| Critical-flow traceability         | filename mapping + spot checks                                             | Mapped specs to CRUD, Sync, Auth, Sprint flows and looked for dark logic    | Filename intent can over/under represent behavior      |
| Flakiness risk indicators          | `rg -n "waitForTimeout\(" e2e/*.spec.ts`                                   | Flagged fixed-wait usage in high-risk flows                                 | Static indicator only                                  |
| Coverage instrumentation readiness | config inspection + `vitest --coverage` execution                          | Verified provider setup and collected API/Web line+branch baselines         | Web baseline currently includes 13 known failing tests |

### 3. Findings (Ranked)

1. **P1 - Web coverage baseline reliability is constrained by failing web tests**
   - Evidence: coverage now runs, but Web coverage execution still reports 13 test failures.
   - Impact: web line/branch percentages are measurable but reliability is reduced until failing tests are resolved.
   - Scope: `web` unit test suite and web coverage quality gates.

2. **P1 - Real-time sync/concurrency tests are underrepresented**
   - Evidence: only 4 sync-focused specs out of 71 (`autosave-race-conditions`, `content-caching`, `my-week-stale-data`, `race-conditions`).
   - Impact: stale-write, lost-update, and ordering regressions may escape detection.
   - Scope: editor + WebSocket/Yjs collaboration.

3. **P1 - Extensive fixed waits increase flake risk**
   - Evidence: widespread `waitForTimeout(...)` in key specs (`autosave-race-conditions`, `data-integrity`, `drag-handle`, `inline-comments`, etc.).
   - Impact: CI nondeterminism, false failures, and noisy reruns.
   - Scope: multiple E2E feature areas.

4. **P2 - `pnpm test` baseline is deterministic in current environment**
   - Evidence: 3/3 runs clean; stable runtime band.
   - Impact: good confidence for API regression checks.

5. **P2 - Web unit suite currently has deterministic failures**
   - Evidence: `pnpm --filter @ship/web test -- --coverage --run --reporter=dot` reported 13 failed tests.
   - Impact: weak web test signal and reduced confidence in web coverage quality.

### 4. Critical-Flow Traceability

| Flow              | Mapped E2E Coverage                                                                                               | Signal      |
| ----------------- | ----------------------------------------------------------------------------------------------------------------- | ----------- |
| CRUD              | 11 mapped files (`documents`, `document-workflows`, `issues`, `wiki-document-properties`, `bulk-selection`, etc.) | Strong      |
| Real-time Sync    | 4 mapped files (`autosave-race-conditions`, `content-caching`, `my-week-stale-data`, `race-conditions`)           | Medium-Weak |
| Auth / RBAC       | 8 mapped files (`auth`, `authorization`, `session-timeout`, `security`, `admin-workspace-members`, etc.)          | Strong      |
| Sprint Management | 12 mapped files (`weeks`, `weekly-accountability`, `accountability-`*, `manager-reviews`*, `project-weeks`, etc.) | Strong      |

### 5. Highest-Risk Dark Logic Gaps

1. **Concurrent same-document edit convergence**
   - Missing explicit two-user overlapping edit assertions with persisted reload verification.
   - Needed checks: both markers visible in both sessions, stable order after reload, merged content persisted server-side.

2. **Offline edit queue replay exactly-once semantics**
   - Missing explicit validation that reconnect replay does not duplicate operations.
   - Needed checks: each offline edit appears exactly once, save status converges, expected revision progression, reload parity.

3. **RBAC revocation during active collaboration**
   - Missing explicit mid-session permission revocation write-block test.
   - Needed checks: write attempts rejected (UI + 403), no unauthorized persisted changes, revoked session remains denied on reload.

### 6. Coverage Instrumentation and Reporting Status

- Attempted commands:
  - `pnpm --filter @ship/api test:coverage -- --reporter=dot`
  - `pnpm --filter @ship/web test:coverage -- --reporter=dot`
  - `pnpm --filter @ship/web exec vitest run --coverage --reporter=dot --coverage.reportOnFailure=true`
- Coverage runtime status:
  - Operational for both packages (`Coverage enabled with v8`).
- Current caveat:
  - Web run has 13 failing tests; used `coverage.reportOnFailure=true` to emit numeric coverage anyway.
- `api/vitest.config.ts` and `web/vitest.config.ts` now both use `coverage.provider: 'v8'`.
- Playwright is not currently configured to emit app code coverage artifacts.
- To produce E2E coverage metrics, the app needs instrumentation (for example Istanbul) plus a merge/report pipeline.

### 7. Execution and Flakiness Snapshot (`pnpm test`)

1. Run 1: pass (451/451), 20.57s
2. Run 2: pass (451/451), 22.08s
3. Run 3: pass (451/451), 19.99s

Flaky tests observed in this command path: **0**.

### 8. Residual Risk Summary

- Highest risk: collaboration correctness during concurrent edits, reconnects, and permission transitions.
- Confidence: medium-high for measured baselines; medium for dark-logic inference (mapping + config analysis).
- Blind spots:
  - No CI-history flake-rate sampling in this audit.
  - Web coverage percentages are currently sampled with failing tests present; treat as provisional until web suite is stabilized.

### 9. Audit Boundary Reminder

- This report is diagnosis only.
- No fixes were implemented during this audit.

### 10. Improvement Plan

- **Coverage unlock:** Keep runnable coverage active in `api` and `web`; improve line/branch baselines over time.
- **Reliability:** Resolve 13 deterministic Web unit test failures; replace `waitForTimeout` in high-risk E2E specs with event/assertion-based waits; track flaky rate.
- **Flow coverage:** Add 3 E2E scenarios—concurrent same-document overlap edit convergence, offline edit replay exactly-once, RBAC revocation during active collaboration.
- **Reporting:** Re-run audit after fixes and update coverage percentages and Pass/Fail/Flaky baselines.

---

## 6. Runtime Errors and Edge Cases

*Source: `audits/runtime-error-edge-case-audit-2026-03-10.md`*

### Audit Deliverable

| Metric                                | Your Baseline                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Console errors during normal usage    | **24** (`audits/artifacts/console-main.log`, 10-minute active editing window)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| Unhandled promise rejections (server) | **1** observed server-side runtime rejection signal (`ForbiddenError: invalid csrf token`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Network disconnect recovery           | **Partial** (pass in baseline reconnect flow; partial under chaos due to redirect churn and aborted calls)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Missing error boundaries              | `web/src/components/UnifiedEditor.tsx` (no clear user-facing boundary for autosave/collab hard failures); `web/src/pages/Login.tsx` (setup-status failures primarily surfaced in console)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| Silent failures identified            | 1) Autosave terminal failure is console-only (`web/src/hooks/useAutoSave.ts`) Repro: edit title/content, force repeated save failures, wait for retries to exhaust. 2) Reconnect-triggered session-expired redirect churn (`web/src/lib/api.ts`) Repro: edit doc, force 10s offline, reconnect. 3) Login rate limiting (`429`) can block valid credentials while UI shows generic "Login failed". Repro: repeat login attempts until rate-limited, then retry correct credentials. 4) Reviews button returns `403 Forbidden`. Repro: click Reviews. 5) On 3G + refresh, receiving collaborator stayed stale. Repro: throttle to 3G, refresh receiver, continue edits from sender. |

#### Screenshot Evidence (Provided 2026-03-10)

| Screenshot | Attached Evidence | Mapped Finding(s) |
| --- | --- | --- |
| Gap 1 Screenshot | `audits/assets/gap1.png` | Gap 1: concurrent title collision divergence |
| Gap 2 Screenshot | `audits/assets/gap2.png` | Gap 2: reconnect redirect/auth churn |
| Gap 3 Screenshot | `audits/assets/gap3.png` | Gap 3: autosave failure visibility gap |

### 1. Scope

- Focus: runtime resilience under network instability, adversarial input, and concurrent edits.
- Repository: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`
- Test setup: local `pnpm dev`, demo auth user, headless Playwright.
- Runs executed: one long chaos session (~16 minutes with ~10 active editing minutes) and one targeted fuzz/collision session.

### 2. How We Measured

| Area                     | Tooling                 | Command(s)                                                              | Notes                                                      |
| ------------------------ | ----------------------- | ----------------------------------------------------------------------- | ---------------------------------------------------------- |
| Console/runtime errors   | Playwright + `rg`       | `pnpm exec node audits/artifacts/category6-runtime-chaos-audit.mjs`     | Counted error lines in `audits/artifacts/console-main.log` |
| Failed network requests  | Playwright + `wc`/`rg`  | `wc -l < audits/artifacts/requestfailed.log`                            | Isolated disconnect and session-expiry patterns            |
| Concurrency collisions   | Playwright targeted run | `pnpm exec node audits/artifacts/category6-targeted-fuzz-collision.mjs` | Two clients edited the same title within ~50ms             |
| Input fuzzing/injection  | Playwright targeted run | `pnpm exec node audits/artifacts/category6-targeted-fuzz-collision.mjs` | Tested empty title, 52k-char title, XSS/SQL-like payloads  |
| Server integrity signals | API dev logs            | `pnpm dev` output correlation                                           | Tracked CSRF failures and reconnect churn during chaos     |

#### Execution Path

1. Started `pnpm dev` and confirmed API and web were reachable.
2. Ran `audits/category6-runtime-chaos-audit.mjs`.
3. Collected `audits/artifacts/console-main.log` and `audits/artifacts/requestfailed.log`.
4. Ran `audits/category6-targeted-fuzz-collision.mjs`.
5. Counted baseline values with `rg`/`wc` and mapped issues to:
   - `web/src/hooks/useAutoSave.ts`
   - `web/src/lib/api.ts`
   - `web/src/components/UnifiedEditor.tsx`
   - `web/src/pages/Login.tsx`

### 3. Five-Vector Findings

- Client resilience and observability: no browser unhandled rejections, but 24 console errors and multiple user-silent failures, including generic login messaging when the backend rate-limits even valid credential attempts.
- Network resilience: baseline disconnect/reconnect preserved collaborative data and UI state, but degraded conditions still showed failures (10-second chaos redirect/abort churn and a user-observed 3G-refresh stale receiver).
- Input fuzzing and security: script payload did not persist as raw `<script>`; long title acceptance suggests potential validation mismatch risk.
- Concurrency and race conditions: near-simultaneous title edits diverged between clients, and one startup case showed mismatched shared versions that converged only after leaving and reopening the document.
- Server integrity: CSRF rejection, reviews endpoint `403 Forbidden`, and frequent connect/disconnect cycles were visible; no clear burst of server 500s in artifacts.

### 4. Ranked Findings

| Rank | Severity | Finding                                              | Evidence                                                                                                                                    | User Impact                                                                                                                                   |
| ---- | -------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | P0       | Concurrent title edits diverge across clients        | `audits/artifacts/category6-targeted.json` (`final1 != final2`)                                                                             | Two users can each believe different final states are saved                                                                                   |
| 2    | P1       | Reconnect can trigger session-expired redirect churn | `audits/artifacts/requestfailed.log` shows 9 `login?expired=true&returnTo=` attempts + aborted calls                                        | Mid-edit disruption and possible loss of confidence in save state                                                                             |
| 3    | P1       | Autosave failures are mostly silent                  | `web/src/hooks/useAutoSave.ts` retries then logs terminal failure to console                                                                | User may assume content saved when it is not                                                                                                  |
| 4    | P1       | 3G refresh can leave receiving collaborator stale    | User-observed: after refresh on 3G, receiver did not update to new document edits                                                           | Receiver can work from outdated state and miss current edits after reconnect/refresh                                                          |
| 5    | P2       | Login rate-limit errors are not surfaced clearly     | User-observed repeated attempts can return `429 Too Many Requests` even when credentials are correct, while UI shows generic "Login failed" | Users cannot distinguish temporary lockout from credential problems, causing repeated retries and failed valid logins during cooldown windows |
| 6    | P2       | Initial collaboration version mismatch on open       | User-observed shared document versions differed on first open, then converged after navigating out of the doc and back in                   | Users can see stale/conflicting state at entry and may lose trust in real-time accuracy until manual re-entry                                 |
| 7    | P2       | Reviews button fails with `403 Forbidden`            | User-observed click on Reviews leads to `403 Forbidden` response                                                                            | Users cannot access review flow and may interpret this as a broken feature rather than a permission/state issue                               |

### 5. Top 3 Fixes (Detailed)

#### Gap 1: Concurrent title collision divergence

- Repro:
  1. Open the same doc in two authenticated browser contexts.
  2. Update title in both within ~50ms.
  3. Observe divergent post-sync title values.
- Root cause: title updates use async patch/autosave flow outside CRDT convergence guarantees.
- Before: clients can display conflicting final titles.
- After (target): stale writes return `409 WRITE_CONFLICT`, and client prompts refresh/merge.
- Implementation sketch: add versioned compare-and-swap on title patch (`expectedUpdatedAt` guard in SQL `WHERE` clause).
- Screenshot evidence: `audits/assets/gap1.png`

#### Gap 2: Reconnect redirect storm after transient outage

- Repro:
  1. Start editing with active sync.
  2. Force offline for 10 seconds.
  3. Reconnect and observe aborted requests plus repeated `expired=true` redirects.
- Root cause: immediate redirect behavior on first `401` during reconnect turbulence.
- Before: short outages can kick users into redirect churn.
- After (target): apply short reconnect grace window and retry gate before forced session-expired redirect.
- Implementation sketch: add circuit-breaker style `401` deferral window in `web/src/lib/api.ts`.
- Screenshot evidence: `audits/assets/gap2.png`

#### Gap 3: Autosave terminal failure has no persistent UI signal

- Repro:
  1. Edit title or content.
  2. Force repeated save failures (offline or forced 5xx).
  3. Wait for retries to exhaust and observe console-only failure.
- Root cause: autosave hook does not expose terminal error state to UI.
- Before: user receives no clear "not saved" status.
- After (target): sticky error banner/toast appears on terminal failure and clears only after successful save.
- Implementation sketch: add `onFailure` callback and exponential backoff handling in `useAutoSave`.
- Screenshot evidence: `audits/assets/gap3.png`

### 6. What Worked

- XSS hardening passed the tested payload: raw `<script>` did not persist.
- Collaborative editing survived disconnect/reconnect in baseline testing, and the UI recovered after reconnection.
- WebSocket collaboration recovered repeatedly during stable online periods.

### 7. Residual Risk and Limits

- Highest residual risk: non-CRDT title/property writes under contention.
- Confidence: medium-high for observed runtime failures; medium for DB persistence inference in collision scenario.
- Limits:
  - Targeted collision run did not include DB-readback verification for every write.
  - Local dev behavior may differ from production CDN/proxy behavior.
  - Top 3 gaps now have dedicated screenshots in `audits/assets/gap1.png`, `gap2.png`, and `gap3.png`.
  - Reviews `403` still has no dedicated screenshot artifact.

### 8. Boundary and Coverage

- This is a diagnosis-only audit; no production fixes were applied.
- Artifacts are in `audits/artifacts/`; harness scripts are in `audits/`.
- Requirement status:
  - Three critical gaps with repro/cause/before/after: addressed.
  - User-facing confusion/data-loss scenario: addressed.
  - Explicit measurement path: addressed.
  - Per-gap screenshot/recording evidence for top 3 gaps: complete

### 9. Improvement Plan (Top 3 Fixes)

1. **Gap 1 – Concurrent title collision divergence:** Add versioned compare-and-swap on title patch (`expectedUpdatedAt` guard in SQL `WHERE` clause); stale writes return `409 WRITE_CONFLICT`; client prompts refresh/merge.
2. **Gap 2 – Reconnect redirect storm:** Add circuit-breaker style `401` deferral window in `web/src/lib/api.ts`; apply short reconnect grace window and retry gate before forced session-expired redirect.
3. **Gap 3 – Autosave failure visibility:** Add `onFailure` callback and exponential backoff handling in `useAutoSave`; show sticky error banner/toast on terminal failure; clear only after successful save.

---

## 7. Accessibility Compliance

*Source: `audits/accessibility-compliance-audit-2026-03-10.md`*

### 1. Executive Summary

- Audited routes: `/login`, `/dashboard`, `/my-week`, `/docs`, `/issues`, `/projects`, `/programs`, `/team/allocation`, `/settings`.
- Baseline: Lighthouse 95-100, Critical 0, Serious 34 (all contrast).
- Selected target: fix all Critical/Serious issues on 3 priority pages (`/dashboard`, `/my-week`, `/issues`).
- Outcome: achieved. Those 3 pages now show Lighthouse 100 and 0 Critical/Serious.
- Remaining gap: 3 Serious contrast issues remain (`/projects`, `/programs`, `/team/allocation`, 1 each).
- VoiceOver spot check: most buttons were announced, but the `/issues` table did not announce row/cell context (silent).
- Keyboard traversal works across the app except table content traversal.
- Full screen-reader validation is still pending.

### 2. Scope and Measurement

- Repository: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`
- Environment: local dev via `pnpm dev`, authenticated seeded user (`dev@ship.local`)
- Automated command used:

`SHIP_BASE_URL=http://localhost:5173 node audits/accessibility/run-a11y-audit.mjs`

- Tooling coverage:
  - Lighthouse for per-page accessibility score
  - axe for Critical/Serious/Moderate/Minor, contrast, and ARIA/label checks
  - Playwright traversal for Tab reachability
- Boundaries:
  - Local dev run (not production runtime/CDN)
  - Partial manual VoiceOver spot check completed; full VoiceOver/NVDA pass not completed
  - No full Enter/Escape/Arrow interaction matrix across all controls

#### Evidence Bundles

- Baseline: `audits/accessibility/results/2026-03-10T07-18-30-333Z`
- Intermediate: `audits/accessibility/results/2026-03-10T07-38-55-200Z`
- Final: `audits/accessibility/results/2026-03-10T07-42-20-540Z`

### 3. Audit Deliverable

| Metric | Your Baseline |
|---|---|
| Lighthouse accessibility score (per page) | Login 100, Dashboard 95, My Week 95, Docs 100, Issues 96, Projects 96, Programs 95, Team Allocation 96, Settings 100 |
| Total Critical/Serious violations | Critical 0, Serious 34 |
| Keyboard navigation completeness | Partial (global navigation works; table content traversal remains incomplete) |
| Color contrast failures | 34 |
| Missing ARIA labels or roles | axe: none detected. Manual VoiceOver finding: `/issues` table row/cell context not announced (silent). |

### 4. Key Findings

- **P1:** Baseline had broad contrast failures (all 34 Serious findings were contrast), blocking full conformance claims.
- **P1:** Targeted remediations removed all Critical/Serious issues on `/dashboard`, `/my-week`, and `/issues`.
- **P2:** App-wide compliance is not complete; 3 Serious contrast issues remain.
- **P2:** Manual VoiceOver found a usability gap: `/issues` table rows/cells were silent (context not announced).
- **P2:** Keyboard gap is now narrowed to table content traversal.
- **P2:** Assistive-tech assurance is incomplete until full screen-reader validation and table keyboard traversal are resolved.

### 5. Improvement Path and Results

- Requirement options were:
  1. Improve lowest Lighthouse score by +10, or
  2. Fix all Critical/Serious on 3 important pages.
- Selected option: **Fix all Critical/Serious on 3 important pages**.
- Reason: lowest baseline score was 95; +10 is not feasible because Lighthouse maximum is 100.
- Status: **Achieved**.

| Page | Lighthouse (Before -> After) | Critical+Serious (Before -> After) |
|---|---:|---:|
| Dashboard | 95 -> 100 | 10 -> 0 |
| My Week | 95 -> 100 | 20 -> 0 |
| Issues | 96 -> 100 | 1 -> 0 |

#### Remediation Files

- `web/src/components/dashboard/DashboardVariantC.tsx`
- `web/src/pages/MyWeekPage.tsx`
- `web/src/components/IssuesList.tsx`
- `web/src/components/DashboardSidebar.tsx`

### 6. Residual Risk and Completion Plan

- Highest remaining risk: low-contrast variants on `/projects`, `/programs`, and `/team/allocation`.
- Confidence: high for automated results, medium for end-to-end assistive-tech usability.
- Blind spots: production environment not audited; full manual screen-reader pass pending.

#### Completion Plan

1. Resolve remaining 3 Serious contrast issues.
   - Exit criterion: app-wide Serious = 0 and Critical = 0.
2. Validate and fix keyboard traversal for table content (row/cell navigation and focus visibility).
   - Exit criterion: keyboard completeness moves from Partial to Full.
3. Complete manual screen-reader pass (VoiceOver or NVDA) on major pages and fix the `/issues` table announcement gap.
   - Exit criterion: no blocking screen-reader usability issues, including table row/cell context announcements.
4. Add CI regression gates for Lighthouse + axe on core routes.
   - Exit criterion: no net-new Critical/Serious regressions.

### 7. Requirement Coverage Check

- Measurement path and method: **Addressed** (`## 2`).
- Major audited pages: **Addressed** (`## 1`).
- Baseline audit deliverable table: **Addressed** (`## 3`).
- Improvement plan and target-achievement path: **Addressed** (`## 5`, `## 6`).
- Before/after evidence for selected target: **Addressed** (`## 5` + evidence bundles).

### 8. Improvement Plan

- **Achieved:** Critical/Serious issues fixed on `/dashboard`, `/my-week`, `/issues` (Lighthouse 100, 0 violations).
- **Remaining:**
  1. Resolve 3 Serious contrast issues on `/projects`, `/programs`, `/team/allocation` (exit: app-wide Serious = 0).
  2. Fix keyboard traversal for table content (exit: keyboard completeness = Full).
  3. Complete manual screen-reader pass; fix `/issues` table row/cell announcement gap.
  4. Add CI regression gates for Lighthouse + axe on core routes.
