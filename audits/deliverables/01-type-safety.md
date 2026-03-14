# 01 — Type Safety

**Category:** Type Safety
**Audit Date:** 2026-03-09
**Source:** `audits/type-safety-audit-2026-03-09.md`

Type-safety violations were counted via an AST-based Node.js script scanning all `.ts` and `.tsx` source files in `api/`, `web/`, and `shared/` (320 files total, excluding `.d.ts`). Six categories were measured: `any` types, `as` assertions, non-null assertions (`!`), `@ts-ignore`/`@ts-expect-error` directives, untyped function parameters, and missing explicit return types.

---

## Before — Core Violations by Package

_Source: `audits/type-safety-audit-2026-03-09.md`, Section 3_

| Package    | `any` | `as`  | `!`   | `@ts-ignore` / `@ts-expect-error` | Untyped Params | Missing Return Types | Total |
|------------|------:|------:|------:|----------------------------------:|---------------:|---------------------:|------:|
| `api/`     | 229   | 317   | 296   | 0                                 | 283            | 1,246                | 2,371 |
| `web/`     | 33    | 372   | 33    | 1                                 | 1,168          | 3,208                | 4,815 |
| `shared/`  | 0     | 2     | 0     | 0                                 | 0              | 0                    | 2     |
| **Total**  | **262** | **691** | **329** | **1**                         | **1,451**      | **4,454**            | **7,188** |

**Core metric total** (`any` + `as` + `!` + `@ts-*`): **1,283**

### Top 5 Violation-Dense Files (Before)

| File | Total | `any` | `as` | `!` | `@ts-*` | Untyped Params | Missing Return Types |
|------|------:|------:|-----:|----:|--------:|---------------:|---------------------:|
| `web/src/components/IssuesList.tsx` | 189 | 0 | 4 | 0 | 0 | 47 | 138 |
| `web/src/pages/App.tsx` | 180 | 0 | 1 | 0 | 0 | 30 | 149 |
| `api/src/routes/weeks.ts` | 159 | 11 | 26 | 48 | 0 | 24 | 50 |
| `web/src/hooks/useSessionTimeout.test.ts` | 159 | 0 | 2 | 0 | 0 | 0 | 157 |
| `web/src/pages/ReviewsPage.tsx` | 150 | 0 | 6 | 4 | 0 | 57 | 83 |

---

## After — Improvement Plan Targets

_Source: `audits/type-safety-audit-2026-03-09.md`, Section 7_

No remediation has been applied yet. The improvement plan targets a 25% reduction in core violations.

| Metric | Before | Target | Reduction |
|--------|-------:|-------:|----------:|
| Core violations (`any` + `as` + `!` + `@ts-*`) | 1,283 | ≤ 962 | −321 (−25%) |

### Planned Reduction by Phase

| Phase | Scope | Target Reduction |
|-------|-------|----------------:|
| Phase 1 — API hotspot hardening | `api/src/routes/weeks.ts`, `api/src/routes/issues.ts` | −120 |
| Phase 2 — Web core flow typing | `IssuesList.tsx`, `App.tsx`, `ReviewsPage.tsx` | −110 |
| Phase 3 — Test and mock typing cleanup | `accountability.test.ts`, `transformIssueLinks.test.ts` | −70 |
| Phase 4 — CI regression guardrails | Block increases in core violation count | −21+ and lock-in |

**Note:** After-state measurements are not yet available. This document will be updated after Phase 1–4 implementation.

---

## Summary

Strict mode is already enabled across the full repository and suppression directives are effectively absent (1 total). The primary debt is concentrated in `as` assertions (691) and non-null assertions in `api/src/routes/weeks.ts`. The `shared/` package has only 2 violations and serves as the quality baseline. The improvement plan targets a minimum −25% reduction (1,283 → ≤ 962 core violations) across four phases.
