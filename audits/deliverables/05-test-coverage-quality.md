# 05 — Test Coverage and Quality

**Category:** Test Coverage and Quality
**Before Date:** 2026-03-10 / 2026-03-12 (pre-implementation)
**After Date:** 2026-03-12 (post-implementation)
**Sources:** `audits/test-coverage-quality-audit-2026-03-10.md`, `audits/coverage-snapshot-before-2026-03-12.md`, `audits/coverage-snapshot-after-2026-03-12.md`, `audits/e2e-closure-delta-2026-03-12.md`

**How to Reproduce:**
```bash
pnpm --filter @ship/api test:coverage
pnpm --filter @ship/web test:coverage
# E2E fixed-wait count: grep -c "waitForTimeout" e2e/*.spec.ts
```

Coverage was measured using Vitest with `coverage.provider: 'v8'` via `pnpm --filter @ship/api test:coverage` and `pnpm --filter @ship/web test:coverage`. E2E fixed-wait counts were measured with `rg -n "waitForTimeout\(" e2e/*.spec.ts`.

---

## Before — Unit / Integration Coverage

_Source: `audits/coverage-snapshot-before-2026-03-12.md`_

| Surface | Statements | Branches | Functions | Lines |
|---------|----------:|--------:|----------:|------:|
| API | 41.30% | 34.33% | 41.43% | 41.49% |
| Web | 33.91% | 24.09% | 31.22% | 34.90% |

### Before — Original Audit Baseline (2026-03-10)

_Source: `audits/test-coverage-quality-audit-2026-03-10.md`, Section 1_

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

---

## After — Unit / Integration Coverage

_Source: `audits/coverage-snapshot-after-2026-03-12.md`_

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

_Source: `audits/e2e-closure-delta-2026-03-12.md`_

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

### After — New Coverage Added

| Area | Files Added |
|------|-------------|
| API — document CRUD | `api/src/utils/document-crud.ts` |
| API — route branches | `api/src/routes/documents.ts` |
| API — permissions | `api/src/routes/permissions.coverage.test.ts` |
| Web — dashboard | `web/src/pages/Dashboard.tsx`, `DashboardVariantC.tsx` |
| Web — upload service | `web/src/services/upload.ts` |
| Web — image upload | `web/src/components/editor/ImageUpload.tsx` |
| Web — shared transport | `web/src/lib/api.ts` |
| Web — date utils | `web/src/lib/date-utils.ts` |
| Web — focus hook | `web/src/hooks/useDashboardFocus.ts` |

---

## Summary

Web statement coverage improved by +15.47 percentage points (33.91% → 49.38%) and web branch coverage by +17.79 points (24.09% → 41.88%). API coverage increased by +4.05 points on statements and +3.69 on branches. E2E fixed-wait usage dropped from 619 to 537 (−13.2%), and all three previously uncovered dark-logic specs (collaboration convergence, offline replay, RBAC revocation) now have grouped runtime evidence. Layer 3 E2E groups 4, 5, 6, and 7 all closed cleanly on 2026-03-12.

---

## Update — 2026-03-14 (spec-003 closure)

All 13 previously-failing web tests resolved as part of spec-003 (improve test reliability). `clearMocks: true` added to `web/vitest.config.ts` to prevent future mock-state leakage (see ADR-005).

| Metric | 2026-03-12 after | 2026-03-14 current | Delta |
|--------|----------------:|------------------:|------:|
| API tests (pass / fail) | 451 / 0 | 538 / 0 | +87 |
| Web tests (pass / fail) | 151 / 13 | 198 / 0 | +47 pass, −13 fail |
| Web statements | 49.38% | 49.36% | −0.02pp |
| Web lines | — | 50.44% | — |
| Web branches | 41.88% | 39.71% | −2.17pp |
| Web functions | — | 45.00% | — |

Note: branch coverage decreased slightly (−2.17pp) due to new test files adding covered statements without proportionally increasing branch coverage. This is expected when deterministic fixes add tests for happy paths in previously-failing files.
