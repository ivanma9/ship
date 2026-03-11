# 5-Minute Demo Script: Consolidated Audit Report (2026-03-10)

Source report: `audits/consolidated-audit-report-2026-03-10.md`
Audience: engineering + product
Goal: quickly communicate what was found and what to improve next, section by section.

## 0:00-0:20 | Opening

"This is a 5-minute walkthrough of the consolidated audit across seven areas. For each area, I’ll cover two things: what we found, and the improvement to make next."

## 0:20-3:50 | Audit Sections (Finding + Improvement Together)

### 1) Type Safety (0:20-0:50)

- **What we found:** Core type-risk baseline is high (1,283 across `any` + `as` + `!` + suppressions), concentrated in `web/`; `api/src/routes/weeks.ts` is the highest-risk API hotspot.
- **Improvement:** Execute the 25% core reduction plan, starting with `api/src/routes/weeks.ts`, `web/src/pages/App.tsx`, `web/src/components/IssuesList.tsx`, and `web/src/pages/ReviewsPage.tsx` using typed parsers, guards, and narrowed interfaces.

### 2) Bundle Size (0:50-1:15)

- **What we found:** Entry chunk is oversized (`~2.07 MB`) and dominates load share (`94.9%`); largest contributors include `emoji-picker-react`, `highlight.js`, and `yjs`.
- **Improvement:** Prioritize lazy loading and footprint reduction for those high-weight dependencies, fix static+dynamic import overlap, and remove confirmed unused dependencies.

### 3) API Response Time (1:15-1:40)

- **What we found:** At `c50`, `/api/documents?type=wiki` and `/api/issues` are the slowest list endpoints and primary optimization targets.
- **Improvement:** Apply payload-size and indexing optimizations, then re-run identical benchmarks targeting P95 reductions of 20% (`123ms -> <=98ms`, `105ms -> <=84ms`).

### 4) Database Query Efficiency (1:40-2:05)

- **What we found:** Two key inefficiencies were identified: N+1 in accountability flows and extra query round-trip in mention search; projected improvement shows search queries `5 -> 4` (20%) and query-family execution time improvement (~63%).
- **Improvement:** Implement the proposed set-based batching in accountability and consolidate mention search into a single query; validate before/after counts in the same audit report.

### 5) Test Coverage and Quality (2:05-2:35)

- **What we found:** Test volume is strong (`1,471` total), API baseline is deterministic, but web coverage confidence is limited by 13 deterministic web test failures; collaboration dark logic remains under-tested.
- **Improvement:** First stabilize web tests, then replace `waitForTimeout` in high-risk E2E paths, and add 3 missing scenarios: concurrent overlap convergence, offline replay exactly-once, and RBAC revocation during active collaboration.

### 6) Runtime Errors and Edge Cases (2:35-3:15)

- **What we found:** Most urgent trust issues are title divergence under concurrent edits (P0), reconnect redirect churn, and silent terminal autosave failures.
- **Improvement:** Add versioned compare-and-swap conflict handling for title writes, add reconnect grace/retry logic before forced redirect, and expose terminal autosave failure as persistent UI state.

### 7) Accessibility Compliance (3:15-3:50)

- **What we found:** Major progress achieved: three priority pages now have 0 Critical/Serious issues and Lighthouse 100, but three Serious contrast issues remain (`/projects`, `/programs`, `/team/allocation`) plus table screen-reader context gaps.
- **Improvement:** Resolve remaining contrast issues, complete table keyboard/screen-reader fixes, and add Lighthouse + axe regression gates in CI.

## 3:50-5:00 | Priority Close and Decision Ask

"Across all seven audits, the sequence should be: runtime trust fixes first, then web test stabilization, then targeted type-safety/performance/accessibility completion work."

"Decision request: approve this per-audit improvement plan for next sprint execution, with runtime and test reliability as the first gates."

---

## Optional Presenter Notes

- Why this structure: each section is immediately actionable because finding and fix are paired.
- Why runtime first: it affects data correctness and user trust directly.
- Why test stabilization early: it improves confidence in every subsequent change.
