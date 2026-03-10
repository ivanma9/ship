# Type Safety Audit Report

## 1. Scope

- Category: Type Safety
- Repository: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`
- Audit scope:
  - Scanned TypeScript source in `api/`, `web/`, and `shared/` (`.ts`, `.tsx`, excluding `.d.ts`)
  - Primary counts come from an AST-based scan (not lint rule output)

## 2. Measurement Method

### Strict mode check

- Tools: `rg`, `cat`
- Command:

```bash
for f in tsconfig.json api/tsconfig.json web/tsconfig.json shared/tsconfig.json; do
  echo "--- $f"
  rg -n '"strict"|"noImplicitAny"|"strictNullChecks"' "$f"
done
```

### Type-safety count scan

- Tool: Node.js + TypeScript AST script
- Command:

```bash
node .tmp_type_safety_audit.cjs > /tmp/type_safety_results.json
```

- Categories counted:
  - `any`
  - `as` assertions
  - non-null assertions (`!`)
  - `@ts-ignore` / `@ts-expect-error`
  - untyped function parameters
  - missing explicit return types

### Method limits

- `untyped params` and `missing return types` are risk proxies, not direct correctness bugs
- Counts include inference-heavy callback and test code, which can inflate totals

## 3. Baseline Numbers

| Baseline                                | Value | Unit        | Context |
| --------------------------------------- | ----- | ----------- | ------- |
| Total `any` types                       | 262   | occurrences | 320 scanned files in `api/`, `web/`, `shared/` |
| Total `as` assertions                   | 691   | occurrences | Same scope |
| Total non-null assertions (`!`)         | 329   | occurrences | Same scope |
| Total `@ts-ignore` / `@ts-expect-error` | 1     | occurrences | Same scope |
| Strict mode enabled                     | Yes   | boolean     | Root has `strict: true`; `api`/`shared` inherit; `web` sets `strict: true` |
| Strict mode error count                 | N/A   | errors      | Not run, because strict mode is already enabled |
| Untyped function parameters             | 1451  | occurrences | Additional proxy metric |
| Missing explicit return types           | 4454  | occurrences | Additional proxy metric |
| Combined measured violations            | 7188  | occurrences | Sum of all six categories |

### Per-package breakdown

| Package   | `any` | `as` | `!` | `@ts-ignore/@ts-expect-error` | untyped params | missing return types | Total |
| --------- | ----- | ---- | --- | ----------------------------- | -------------- | -------------------- | ----- |
| `api/`    | 229   | 317  | 296 | 0                             | 283            | 1246                 | 2371  |
| `web/`    | 33    | 372  | 33  | 1                             | 1168           | 3208                 | 4815  |
| `shared/` | 0     | 2    | 0   | 0                             | 0              | 0                    | 2     |

### Top 5 dense files

| File                                      | Total | `any` | `as` | `!` | `@ts-` directives | untyped params | missing return types |
| ----------------------------------------- | ----- | ----- | ---- | --- | ----------------- | -------------- | -------------------- |
| `web/src/components/IssuesList.tsx`       | 189   | 0     | 4    | 0   | 0                 | 47             | 138                  |
| `web/src/pages/App.tsx`                   | 180   | 0     | 1    | 0   | 0                 | 30             | 149                  |
| `api/src/routes/weeks.ts`                 | 159   | 11    | 26   | 48  | 0                 | 24             | 50                   |
| `web/src/hooks/useSessionTimeout.test.ts` | 159   | 0     | 2    | 0   | 0                 | 0              | 157                  |
| `web/src/pages/ReviewsPage.tsx`           | 150   | 0     | 6    | 4   | 0                 | 57             | 83                   |

### Top 5 violation-dense files list (with counts)

1. `web/src/components/IssuesList.tsx`: 189
2. `web/src/pages/App.tsx`: 180
3. `api/src/routes/weeks.ts`: 159
4. `web/src/hooks/useSessionTimeout.test.ts`: 159
5. `web/src/pages/ReviewsPage.tsx`: 150

### Improvement target conversion (25%)

- Expanded six-metric view: baseline `7188`; 25% reduction target `1797`
- Core-metric target (`any` + `as` + `!` + `@ts-*`) is defined in the Improvement Plan

## 4. Findings (Ranked)

### 1) P1 weakness: `api/src/routes/weeks.ts` is the highest-risk API hotspot

- Evidence: 159 total in one file (11 `any`, 26 `as`, 48 `!`), file length 3156 lines
- Why it matters: Cast/non-null-heavy request and query handling can fail at runtime when assumptions break
- Scope: Week planning routes and related downstream calculations

### 2) P1 weakness: `web/` holds most type-safety debt

- Evidence: `web/` has 1168 untyped params and 3208 missing return types; top dense files include `IssuesList.tsx`, `App.tsx`, and `ReviewsPage.tsx`
- Why it matters: Refactors are harder and regressions are easier in core UI state/event flows
- Scope: Main app shell, list flows, and review workflows

### 3) P2 opportunity: suppression is low, assertion use is high

- Evidence: only 1 suppression directive, but 691 `as` assertions
- Why it matters: Good enforcement baseline already exists; replacing high-risk assertions with guards should reduce risk quickly
- Scope: API request parsing and web event/value coercion

### 4) P2 weakness: proxy metrics are inflated by tests/callback-heavy files

- Evidence: `web/src/hooks/useSessionTimeout.test.ts` has 157 missing return types and appears in top-5 dense files
- Why it matters: Raw counts can mislead prioritization if production and test paths are not separated
- Scope: `web/` tests and callback-heavy modules

### 5) P3 success: `shared/` is nearly clean

- Evidence: 2 total violations (2 `as`, zero in other categories)
- Why it matters: Shared contracts are stable and can serve as the repo quality baseline
- Scope: Shared types/contracts

## 5. Notable Successes

- Strict mode is enabled across repository configuration
- Suppression directives are effectively absent (1 total)
- `shared/` has very low violation density

## 6. Residual Risk Summary

- Highest-risk areas:
  - `api/src/routes/weeks.ts`
  - `web/src/pages/App.tsx`
  - `web/src/components/IssuesList.tsx`
  - `web/src/pages/ReviewsPage.tsx`
- Confidence:
  - Medium-high for hotspot ranking
  - Medium for absolute defect risk (two metrics are proxies)
- Blind spots:
  - No semantic lint rule pass (unsafe assignment/member access, etc.)
  - No production-vs-test filtering in baseline counts
  - No runtime trace validation

## 7. Improvement Plan (25% Core Reduction)

- Goal: Reduce core type-safety violations by at least 25% without behavior changes
- Core scope: `any` + `as` + `!` + `@ts-ignore/@ts-expect-error`
- Baseline: `1283`
- Target reduction: `321`
- Target total: `<= 962`

### Phase 1: API hotspot hardening (target: -120)

- Primary files:
  - `api/src/routes/weeks.ts`
  - `api/src/routes/issues.ts`
- Work:
  - Replace `req.query` casts with typed parse helpers + runtime validation
  - Replace `req.workspaceId!` / `req.userId!` with explicit guards and typed narrowing
  - Replace `row: any` with row interfaces that match selected SQL columns
- Done when:
  - At least 120 core violations removed in target files
  - Existing API behavior preserved by tests

### Phase 2: Web core flow typing (target: -110)

- Primary files:
  - `web/src/components/IssuesList.tsx`
  - `web/src/pages/App.tsx`
  - `web/src/pages/ReviewsPage.tsx`
- Work:
  - Replace event/value assertions with precise React and domain types
  - Replace non-null assertions with guard-based control flow
  - Add local interfaces where handler shapes leak
- Done when:
  - At least 110 core violations removed in target files
  - Existing UI tests pass and key list/review flows are unchanged

### Phase 3: Test and mock typing cleanup (target: -70)

- Primary files:
  - `api/src/services/accountability.test.ts`
  - `api/src/__tests__/transformIssueLinks.test.ts`
- Work:
  - Replace `as any` mocks with typed builders and narrowed partials
  - Keep test logic and assertions unchanged
- Done when:
  - At least 70 core violations removed in target tests
  - Test behavior stays the same

### Phase 4: Regression guardrails (target: -21+ and lock-in)

- Work:
  - Add CI check to block increases in core violation counts
  - Add policy checks for new `any`, non-null assertions, and suppressions (exceptions must be explicit)
- Done when:
  - Total reduction reaches at least `-321`
  - New PRs cannot increase counts without documented exceptions

### Quality gates for every phase

- `pnpm type-check` passes
- `pnpm test` passes
- No superficial type fixes:
  - No `any -> unknown` swaps without proper narrowing
  - No new assertions without runtime safety checks
  - Types must match real API/DB/UI shapes
