# 01 — Type Safety

**Audit Date:** 2026-03-09 · **Remediation Completed:** 2026-03-13

## Before

_Source: `audits/type-safety-audit-2026-03-09.md` — 320 files scanned_

| Package   | `any` | `as` | `!` | `@ts-ignore` / `@ts-expect-error` | Untyped Params | Missing Return Types | Total |
|-----------|------:|-----:|----:|----------------------------------:|---------------:|---------------------:|------:|
| `api/`    | 229   | 317  | 296 | 0                                 | 283            | 1,246                | 2,371 |
| `web/`    | 33    | 372  | 33  | 1                                 | 1,168          | 3,208                | 4,815 |
| `shared/` | 0     | 2    | 0   | 0                                 | 0              | 0                    | 2     |
| **Total** | **262** | **691** | **329** | **1**                        | **1,451**      | **4,454**            | **7,188** |

**Core metric** (`any` + `as` + `!` + `@ts-*`): **1,283**

## Fixes Applied

| Change | Files Touched |
|--------|--------------|
| Typed route handler params as `AuthenticatedRequest`; added `IssueProperties` interface eliminating property bag casts | `api/src/routes/issues.ts` |
| Added `SprintRow`/`StandupRow`/`TipTapDoc` interfaces; narrowed query params with `typeof` guards instead of `as string` casts | `api/src/routes/weeks.ts` |
| Replaced `Map.get()!` with `?.` optional chaining; narrowed `EventTarget` with `instanceof HTMLElement` guard | `web/src/pages/ReviewsPage.tsx`, `web/src/pages/App.tsx`, `web/src/components/IssuesList.tsx` |
| Exported `TipTapDoc`/`TipTapNode` from transform module; changed return type to `Promise<TipTapDoc>`; removed 56 non-null assertions on array indices | `api/src/__tests__/transformIssueLinks.test.ts`, `api/src/services/transformIssueLinks.ts` |
| Added CI ceiling ratchet; ceiling set to 929 then lowered to 878 | `scripts/check-type-ceiling.mjs`, `.github/workflows/ci.yml` |
| Replaced `as any` casts in pg mock helpers with typed `mockQueryResult` wrappers; added generics to `pool.query<T>()` calls; narrowed route handler types; removed redundant non-null assertions | 25 files across API routes, tests, middleware |

## After

_Re-measured post-remediation — 336 files scanned_

| Metric | Before | After | Measurement Method | Status |
|--------|-------:|------:|--------------------|--------|
| Core violations (`any` + `as` + `!` + `@ts-*`) | 1,283 | 878 | `node scripts/type-violation-scan.cjs` | PASS — −31.6%, exceeds 25% target |
| `api/` core | 730 | 476 | same | PASS |
| `web/` core | 413 | 402 | same | PASS |
| `shared/` core | 0 | 0 | same | PASS |
| CI ceiling gate | — | 878 | `node scripts/check-type-ceiling.mjs` | PASS |
| Unit tests | 548 pass | 548 pass | `pnpm test` (vitest) | PASS |

## Measurement

```bash
# Count current violations
node scripts/type-violation-scan.cjs

# CI ceiling gate (fails if core violations exceed ceiling)
node scripts/check-type-ceiling.mjs
```

## Key Decisions

- CI ratchet ceiling — violations can only decrease, never increase. Enforced via `scripts/check-type-ceiling.mjs`.
