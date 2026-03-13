# Coverage Snapshot After Implementation (2026-03-12)

This document is the canonical after snapshot for the current API and web unit/integration coverage improvement work.

## Measurement Method

Commands:

```bash
pnpm --filter @ship/api test:coverage -- --reporter=dot
pnpm --filter @ship/web test:coverage -- --reporter=dot
```

Both surfaces were measured with the same commands as the before snapshot.

## After Numbers

| Surface | Statements | Branches | Functions | Lines |
| --- | ---: | ---: | ---: | ---: |
| API | 45.35% | 38.02% | 46.25% | 45.59% |
| Web | 49.38% | 41.88% | 44.57% | 50.46% |

## Implemented Changes Reflected In This Snapshot

- Added API coverage for `api/src/utils/document-crud.ts`
- Added API route-branch coverage for `api/src/routes/documents.ts`
- Added API permission and workspace coverage for `api/src/routes/permissions.coverage.test.ts`
- Added web coverage for `web/src/pages/Dashboard.tsx`
- Added web coverage for `web/src/components/dashboard/DashboardVariantC.tsx`
- Added web upload-service coverage for `web/src/services/upload.ts`
- Added web image-upload behavior coverage for `web/src/components/editor/ImageUpload.tsx`
- Added web shared transport coverage for `web/src/lib/api.ts`
- Added web date utility coverage for `web/src/lib/date-utils.ts`
- Added web dashboard focus-hook coverage for `web/src/hooks/useDashboardFocus.ts`

## File Highlights

- `api/src/utils/document-crud.ts`: 77.64% statements, 61.53% branches, 76.62% lines
- `api/src/routes/documents.ts`: 66.30% statements, 62.02% branches, 65.72% lines
- `api/src/routes/workspaces.ts`: 75.33% statements, 80.23% branches, 75.33% lines
- `api/src/routes/invites.ts`: 72.72% statements, 73.07% branches, 72.72% lines
- `web/src/pages/Dashboard.tsx`: 95.58% statements, 76.54% branches, 98.38% lines
- `web/src/components/dashboard/DashboardVariantC.tsx`: 100.00% statements, 88.33% branches, 100.00% lines
- `web/src/services/upload.ts`: 89.70% statements, 67.56% branches, 91.04% lines
- `web/src/components/editor/ImageUpload.tsx`: 60.75% statements, 43.24% branches, 61.84% lines
- `web/src/lib/api.ts`: 65.93% statements, 57.79% branches, 65.31% lines
- `web/src/lib/date-utils.ts`: 100.00% statements, 100.00% branches, 100.00% lines
- `web/src/hooks/useDashboardFocus.ts`: 100.00% statements, 100.00% branches, 100.00% lines

## Numeric Delta Vs Before

| Surface | Statements Delta | Branches Delta | Functions Delta | Lines Delta |
| --- | ---: | ---: | ---: | ---: |
| API | +4.05 pts | +3.69 pts | +4.82 pts | +4.10 pts |
| Web | +15.47 pts | +17.79 pts | +13.35 pts | +15.56 pts |
