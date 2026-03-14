# 01 — Type Safety

**Category:** Type Safety
**Before Date:** 2026-03-09
**After Date:** 2026-03-14
**Source:** `audits/type-safety-audit-2026-03-09.md`, `scripts/type-violation-scan.cjs`

Type-safety violations were counted via an AST-based Node.js script (`scripts/type-violation-scan.cjs`) scanning all `.ts` and `.tsx` source files in `api/`, `web/`, and `shared/` (excluding `.d.ts`). Six categories were measured: `any` types, `as` assertions, non-null assertions (`!`), `@ts-ignore`/`@ts-expect-error` directives, untyped function parameters, and missing explicit return types.

**Reproducibility:** Re-run with `node scripts/type-violation-scan.cjs` from repo root.

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

## After — Re-measured 2026-03-14

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

`scripts/check-type-ceiling.mjs` — fails CI if core violations exceed 1,143. Ceiling is a ratchet: it can only be updated downward with justification.

```bash
node scripts/check-type-ceiling.mjs   # PASS: at ceiling
```

### Remaining Gap to 25% Target

| Metric | Baseline | Current | Target (−25%) | Remaining |
|--------|--------:|--------:|--------------:|----------:|
| Core violations | 1,283 | 1,143 | ≤ 962 | −181 more needed |

---

## Planned Future Reduction (Option A — TODO)

_See `docs/TODO.md` for the full phased plan._

| Phase | Scope | Target Reduction |
|-------|-------|----------------:|
| Phase 1 — API hotspot hardening | `api/src/routes/weeks.ts`, `api/src/routes/issues.ts` | −120 |
| Phase 2 — Web core flow typing | `IssuesList.tsx`, `App.tsx`, `ReviewsPage.tsx` | −110 |
| Phase 3 — Test and mock typing cleanup | `transformIssueLinks.test.ts` | −70 |
| Phase 4 — Lower CI ceiling | Update `CEILING` in `check-type-ceiling.mjs` after each phase | lock-in |

---

## Summary

Core violations dropped from 1,283 → 1,143 (−10.9%) through incidental improvements made during the sprint. A CI ceiling script now prevents regressions. The remaining 181 violations needed to hit the −25% target are tracked in `docs/TODO.md` as a phased follow-up.
