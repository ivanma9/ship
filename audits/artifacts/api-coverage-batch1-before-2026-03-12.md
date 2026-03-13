# API Coverage Snapshot Before Batch 1

- Date: 2026-03-12
- Scope: API unit/integration coverage before implementing Batch 1 (`documents` route branches + `document-crud` helper coverage)
- Command:

```bash
pnpm --filter @ship/api test:coverage -- --reporter=dot
```

## Package Coverage

| Metric | Value |
| --- | --- |
| Statements | 42.59% |
| Branches | 35.42% |
| Functions | 42.76% |
| Lines | 42.80% |

## Relevant File Baseline

| File | Statements | Branches | Functions | Lines |
| --- | --- | --- | --- | --- |
| `api/src/routes/documents.ts` | 61.29% | 57.07% | 57.89% | 60.45% |
| `api/src/utils/document-crud.ts` | 30.58% | 34.61% | 28.57% | 31.16% |

## Measurement Notes

- Measurement method: package coverage via Vitest with the repo’s canonical API coverage command.
- This snapshot was taken before adding `api/src/routes/documents.coverage.test.ts` and `api/src/utils/document-crud.test.ts`.
