# Consolidated Audit Deliverables — Before vs After

**Date:** 2026-03-13

This document consolidates all seven audit categories measured during the Ship performance, quality, and compliance sprint. Each category includes the baseline measurement captured before any remediation work and the final state after all changes were applied. A roll-up summary table at the end shows the single most important metric per category with before/after values and percent change.

---

## Table of Contents

1. [Type Safety](#1-type-safety)
2. [Bundle Size](#2-bundle-size)
3. [API Response Time](#3-api-response-time)
4. [Database Query Efficiency](#4-database-query-efficiency)
5. [Test Coverage and Quality](#5-test-coverage-and-quality)
6. [Runtime Errors and Edge Cases](#6-runtime-errors-and-edge-cases)
7. [Accessibility Compliance](#7-accessibility-compliance)
8. [Summary](#summary)

---

## 1. Type Safety

**Before Date:** 2026-03-09
**Source:** `audits/type-safety-audit-2026-03-09.md`

Type-safety violations were counted via an AST-based Node.js script scanning all `.ts` and `.tsx` source files in `api/`, `web/`, and `shared/` (320 files total, excluding `.d.ts`). Six categories were measured: `any` types, `as` assertions, non-null assertions (`!`), `@ts-ignore`/`@ts-expect-error` directives, untyped function parameters, and missing explicit return types.

### Before — Core Violations by Package

| Package    | `any` | `as`  | `!`   | `@ts-ignore` / `@ts-expect-error` | Untyped Params | Missing Return Types | Total |
|------------|------:|------:|------:|----------------------------------:|---------------:|---------------------:|------:|
| `api/`     | 229   | 317   | 296   | 0                                 | 283            | 1,246                | 2,371 |
| `web/`     | 33    | 372   | 33    | 1                                 | 1,168          | 3,208                | 4,815 |
| `shared/`  | 0     | 2     | 0     | 0                                 | 0              | 0                    | 2     |
| **Total**  | **262** | **691** | **329** | **1**                         | **1,451**      | **4,454**            | **7,188** |

**Core metric total** (`any` + `as` + `!` + `@ts-*`): **1,283**

### Before — Top 5 Violation-Dense Files

| File | Total | `any` | `as` | `!` | `@ts-*` | Untyped Params | Missing Return Types |
|------|------:|------:|-----:|----:|--------:|---------------:|---------------------:|
| `web/src/components/IssuesList.tsx` | 189 | 0 | 4 | 0 | 0 | 47 | 138 |
| `web/src/pages/App.tsx` | 180 | 0 | 1 | 0 | 0 | 30 | 149 |
| `api/src/routes/weeks.ts` | 159 | 11 | 26 | 48 | 0 | 24 | 50 |
| `web/src/hooks/useSessionTimeout.test.ts` | 159 | 0 | 2 | 0 | 0 | 0 | 157 |
| `web/src/pages/ReviewsPage.tsx` | 150 | 0 | 6 | 4 | 0 | 57 | 83 |

### After — Improvement Plan Targets

No remediation has been applied yet. The improvement plan targets a 25% reduction in core violations.

| Metric | Before | Target | Reduction |
|--------|-------:|-------:|----------:|
| Core violations (`any` + `as` + `!` + `@ts-*`) | 1,283 | ≤ 962 | −321 (−25%) |

### After — Planned Reduction by Phase

| Phase | Scope | Target Reduction |
|-------|-------|----------------:|
| Phase 1 — API hotspot hardening | `api/src/routes/weeks.ts`, `api/src/routes/issues.ts` | −120 |
| Phase 2 — Web core flow typing | `IssuesList.tsx`, `App.tsx`, `ReviewsPage.tsx` | −110 |
| Phase 3 — Test and mock typing cleanup | `accountability.test.ts`, `transformIssueLinks.test.ts` | −70 |
| Phase 4 — CI regression guardrails | Block increases in core violation count | −21+ and lock-in |

**Note:** After-state measurements are not yet available. This section will be updated after Phase 1–4 implementation.

---

## 2. Bundle Size

**Before Date:** 2026-03-09
**After Date:** 2026-03-13
**Sources:** `audits/bundle-size-audit-2026-03-09.md`, `audits/bundle-size-audit-after-006.md`

Bundle size was measured by summing exact byte sizes of all files in `web/dist/index.html` and `web/dist/assets/*` after a production `pnpm build`. Entry chunk gzip size was measured by the `web/scripts/check-bundle-budget.mjs` script using Node's `zlib.gzipSync`. The optimization work is on branch `006-bundle-size-reduction`.

### Before

| Metric | Value |
|--------|-------|
| Total production payload | 2,321,505 bytes (2,267.09 KB, **2.21 MB**) |
| Largest entry chunk (raw) | `index-C2vAyoQ1.js` — 2,073.70 KB minified |
| Entry chunk gzip | **587.59 KB** |
| Emitted JS files | 263 |
| Dominant chunk share | 94.90% (`index-C2vAyoQ1.js`) |

### Before — Top Dependencies (Visualizer Rendered Size)

| Rank | Dependency | Rendered Size | Location |
|------|------------|--------------|----------|
| 1 | `emoji-picker-react` | 399.60 KB | Bundled into entry chunk |
| 2 | `highlight.js` | 377.94 KB | Bundled into entry chunk |
| 3 | `yjs` | 264.93 KB | Bundled into entry chunk |

### After

| Metric | Value |
|--------|-------|
| Total production payload | 3,441,011 bytes (3,360.36 KB, **3.28 MB**) |
| Largest entry chunk (raw) | `index-*.js` — 977.87 KB minified |
| Entry chunk gzip (Vite) | **266.21 KB** (−54.7%) |
| Entry chunk gzip (budget script) | **259.97 KB** (−55.8%) |
| Emitted JS files | 308 (+45 new lazy chunks) |
| Dominant chunk share | ~80% (`index-*.js`) |

### After — Top Dependencies (Post-Optimization Location)

| Rank | Dependency | Gzip Size | Location After |
|------|------------|----------:|----------------|
| 1 | `emoji-picker-react` | 109.27 KB | Lazy chunk `index-Bj3ev3tE.js` — not in entry |
| 2 | `highlight.js` | 139.83 KB | Lazy chunk `Editor-*.js` — not in entry |
| 3 | `yjs` | part of `Editor-*.js` | Lazy chunk `Editor-*.js` — not in entry |

### After — Changes Applied

| Change | Impact |
|--------|--------|
| Lazy-load `emoji-picker-react` in `EmojiPicker.tsx` | Moved 109.27 KB gzip out of entry chunk |
| Lazy-load `Editor.tsx` at call sites | Moved yjs, lowlight, y-websocket, TipTap extensions (139.83 KB gzip) into `Editor-*.js` lazy chunk |
| Added `EditorSkeleton.tsx` loading state | UX continuity during lazy load |
| Added `LazyErrorBoundary.tsx` error boundary | Handles lazy chunk 404s with "Reload" button |
| Removed `@tanstack/query-sync-storage-persister` | Unused dependency eliminated |
| Added `web/scripts/check-bundle-budget.mjs` | CI budget enforcement at 275 KB gzip |

### Target vs Actual

| Target | Threshold | Actual | Status |
|--------|-----------|--------|--------|
| ≥20% initial page load reduction (entry chunk gzip) | ≤470.07 KB | 259.97 KB | PASS (−55.8%) |

---

## 3. API Response Time

**Before Date:** 2026-03-10
**After Date:** 2026-03-12
**Source:** `audits/api-response-time.md`

Response times were measured using ApacheBench (`ab`) and `k6` against a local API (`http://127.0.0.1:3000`) with local PostgreSQL at a seeded data volume of 572 documents, 104 issues, 26 users, and 35 sprints. Benchmarks were run at three concurrency levels (c10, c25, c50). Results below use c50 as the primary comparison tier. P50/P95/P99 values are from the `ab` tool unless noted.

### Before — c50 Benchmark (AB)

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

### After — Changes Applied

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

### After — EXPLAIN ANALYZE Evidence

| Query | Before | After |
|-------|--------|-------|
| Wiki execution time | 1.4 ms | 0.6 ms |
| Wiki buffer hits | 24 | 7 |
| Issues execution time | 2.78 ms | 1.25 ms |
| Issues buffer hits | 2,527 | 32 |

---

## 4. Database Query Efficiency

**Before Date:** 2026-03-10
**After Date:** 2026-03-13
**Sources:** `audits/database-query-efficiency-audit-2026-03-10.md`, `audits/artifacts/db-query-efficiency-baseline.json`, `audits/artifacts/db-query-efficiency-after.json`

Query counts were measured by instrumenting `pool.query` at the API layer and replaying five authenticated user flows. Each flow was executed against a locally running API and PostgreSQL instance with seeded data.

### Before — Query Counts per User Flow

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

### After — Query Counts per User Flow

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

## 5. Test Coverage and Quality

**Before Date:** 2026-03-10 / 2026-03-12 (pre-implementation)
**After Date:** 2026-03-12 (post-implementation)
**Sources:** `audits/test-coverage-quality-audit-2026-03-10.md`, `audits/coverage-snapshot-before-2026-03-12.md`, `audits/coverage-snapshot-after-2026-03-12.md`, `audits/e2e-closure-delta-2026-03-12.md`

Coverage was measured using Vitest with `coverage.provider: 'v8'` via `pnpm --filter @ship/api test:coverage` and `pnpm --filter @ship/web test:coverage`. E2E fixed-wait counts were measured with `rg -n "waitForTimeout\(" e2e/*.spec.ts`.

### Before — Unit / Integration Coverage

| Surface | Statements | Branches | Functions | Lines |
|---------|----------:|--------:|----------:|------:|
| API | 41.30% | 34.33% | 41.43% | 41.49% |
| Web | 33.91% | 24.09% | 31.22% | 34.90% |

### Before — Original Audit Baseline (2026-03-10)

| Metric | Value |
|--------|-------|
| Total tests | 1,471 (API: 451, Web: 151, E2E: 869) |
| Pass / Fail / Flaky (pnpm test) | 451 / 0 / 0 |
| API line coverage | 40.52% |
| API branch coverage | 33.44% |
| Web line coverage | 28.53% (with 13 failing tests) |
| Web branch coverage | 19.38% (with 13 failing tests) |
| `waitForTimeout(...)` calls in E2E | 619 (at HEAD) |
| Critical-flow dark logic gaps | 3 (collaboration convergence, offline replay, RBAC revocation) |

### Before — Key Coverage Hotspots

| File | Statements | Branches | Lines |
|------|----------:|--------:|------:|
| `api/src/routes/dashboard.ts` | 36.71% | 26.27% | 37.31% |
| `api/src/utils/document-crud.ts` | 30.58% | 34.61% | 31.16% |
| `web/src/pages/Dashboard.tsx` | 33.82% | 28.39% | 37.09% |
| `web/src/components/dashboard/DashboardVariantC.tsx` | 0.00% | 0.00% | 0.00% |

### After — Unit / Integration Coverage

| Surface | Statements | Branches | Functions | Lines | Stmt Delta | Branch Delta |
|---------|----------:|--------:|----------:|------:|----------:|-------------:|
| API | 45.35% | 38.02% | 46.25% | 45.59% | +4.05 pts | +3.69 pts |
| Web | 49.38% | 41.88% | 44.57% | 50.46% | +15.47 pts | +17.79 pts |

### After — Key File Highlights

| File | Statements | Branches | Lines |
|------|----------:|--------:|------:|
| `api/src/utils/document-crud.ts` | 77.64% | 61.53% | 76.62% |
| `api/src/routes/documents.ts` | 66.30% | 62.02% | 65.72% |
| `api/src/routes/workspaces.ts` | 75.33% | 80.23% | 75.33% |
| `web/src/pages/Dashboard.tsx` | 95.58% | 76.54% | 98.38% |
| `web/src/components/dashboard/DashboardVariantC.tsx` | 100.00% | 88.33% | 100.00% |
| `web/src/services/upload.ts` | 89.70% | 67.56% | 91.04% |
| `web/src/lib/date-utils.ts` | 100.00% | 100.00% | 100.00% |

### After — E2E Reliability

| Metric | Before | After | Delta |
|--------|-------:|------:|------:|
| `waitForTimeout(...)` calls (e2e/*.spec.ts) | 619 | 537 | −82 (−13.2%) |
| High-risk targeted files with fixed waits | 8 | 0 | −8 |
| Dark-logic specs with grouped runtime evidence | 0 | 3 | +3 |

### After — E2E Layer 3 Group Closure (2026-03-12)

| Group | Tests | Failed | Flaky |
|-------|------:|-------:|------:|
| Group 4 — sprint/accountability core | 40 | 0 | 0 |
| Group 5 — sprint planning/review | Passed | 0 | 0 |
| Group 6 — issues/program core | 49 | 0 | 0 |
| Group 7 — issue/program APIs | 71 | 0 | 0 |

---

## 6. Runtime Errors and Edge Cases

**Before Date:** 2026-03-10
**After Date:** 2026-03-13 (partial — see notes)
**Sources:** `audits/consolidated-audit-report-2026-03-10.md` (Section 6), `audits/artifacts/console-main.log`, `audits/artifacts/category6-targeted.json`

Runtime errors were captured by running the app under Playwright automation across authenticated page flows and recording browser console output. The `console-main.log` artifact contains the raw console capture from 2026-03-10. The `category6-targeted.json` artifact records a targeted fuzz/collision test result.

### Before — Runtime Error Baseline

| Metric | Baseline Value | Notes |
|--------|---------------|-------|
| Console `error` entries | 24 | Captured across page loads in `console-main.log` |
| Unhandled promise rejections | 1 | `Failed to check setup status: TypeError: Failed to fetch` (pre-auth load) |
| Silent failures (no UI feedback) | 5 | Swallowed fetch errors on unauthenticated routes |
| Known recurring error pattern | `Failed to load resource: 401 Unauthorized` | Fires on every page load before authentication resolves |
| CAIA auth error | 1 | `CAIA auth not available: TypeError: Failed to fetch` — benign/expected in local dev |
| Yjs collision divergence | Detected | `category6-targeted.json`: collision test showed `"inference": "Divergence"` between concurrent edits |
| XSS raw script injection | Not detected | `xssRawScriptTagInEditor: false` in fuzz results |

### Before — Recurring Error Classes

| Error Class | Count | Source |
|-------------|------:|--------|
| `401 Unauthorized` on initial resource load | Multiple per session | Pre-auth page load race |
| `Failed to check setup status` (unhandled rejection) | 1 | `Login.tsx` `checkSetup` on cold start |
| `CAIA not configured` / auth unavailable | 1 per session | Expected in local dev, benign |
| Silent fetch failures (no user-visible error state) | 5 | Various unauthenticated API calls |

### After — Tracked Fixes

| Fix | Description | Status |
|-----|-------------|--------|
| `/issues` empty state error handling | Added `role=status aria-live=polite` to error state and normal empty state in `IssuesList.tsx` | Applied — re-test needed |
| `/issues` keyboard row handler | Row-level `onKeyDown Enter` handler added to each `<tr>` directly (no longer relies on table-level event bubbling) | Applied — re-test needed |
| Yjs collision divergence | Detected in `category6-targeted.json`; targeted fuzz-collision test added for regression tracking | Tracked |

### After — Improvement Plan Targets

| Metric | Before | Target | Notes |
|--------|-------:|-------:|-------|
| Console `error` entries | 24 | ≤ 5 | Remove pre-auth 401 noise via session guard; handle remaining fetch errors |
| Unhandled promise rejections | 1 | 0 | Wrap `checkSetup` in `Login.tsx` with rejection handler |
| Silent failures (no UI feedback) | 5 | 0 | Surface errors with `role=status` / toast patterns |

**Note:** After-state raw console error counts have not been re-measured under identical conditions. The table above reflects the improvement plan targets, not confirmed measurements.

---

## 7. Accessibility Compliance

**Before Date:** 2026-03-10
**After Date:** 2026-03-13
**Sources:** `audits/accessibility-compliance-audit-2026-03-10.md`, `docs/a11y-manual-validation.md`

Accessibility was measured using Lighthouse (per-page accessibility score), axe (Critical/Serious/Moderate/Minor violations, contrast, ARIA/label checks), and Playwright Tab traversal. The automated audit was run as `SHIP_BASE_URL=http://localhost:5173 node audits/accessibility/run-a11y-audit.mjs` against a locally seeded dev instance.

### Before — Baseline Audit (2026-03-10)

| Page | Lighthouse Score | Critical Violations | Serious Violations |
|------|----------------:|-------------------:|-------------------:|
| `/login` | 100 | 0 | 0 |
| `/dashboard` | 95 | 0 | 10 |
| `/my-week` | 95 | 0 | 20 |
| `/docs` | 100 | 0 | 0 |
| `/issues` | 96 | 0 | 1 |
| `/projects` | 96 | 0 | 1 |
| `/programs` | 95 | 0 | 1 |
| `/team/allocation` | 96 | 0 | 1 |
| `/settings` | 100 | 0 | 0 |
| **Total** | — | **0** | **34** |

### Before — Additional Baseline Metrics

| Metric | Value |
|--------|-------|
| Color contrast failures | 34 (all Serious violations were contrast failures) |
| Missing ARIA labels / roles | None detected by axe |
| Keyboard navigation | Partial — global nav works; table content traversal incomplete |
| Manual VoiceOver | `/issues` table rows/cells silent (context not announced) |

### After — Priority Pages (Targeted Remediation)

| Page | Lighthouse Before | Lighthouse After | Critical+Serious Before | Critical+Serious After |
|------|------------------:|-----------------:|------------------------:|-----------------------:|
| `/dashboard` | 95 | **100** | 10 | **0** |
| `/my-week` | 95 | **100** | 20 | **0** |
| `/issues` | 96 | **100** | 1 | **0** |

### After — Full App Violation Summary

| Metric | Before | After | Delta |
|--------|-------:|------:|------:|
| Total Serious violations | 34 | **0** | −34 (−100%) |
| Total Critical violations | 0 | 0 | 0 |
| Pages with Serious violations | 6 | 0 | −6 |

### After — Contrast Fixes Applied (Session 1 — 007-a11y-completion-gates)

| Element | Old Value | Old Ratio | New Value | New Ratio | WCAG Result |
|---------|-----------|----------:|-----------|----------:|:-----------:|
| Focus ring (`:focus-visible`) | `#005ea2` | 2.89:1 | `#1a85d9` | 5.00:1 | PASS |
| Editor placeholder text | `#525252` | 2.49:1 | `#808080` | 4.92:1 | PASS |
| Drag handle (default) | `#525252` | 2.49:1 | `#808080` | 4.92:1 | PASS |
| `.mention` / `.mention-document` text | `#5e6ad2` | 4.14:1 | `#6b7ae0` | 5.08:1 | PASS |
| Programs.tsx unassigned dash | `text-muted/50` | 2.50:1 | `text-muted` | 5.63:1 | PASS |
| TeamMode.tsx archived avatars | `bg-gray-400` | 2.30:1 | `bg-gray-500` | 4.60:1 | PASS |

### After — Contrast Fixes Applied (Session 2 — app-wide sweep)

| Element | Old Value | Old Ratio | New Value | New Ratio | WCAG Result |
|---------|-----------|----------:|-----------|----------:|:-----------:|
| `text-accent` as text color (40+ components) | `#005ea2` | 2.89:1 | `#1a85d9` (via `text-accent-text`) | 5.00:1 | PASS |
| `text-muted/<opacity>` variants (all files) | `#8a8a8a` at 30–60% | 1.41–2.57:1 | `text-muted` (100%) | 5.63:1 | PASS |
| KanbanBoard archived assignee avatar | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |
| AccountabilityGrid empty-state badge | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |
| TeamDirectory archived avatar | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |

### Remaining Gaps

| Gap | Status |
|-----|--------|
| Full manual VoiceOver/NVDA pass on all pages | Pending — partial pass done on `/issues` |
| Keyboard traversal for table content (row/cell focus) | Partially addressed; re-test needed |
| CI regression gate (Lighthouse + axe on merge) | Configured in `007-a11y-completion-gates` CI job |

---

## Summary

Roll-up table showing the single most important metric per category, before/after values, and percent change.

| # | Category | Key Metric | Before | After | % Change |
|---|----------|-----------|-------:|------:|---------:|
| 1 | Type Safety | Core violations (`any` + `as` + `!` + `@ts-*`) | 1,283 | ≤ 962 (target) | −25% (target) |
| 2 | Bundle Size | Entry chunk gzip size | 587.59 KB | 259.97 KB | −55.8% |
| 3 | API Response Time | `/api/documents?type=wiki` P95 at c50 | 123 ms | 8 ms | −93.5% |
| 4 | Database Query Efficiency | Search content query execution time | 0.979 ms | 0.360 ms | −63.2% |
| 5 | Test Coverage and Quality | Web statement coverage | 33.91% | 49.38% | +45.6% |
| 6 | Runtime Errors and Edge Cases | Browser console `error` entries per session | 24 | ≤ 5 (target) | −79% (target) |
| 7 | Accessibility Compliance | Total Serious violations (axe) | 34 | 0 | −100% |
