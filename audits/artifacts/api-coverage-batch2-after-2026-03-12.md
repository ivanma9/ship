# API Coverage Batch 2 After Snapshot (2026-03-12)

Measurement method:

```bash
pnpm --filter @ship/api test:coverage -- --reporter=dot
```

Measured after implementing Batch 2 permission/workspace/invite coverage.

Overall API coverage:

| Metric | Value |
| --- | --- |
| Statements | 45.35% |
| Branches | 38.02% |
| Functions | 46.25% |
| Lines | 45.59% |

Target route/file coverage after Batch 2:

| File | Branches | Lines |
| --- | --- | --- |
| `api/src/routes/admin.ts` | 23.56% | 26.11% |
| `api/src/routes/workspaces.ts` | 80.23% | 75.33% |
| `api/src/routes/invites.ts` | 73.07% | 72.72% |

Delta vs before:

| Scope | Metric | Before | After | Delta |
| --- | --- | --- | --- | --- |
| Package | Statements | 43.41% | 45.35% | +1.94 |
| Package | Branches | 36.39% | 38.02% | +1.63 |
| Package | Functions | 44.75% | 46.25% | +1.50 |
| Package | Lines | 43.59% | 45.59% | +2.00 |
| `admin.ts` | Branches | 6.36% | 23.56% | +17.20 |
| `admin.ts` | Lines | 14.11% | 26.11% | +12.00 |
| `workspaces.ts` | Branches | 43.02% | 80.23% | +37.21 |
| `workspaces.ts` | Lines | 39.46% | 75.33% | +35.87 |
| `invites.ts` | Branches | 23.07% | 73.07% | +50.00 |
| `invites.ts` | Lines | 30.30% | 72.72% | +42.42 |

Notes:
- Snapshot uses the same package-wide coverage command as the before snapshot.
- Batch 2 added route coverage for permission gates, duplicate membership/invite handling, invalid and expired invite paths, and admin validation branches.
