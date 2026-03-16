# 05 — Test Coverage & Quality

**Audit Date:** 2026-03-10 · **Remediation Completed:** 2026-03-14

## Before

| Metric | Value |
|--------|-------|
| Total tests | 1,471 (API: 451, Web: 151, E2E: 869) |
| API line coverage | 40.52% |
| API branch coverage | 33.44% |
| Web line coverage | 28.53% (13 failing tests) |
| Web branch coverage | 19.38% (13 failing tests) |
| `waitForTimeout(...)` calls in E2E | 619 |
| Dark-logic specs covered | 0 of 3 (collaboration convergence, offline replay, RBAC revocation) |

## Fixes Applied

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

## After

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

## Measurement

```bash
pnpm --filter @ship/api test:coverage
pnpm --filter @ship/web test:coverage
# E2E fixed-wait count:
rg -c "waitForTimeout\(" e2e/*.spec.ts
```

## Key Decisions

- Web branch coverage at 2026-03-14 (39.71%) is slightly below the 2026-03-12 snapshot (41.88%) because spec-003 added new test files covering happy paths without proportionally increasing branch coverage. This is expected and accepted per ADR-005.
- `clearMocks: true` added globally to `web/vitest.config.ts` to prevent mock-state leakage across tests (root cause of the 13 deterministic failures).
