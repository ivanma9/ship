# API Coverage Batch 2 Before Snapshot (2026-03-12)

Measurement method:

```bash
pnpm --filter @ship/api test:coverage -- --reporter=dot
```

Measured before implementing Batch 2 permission/workspace/invite coverage.

Overall API coverage:

| Metric | Value |
| --- | --- |
| Statements | 43.41% |
| Branches | 36.39% |
| Functions | 44.75% |
| Lines | 43.59% |

Target route/file coverage before Batch 2:

| File | Branches | Lines |
| --- | --- | --- |
| `api/src/routes/admin.ts` | 6.36% | 14.11% |
| `api/src/routes/workspaces.ts` | 43.02% | 39.46% |
| `api/src/routes/invites.ts` | 23.07% | 30.30% |

Notes:
- Snapshot taken after Batch 1 document/dashboard coverage work.
- The same command must be used for the after snapshot.
