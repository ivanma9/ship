# Coverage Snapshot Before Implementation (2026-03-12)

This document is the canonical before snapshot for the current API and web unit/integration coverage improvement work.

## Measurement Method

Commands:

```bash
pnpm --filter @ship/api test:coverage -- --reporter=dot
pnpm --filter @ship/web test:coverage -- --reporter=dot
```

Both surfaces were measured with the repo's package-level Vitest coverage commands.

## Before Numbers

| Surface | Statements | Branches | Functions | Lines |
| --- | ---: | ---: | ---: | ---: |
| API | 41.30% | 34.33% | 41.43% | 41.49% |
| Web | 33.91% | 24.09% | 31.22% | 34.90% |

## File Hotspots At Snapshot Time

- `api/src/routes/dashboard.ts`: 36.71% statements, 26.27% branches, 37.31% lines
- `api/src/utils/document-crud.ts`: 30.58% statements, 34.61% branches, 31.16% lines
- `web/src/pages/Dashboard.tsx`: 33.82% statements, 28.39% branches, 37.09% lines
- `web/src/components/dashboard/DashboardVariantC.tsx`: 0.00% statements, 0.00% branches, 0.00% lines

## Snapshot Scope

- Includes coverage state before the new dashboard and document CRUD coverage additions in this session.
- Excludes E2E coverage because Playwright app-code coverage is not instrumented in this repo.
