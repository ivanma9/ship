# API Coverage Snapshot After Batch 1

- Date: 2026-03-12
- Scope: API unit/integration coverage after implementing Batch 1 (`documents` route branches + `document-crud` helper coverage)
- Command:

```bash
pnpm --filter @ship/api test:coverage -- --reporter=dot
```

## Package Coverage

| Metric | Value |
| --- | --- |
| Statements | 43.41% |
| Branches | 36.39% |
| Functions | 44.75% |
| Lines | 43.59% |

## Relevant File After Snapshot

| File | Statements | Branches | Functions | Lines |
| --- | --- | --- | --- | --- |
| `api/src/routes/documents.ts` | 66.30% | 62.02% | 57.89% | 65.72% |
| `api/src/utils/document-crud.ts` | 77.64% | 61.53% | 85.71% | 76.62% |

## Delta vs Before

| Metric | Delta |
| --- | --- |
| Statements | +0.82 |
| Branches | +0.97 |
| Functions | +1.99 |
| Lines | +0.79 |

## Measurement Notes

- Measurement method: package coverage via Vitest with the repo’s canonical API coverage command.
- Added tests:
  - `api/src/routes/documents.coverage.test.ts`
  - `api/src/utils/document-crud.test.ts`
