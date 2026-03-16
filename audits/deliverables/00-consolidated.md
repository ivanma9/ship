# Consolidated Audit Deliverables — Before vs After

**Date:** 2026-03-15

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
9. [Auth Stability Fixes (Bonus)](#auth-stability-fixes-track-c--2026-03-13-14)

---

## 1. Type Safety

**Audit Date:** 2026-03-09 · **Remediation Completed:** 2026-03-15

### Before

_Source: `audits/type-safety-audit-2026-03-09.md` — 320 files scanned_

| Package   | `any` | `as` | `!` | `@ts-ignore` / `@ts-expect-error` | Untyped Params | Missing Return Types | Total |
|-----------|------:|-----:|----:|----------------------------------:|---------------:|---------------------:|------:|
| `api/`    | 229   | 317  | 296 | 0                                 | 283            | 1,246                | 2,371 |
| `web/`    | 33    | 372  | 33  | 1                                 | 1,168          | 3,208                | 4,815 |
| `shared/` | 0     | 2    | 0   | 0                                 | 0              | 0                    | 2     |
| **Total** | **262** | **691** | **329** | **1**                        | **1,451**      | **4,454**            | **7,188** |

**Core metric** (`any` + `as` + `!` + `@ts-*`): **1,283**

### Fixes Applied

| Change | Files Touched |
|--------|--------------|
| Typed route handler params as `AuthenticatedRequest`; added `IssueProperties` interface eliminating property bag casts | `api/src/routes/issues.ts` |
| Added `SprintRow`/`StandupRow`/`TipTapDoc` interfaces; narrowed query params with `typeof` guards instead of `as string` casts | `api/src/routes/weeks.ts` |
| Replaced `Map.get()!` with `?.` optional chaining; narrowed `EventTarget` with `instanceof HTMLElement` guard | `web/src/pages/ReviewsPage.tsx`, `web/src/pages/App.tsx`, `web/src/components/IssuesList.tsx` |
| Exported `TipTapDoc`/`TipTapNode` from transform module; changed return type to `Promise<TipTapDoc>`; removed 56 non-null assertions on array indices | `api/src/__tests__/transformIssueLinks.test.ts`, `api/src/services/transformIssueLinks.ts` |
| Added CI ceiling ratchet; ceiling set to 929 then lowered to 878 | `scripts/check-type-ceiling.mjs`, `.github/workflows/ci.yml` |
| Replaced `as any` casts in pg mock helpers with typed `mockQueryResult` wrappers; added generics to `pool.query<T>()` calls; narrowed route handler types; removed redundant non-null assertions | 25 files across API routes, tests, middleware |

### After

_Re-measured post-remediation — 336 files scanned_

| Metric | Before | After | Measurement Method | Status |
|--------|-------:|------:|--------------------|--------|
| Core violations (`any` + `as` + `!` + `@ts-*`) | 1,283 | 878 | `node scripts/type-violation-scan.cjs` | PASS — −31.6%, exceeds 25% target |
| `api/` core | 730 | 476 | same | PASS |
| `web/` core | 413 | 402 | same | PASS |
| `shared/` core | 0 | 0 | same | PASS |
| CI ceiling gate | — | 878 | `node scripts/check-type-ceiling.mjs` | PASS |
| Unit tests | 548 pass | 548 pass | `pnpm test` (vitest) | PASS |

### Measurement

```bash
# Count current violations
node scripts/type-violation-scan.cjs

# CI ceiling gate (fails if core violations exceed ceiling)
node scripts/check-type-ceiling.mjs
```

---

## 2. Bundle Size

**Audit Date:** 2026-03-10 · **Remediation Completed:** 2026-03-13

### Before

| Metric | Value |
|--------|-------|
| Total production payload | 2,321,505 bytes (2,267.09 KB, **2.21 MB**) |
| Largest entry chunk (raw) | `index-C2vAyoQ1.js` — 2,073.70 KB minified |
| Entry chunk gzip | **587.59 KB** |
| Emitted JS files | 263 |
| Dominant chunk share | 94.90% (`index-C2vAyoQ1.js`) |

### Fixes Applied

| Change | Files Touched |
|--------|---------------|
| Lazy-load `emoji-picker-react` | `web/src/components/EmojiPicker.tsx` |
| Lazy-load `Editor.tsx` at all call sites (moves yjs, lowlight, y-websocket, TipTap extensions out of entry chunk) | `web/src/components/Editor.tsx` + call sites |
| Added `EditorSkeleton.tsx` loading state | `web/src/components/EditorSkeleton.tsx` |
| Added `LazyErrorBoundary.tsx` error boundary | `web/src/components/LazyErrorBoundary.tsx` |
| Removed unused `@tanstack/query-sync-storage-persister` | `web/package.json` |
| Added CI budget gate script at 275 KB gzip | `web/scripts/check-bundle-budget.mjs` |

### After

| Metric | Before | After | Measurement Method | Status |
|--------|--------|-------|--------------------|--------|
| Entry chunk gzip | 587.59 KB | **259.97 KB** | `check-bundle-budget.mjs` (`zlib.gzipSync`) | PASS (−55.8%) |
| Entry chunk gzip (Vite report) | 587.59 KB | 266.21 KB | Vite build output | PASS (−54.7%) |
| Entry chunk raw | 2,073.70 KB | 977.87 KB | `web/dist/assets/` | — |
| Total production payload | 2.21 MB | 3.28 MB | Sum of `dist/` bytes | Expected increase |
| Emitted JS files | 263 | 308 | `dist/assets/` count | +45 lazy chunks |
| ≥20% entry chunk reduction target | — | −55.8% | Budget script | PASS |

### Measurement

```bash
pnpm build
node web/scripts/check-bundle-budget.mjs
# Output: PASS/FAIL with gzip size vs 275 KB budget
```

---

## 3. API Response Time

**Audit Date:** 2026-03-10 · **Remediation Completed:** 2026-03-12

### Before

_c50 concurrency, ApacheBench, local API on :3000, PostgreSQL seeded (572 docs, 104 issues, 26 users, 35 sprints)_

| Endpoint | P50 (ms) | P95 (ms) | P99 (ms) |
|----------|--------:|---------:|---------:|
| `/api/documents?type=wiki` | 101 | 123 | 131 |
| `/api/issues` | 87 | 105 | 116 |
| `/api/projects` | 42 | 54 | 58 |
| `/api/weeks` | 39 | 46 | 53 |
| `/api/programs` | 30 | 36 | 40 |

### Fixes Applied

| Change | Files Touched |
|--------|---------------|
| Migration 038 — composite partial index `idx_documents_list_active_type` on `(workspace_id, document_type, position ASC, created_at DESC) WHERE archived_at IS NULL AND deleted_at IS NULL` | `api/src/db/migrations/038_*.sql` |
| Migration 038 — composite partial index `idx_documents_person_workspace_user` on `(workspace_id, (properties->>'user_id')) WHERE document_type = 'person'`; converts Nested Loop Join to Hash Join | `api/src/db/migrations/038_*.sql` |
| `/api/issues` list query — removed `d.content` from SELECT (not needed for list view) | `api/src/routes/issues.ts` |

### After

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

### Measurement

```bash
# Pre-requisites: pnpm dev running (API on :3000), DB seeded
node audits/scripts/api-benchmark.mjs
# Output: audits/artifacts/api-benchmark-result.json
```

---

## 4. Database Query Efficiency

**Audit Date:** 2026-03-10 · **Remediation Completed:** 2026-03-15

### Before

_Source: `audits/artifacts/db-query-efficiency-baseline.json` (captured 2026-03-10T06:34:08Z)_

| User Flow | Total Queries | Slowest Query (ms) | N+1 Detected? | Repeated Query Count |
|-----------|-------------:|-------------------:|:-------------:|---------------------:|
| Load main page | 54 | 3.39 | Yes | 9 |
| View a document | 16 | 2.29 | No | 4 |
| List issues | 17 | 2.40 | No | 4 |
| Load sprint board | 14 | 2.24 | No | 3 |
| Search content | 5 | 1.00 | No | 1 |

### Fixes Applied

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

### After

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

### Measurement

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

## 5. Test Coverage and Quality

**Audit Date:** 2026-03-10 · **Remediation Completed:** 2026-03-14

### Before

| Metric | Value |
|--------|-------|
| Total tests | 1,471 (API: 451, Web: 151, E2E: 869) |
| API line coverage | 40.52% |
| API branch coverage | 33.44% |
| Web line coverage | 28.53% (13 failing tests) |
| Web branch coverage | 19.38% (13 failing tests) |
| `waitForTimeout(...)` calls in E2E | 619 |
| Dark-logic specs covered | 0 of 3 (collaboration convergence, offline replay, RBAC revocation) |

### Fixes Applied

| Change | Files Touched |
|--------|---------------|
| Added unit tests for API document CRUD | `api/src/utils/document-crud.ts` |
| Added unit tests for API route branches | `api/src/routes/documents.ts` |
| Added API permissions coverage | `api/src/routes/permissions.coverage.test.ts` |
| Added API workspaces coverage | `api/src/routes/workspaces.ts` |
| Added web dashboard tests | `web/src/pages/Dashboard.tsx`, `web/src/components/dashboard/DashboardVariantC.tsx` |
| Added web upload service tests | `web/src/services/upload.ts`, `web/src/components/editor/ImageUpload.tsx` |
| Added web shared transport and date utils tests | `web/src/lib/api.ts`, `web/src/lib/date-utils.ts`, `web/src/hooks/useDashboardFocus.ts` |
| Replaced 82 fixed `waitForTimeout` waits with event-based waits | `e2e/*.spec.ts` (8 targeted files) |
| Added 3 dark-logic specs with grouped runtime evidence | `e2e/*.spec.ts` |
| Resolved 13 deterministic web test failures; added `clearMocks: true` (ADR-005) | `web/vitest.config.ts` |

### After

| Metric | Before | After | Measurement Method | Status |
|--------|-------:|------:|-------------------|--------|
| API statements | 41.30% | 45.35% | `pnpm --filter @ship/api test:coverage` (v8) | +4.05 pp |
| API branches | 34.33% | 38.02% | same | +3.69 pp |
| API functions | 41.43% | 46.25% | same | +4.82 pp |
| API lines | 41.49% | 45.59% | same | +4.10 pp |
| Web statements | 33.91% | 49.36% | `pnpm --filter @ship/web test:coverage` (v8) | +15.45 pp |
| Web branches | 24.09% | 39.71% | same | +15.62 pp |
| Web functions | 31.22% | 45.00% | same | +13.78 pp |
| Web lines | 34.90% | 50.44% | same | +15.54 pp |
| `waitForTimeout(...)` calls | 619 | 537 | `rg -c "waitForTimeout" e2e/*.spec.ts` | −82 (−13.2%) |
| Dark-logic specs covered | 0 | 3 | manual spec review | +3 |
| API tests (pass / fail) | 451 / 0 | 538 / 0 | `pnpm --filter @ship/api test` | +87 |
| Web tests (pass / fail) | 151 / 13 | 198 / 0 | `pnpm --filter @ship/web test` | +47 pass, −13 fail |

### Measurement

```bash
pnpm --filter @ship/api test:coverage
pnpm --filter @ship/web test:coverage
# E2E fixed-wait count:
rg -c "waitForTimeout\(" e2e/*.spec.ts
```

---

## 6. Runtime Errors and Edge Cases

**Category:** Runtime Errors and Edge Cases
**Before Date:** 2026-03-10
**After Date:** 2026-03-15

---

### Before

_Source: `audits/consolidated-audit-report-2026-03-10.md` Section 6; `audits/artifacts/console-main.log`_

| Metric | Baseline |
|--------|----------|
| Console errors during normal usage | **24** (`audits/artifacts/console-main.log`, 10-minute active editing window) |
| Unhandled promise rejections (server) | **1** — `ForbiddenError: invalid csrf token` |
| Network disconnect recovery | **Partial** — pass in baseline reconnect flow; partial under chaos (9 `login?expired=true` redirects, aborted calls) |
| Missing error boundaries | `UnifiedEditor.tsx` (no user-facing boundary for autosave/collab hard failures); `Login.tsx` (setup-status failures console-only) |
| Silent failures identified | **5** — autosave terminal failure console-only; reconnect redirect churn; login rate-limit (`429`) shows generic message; Reviews button `403 Forbidden`; 3G refresh leaves collaborator stale |
| Yjs collision divergence | **Detected** — concurrent title edits diverged between clients |

---

### Fixes Applied

| Fix | Files Changed |
|-----|---------------|
| Unhandled rejections: `checkSetup` and `checkCaiaStatus` wrapped in `try/catch` | `web/src/pages/Login.tsx` |
| Silent failures: 8 empty `.catch(() => {})` blocks replaced with `console.error` logging | `web/src/components/PlanQualityBanner.tsx`, `RetroQualityBanner.tsx` |
| `/issues` error states surface with `role=status aria-live=polite` | `web/src/components/IssuesList.tsx` |
| Reconnect retry gate + delayed session-expired redirect to prevent churn | `web/src/lib/api.ts` |
| Optimistic concurrency (`expected_title`) on document PATCH; `409 WRITE_CONFLICT` on stale writes | `api/src/routes/documents.ts`, `web/src/components/UnifiedEditor.tsx` |
| Login rate-limit (`429`) surfaces explicit lockout message instead of generic error | `api/src/app.ts`, `web/src/pages/Login.tsx`, `web/src/hooks/useAuth.tsx` |
| Reviews nav hidden for non-admin users; clearer access message on direct URL | `web/src/pages/App.tsx`, `web/src/pages/ReviewsPage.tsx` |
| Autosave terminal failure shows persistent editor banner until successful save | `web/src/hooks/useAutoSave.ts`, `web/src/components/UnifiedEditor.tsx` |

---

### After

| Metric | Before | After | Method | Status |
|--------|--------|-------|--------|--------|
| Console errors per session | 24 | **2** | Live Playwright page traversal (8 routes) — `category6-console-recheck.mjs` | **PASS** ✅ |
| Unhandled promise rejections | 1 | **0** | Static analysis — `Login.tsx` lines 79–108 confirmed try/caught | **PASS** ✅ |
| Silent failures (no user feedback) | 5 | **0** | Static analysis — 8 empty catch blocks replaced; `IssuesList.tsx` `role=status` confirmed | **PASS** ✅ |
| Network disconnect recovery | Partial (9 redirect churns) | **Success (0 redirect churns)** | Live Playwright disconnect test — `category6-disconnect-recheck.mjs` | **PASS** ✅ |
| Yjs collision divergence | Divergence | **Converged (Last-Write-Wins)** | Live Playwright collision test — `category6-collision-recheck.mjs` | **PASS** ✅ |

The 2 remaining console errors are transient `401` responses firing immediately post-login before the session cookie propagates — not persistent across navigation.

---

### Measurement

```bash
# Console error count (requires pnpm dev running):
node audits/artifacts/category6-console-recheck.mjs
# → audits/artifacts/category6-recheck-result.json

# Yjs collision convergence:
node audits/artifacts/category6-collision-recheck.mjs
# → audits/artifacts/category6-collision-recheck.json

# Network disconnect recovery:
node audits/artifacts/category6-disconnect-recheck.mjs
# → audits/artifacts/category6-disconnect-recheck.json
```

All 538 unit tests pass (`pnpm test`, run 2026-03-14).

---

### Image Command Fix (Production)

The `/image` slash command worked locally but was broken in production (Railway + Vercel) due to three independent runtime errors.

| Root Cause | Fix |
|-----------|-----|
| Uploads landing on ephemeral disk — wiped on redeploy | Switched to Cloudflare R2; `getS3Client()` reads `R2_ENDPOINT` |
| `CDN_DOMAIN` missing in Railway — `POST /api/files/:id/confirm` threw 500 | Env var documented and required |
| `authMiddleware` on `GET /api/files/:id/serve` blocked `<img>` tag loads | Auth removed from serve route; file UUID is sufficient authorization |

| Metric | Before | After |
|--------|--------|-------|
| Images survive redeploy | No (ephemeral disk) | Yes (R2 object storage) |
| Upload confirmation in prod | 500 (`CDN_DOMAIN` missing) | 200 with R2 CDN URL |
| Images load in `<img>` tags | Blocked (auth required) | Loads without auth |

---

## 7. Accessibility Compliance

**Audit Date:** 2026-03-10 · **Remediation Completed:** 2026-03-13

### Before

| Page | Lighthouse Score | Serious Violations |
|------|----------------:|-------------------:|
| `/login` | 100 | 0 |
| `/dashboard` | 95 | 10 |
| `/my-week` | 95 | 20 |
| `/docs` | 100 | 0 |
| `/issues` | 96 | 1 |
| `/projects` | 96 | 1 |
| `/programs` | 95 | 1 |
| `/team/allocation` | 96 | 1 |
| `/settings` | 100 | 0 |
| **Total** | — | **34** |

| Metric | Baseline |
|--------|----------|
| Color contrast failures | 34 (all Serious violations were contrast failures) |
| Missing ARIA labels / roles | None detected by axe |
| Keyboard navigation | Partial — global nav works; table content traversal incomplete |
| Manual VoiceOver | `/issues` table rows/cells silent (context not announced) |

### Fixes Applied

| Component / File | Element | Old Value | Old Ratio | New Value | New Ratio | WCAG |
|------------------|---------|-----------|----------:|-----------|----------:|:----:|
| Global CSS — focus | Focus ring (`:focus-visible`) | `#005ea2` | 2.89:1 | `#1a85d9` | 5.00:1 | PASS |
| Editor — placeholder | Editor placeholder text | `#525252` | 2.49:1 | `#808080` | 4.92:1 | PASS |
| Editor — drag handle | Drag handle (default) | `#525252` | 2.49:1 | `#808080` | 4.92:1 | PASS |
| Editor — mentions | `.mention` / `.mention-document` | `#5e6ad2` | 4.14:1 | `#6b7ae0` | 5.08:1 | PASS |
| `Programs.tsx` | Unassigned dash | `text-muted/50` | 2.50:1 | `text-muted` | 5.63:1 | PASS |
| `TeamMode.tsx` | Archived avatars | `bg-gray-400` | 2.30:1 | `bg-gray-500` | 4.60:1 | PASS |
| 40+ components | `text-accent` as text color | `#005ea2` | 2.89:1 | `#1a85d9` (via `text-accent-text`) | 5.00:1 | PASS |
| All files | `text-muted/<opacity>` variants | `#8a8a8a` at 30–60% | 1.41–2.57:1 | `text-muted` (100%) | 5.63:1 | PASS |
| `KanbanBoard` | Archived assignee avatar | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |
| `AccountabilityGrid` | Empty-state badge | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |
| `TeamDirectory` | Archived avatar | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |
| `IssuesList.tsx` | Row keyboard handler | — | — | `role=status` + keyboard row handler | — | PASS |

**Files touched:** `web/src/components/dashboard/DashboardVariantC.tsx`, `web/src/pages/MyWeekPage.tsx`, `web/src/components/IssuesList.tsx`, `web/src/components/DashboardSidebar.tsx`, 40+ components via `text-accent-text` token.

### After

| Metric | Before | After | Measurement Method | Status |
|--------|-------:|------:|-------------------|--------|
| Total Serious violations | 34 | 0 | axe automated scan | PASS |
| Total Critical violations | 0 | 0 | axe automated scan | PASS |
| Pages with Serious violations | 6 | 0 | axe automated scan | PASS |
| Lighthouse score `/dashboard` | 95 | 100 | Lighthouse | PASS |
| Lighthouse score `/my-week` | 95 | 100 | Lighthouse | PASS |
| Lighthouse score `/issues` | 96 | 100 | Lighthouse | PASS |
| CI regression gate | none | blocking | GitHub Actions `007-a11y-completion-gates` | PASS |

### Measurement

```bash
# Pre-requisites: pnpm dev running on :5173, DB seeded
SHIP_BASE_URL=http://localhost:5173 node audits/artifacts/accessibility/run-a11y-audit.mjs
```

Evidence bundles: `audits/artifacts/accessibility/results/`

---

## Summary

Roll-up table showing the single most important metric per category, before/after values, and percent change.

| # | Category | Key Metric | Before | After | % Change |
|---|----------|-----------|-------:|------:|---------:|
| 1 | Type Safety | Core violations (`any` + `as` + `!` + `@ts-*`) | 1,283 | **878** (CI gate locked) | **−31.6% TARGET MET** |
| 2 | Bundle Size | Entry chunk gzip size | 587.59 KB | 259.97 KB | −55.8% |
| 3 | API Response Time | `/api/documents?type=wiki` P95 at c50 | 123 ms | 8 ms | −93.5% |
| 4 | Database Query Efficiency | Total queries across 5 user flows | 106 | **68** (all 5 flows ≥ −20%) | **−35.8% TARGET MET** |
| 5 | Test Coverage and Quality | Web statement coverage | 33.91% | 49.36% (198 tests, 0 failing) | +15.45 pts |
| 6 | Runtime Errors and Edge Cases | Browser console `error` entries per session | 24 | **2** | **−91.7% TARGET MET** |
| 7 | Accessibility Compliance | Total Serious violations (axe) | 34 | 0 | −100% |

---

## Auth Stability Fixes (Track C — 2026-03-13–14)

These fixes were completed as part of the sprint but fall outside the 7 core audit categories. They address production cross-origin authentication reliability.

| Fix | Description | Commit |
|-----|-------------|--------|
| SameSite=None cookie | Production session cookies now use `SameSite=None; Secure` to support cross-origin requests between Vercel frontend and Railway API | `2d0db5c` |
| ADR-006 | Architectural decision record documenting the SameSite change and its tradeoffs | `15d7854` |
| 401 retry elimination | Turbulence no longer retries on `UNAUTHORIZED` (401) responses, eliminating request floods | `ec5f9a8` |
| False session-expired prevention | `apiGet`/`fetchWithCsrf` no longer redirect to login on 401 UNAUTHORIZED (avoids false session-expired for background calls) | `8e40514` |
| 429 amber alert | Shows amber warning instead of session-expired redirect on 429 Too Many Requests | `075a3f2` |
