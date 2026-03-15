# 01 — Type Safety

**Category:** Type Safety
**Before Date:** 2026-03-09
**After Date:** 2026-03-15
**Source:** `audits/type-safety-audit-2026-03-09.md`, `scripts/type-violation-scan.cjs`

Type-safety violations were counted via an AST-based Node.js script (`scripts/type-violation-scan.cjs`) scanning all `.ts` and `.tsx` source files in `api/`, `web/`, and `shared/` (excluding `.d.ts`). Six categories were measured: `any` types, `as` assertions, non-null assertions (`!`), `@ts-ignore`/`@ts-expect-error` directives, untyped function parameters, and missing explicit return types.

**How to Reproduce:**
```bash
node scripts/type-violation-scan.cjs
# CI gate: node scripts/check-type-ceiling.mjs
```

---

## Before — Core Violations by Package

_Source: `audits/type-safety-audit-2026-03-09.md`, Section 3 — 320 files scanned_

| Package    | `any` | `as`  | `!`   | `@ts-ignore` / `@ts-expect-error` | Untyped Params | Missing Return Types | Total |
|------------|------:|------:|------:|----------------------------------:|---------------:|---------------------:|------:|
| `api/`     | 229   | 317   | 296   | 0                                 | 283            | 1,246                | 2,371 |
| `web/`     | 33    | 372   | 33    | 1                                 | 1,168          | 3,208                | 4,815 |
| `shared/`  | 0     | 2     | 0     | 0                                 | 0              | 0                    | 2     |
| **Total**  | **262** | **691** | **329** | **1**                         | **1,451**      | **4,454**            | **7,188** |

**Core metric** (`any` + `as` + `!` + `@ts-*`): **1,283**

### Top 5 Violation-Dense Files (Before)

| File | Total | `any` | `as` | `!` | `@ts-*` |
|------|------:|------:|-----:|----:|--------:|
| `web/src/components/IssuesList.tsx` | 189 | 0 | 4 | 0 | 0 |
| `web/src/pages/App.tsx` | 180 | 0 | 1 | 0 | 0 |
| `api/src/routes/weeks.ts` | 159 | 11 | 26 | 48 | 0 |
| `web/src/hooks/useSessionTimeout.test.ts` | 159 | 0 | 2 | 0 | 0 |
| `web/src/pages/ReviewsPage.tsx` | 150 | 0 | 6 | 4 | 0 |

---

## After — Re-measured 2026-03-14 (Pre-Track B)

_Re-run via `node scripts/type-violation-scan.cjs` — 336 files scanned (16 new files added during sprint)_

| Package    | `any` | `as`  | `!`   | `@ts-ignore` / `@ts-expect-error` | Total Core |
|------------|------:|------:|------:|----------------------------------:|-----------:|
| `api/`     | 92    | 432   | 206   | 0                                 | 730        |
| `web/`     | 13    | 356   | 43    | 1                                 | 413        |
| `shared/`  | 0     | 0     | 0     | 0                                 | 0          |
| **Total**  | **105** | **788** | **249** | **1**                          | **1,143**  |

**Core metric** (`any` + `as` + `!` + `@ts-*`): **1,143** (was 1,283 — **−140, −10.9%**)

### Top 10 Violation-Dense Files (After)

| File | Total |
|------|------:|
| `api/src/routes/weeks.ts` | 110 |
| `api/src/routes/issues.ts` | 89 |
| `web/src/pages/ReviewsPage.tsx` | 76 |
| `api/src/__tests__/transformIssueLinks.test.ts` | 74 |
| `web/src/pages/App.tsx` | 65 |
| `api/src/routes/projects.ts` | 59 |
| `api/src/db/seed.ts` | 58 |
| `web/src/components/IssuesList.tsx` | 58 |
| `web/src/hooks/useWeeksQuery.ts` | 58 |
| `web/src/pages/UnifiedDocumentPage.tsx` | 54 |

### CI Gate Added

`scripts/check-type-ceiling.mjs` — fails CI if core violations exceed the current ceiling. Ceiling is a ratchet: it can only be updated downward with justification. Added to `.github/workflows/ci.yml` under "Check type violation ceiling (ratchet)" step.

```bash
node scripts/check-type-ceiling.mjs   # PASS: at ceiling
```

### Pre-Track B Status (Gap to 25% Target)

| Metric | Baseline | Current | Target (−25%) | Remaining |
|--------|--------:|--------:|--------------:|----------:|
| Core violations | 1,283 | 1,143 | ≤ 962 | −181 more needed |

---

## Track B Type Safety Sprint — 2026-03-14

Executed 4-phase type safety improvement targeting −181 violations (1,143 → ≤ 962).

### Phase-by-Phase Results

| Phase | Files Changed | Before | After | Delta |
|-------|--------------|-------:|------:|------:|
| Phase 1 — API hotspot hardening | `issues.ts`, `weeks.ts` | 1,143 | 1,004 | −139 |
| Phase 2 — Web core flow typing | `ReviewsPage.tsx`, `App.tsx`, `IssuesList.tsx` | 1,004 | 992 | −12 |
| Phase 3 — Test/mock typing | `transformIssueLinks.test.ts`, `transformIssueLinks.ts` | 992 | 929 | −63 |
| Phase 4 — Lock-in (ceiling + CI) | `check-type-ceiling.mjs`, `ci.yml` | 929 | 929 | 0 |
| Phase 5 — API layer type hardening (2026-03-15) | 25 files across API routes, tests, middleware | 943 | 878 | −65 |
| **Total** | | **1,143** | **878** | **−265** |

**Final core metric: 878** (was 1,143 at Track B start, 1,283 original baseline — **−31.6% from original baseline**)

### After — Re-measured Post-Phase 5 (2026-03-15)

| Package    | `any` | `as`  | `!`   | `@ts-ignore` / `@ts-expect-error` | Total Core |
|------------|------:|------:|------:|----------------------------------:|-----------:|
| `api/`     | 89    | 303   | 84    | 0                                 | 476        |
| `web/`     | 13    | 349   | 39    | 1                                 | 402        |
| `shared/`  | 0     | 0     | 0     | 0                                 | 0          |
| **Total**  | **102** | **652** | **123** | **1**                          | **878**  |

### Techniques Used

- **Phase 1:** Typed route handler params as `AuthenticatedRequest` directly (instead of casting `req as AuthenticatedRequest` on each use); added `IssueProperties` interface to `issues.ts` eliminating property bag casts; added `SprintRow`/`StandupRow`/`TipTapDoc` interfaces to `weeks.ts`; narrowed query param access with `typeof param === 'string'` guards instead of `as string` casts.
- **Phase 2:** Replaced `Map.get()!` with `?.` optional chaining; narrowed `EventTarget` with `instanceof HTMLElement` guard; removed redundant casts on already-typed `ApprovalInfo` fields.
- **Phase 3:** Exported `TipTapDoc`/`TipTapNode` from `transformIssueLinks.ts`; changed return type to `Promise<TipTapDoc>`; removed 56 non-null assertions on array indices (safe without `noUncheckedIndexedAccess`).
- **Phase 4:** Lowered `CEILING` to 929; added `check-type-ceiling.mjs` to CI pipeline.
- **Phase 5:** Eliminated 65 core type violations across 25 API layer files — replaced `as any` casts in pg mock helpers with typed `mockQueryResult` wrappers, added proper generics to `pool.query<T>()` calls, narrowed route handler types, removed redundant non-null assertions.

### CI Gate (Updated)

Ceiling lowered from 1,143 → 878. `scripts/check-type-ceiling.mjs` now runs in CI.

```bash
node scripts/check-type-ceiling.mjs
# Type violation ceiling check
#   Ceiling : 878
#   Current : 878
#   PASS: at ceiling
```

---

## Summary

Core violations dropped from 1,283 (original baseline) → 878 (Phase 5 final) — **a 31.6% reduction**, exceeding the 25% target (≤ 962). CI ceiling ratchet enforces that violations can only decrease going forward.

## Test Status

All unit tests pass: **547 tests across 36 test files**, 0 failures (vitest, 2026-03-15).
