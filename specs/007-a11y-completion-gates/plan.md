# Implementation Plan: Accessibility Completion and Regression Gates

**Branch**: `007-a11y-completion-gates` | **Date**: 2026-03-13 | **Spec**: [spec.md](./spec.md)

## Summary

Resolve the remaining three serious contrast violations (one each on /projects, /programs, /team/allocation), complete keyboard traversal and screen-reader semantics for the /issues table, document and execute a manual screen-reader validation protocol across all four scoped routes, and add an axe-core CI job to `ci.yml` that fails on new serious violations. No new dependencies or architectural changes are required — the existing `@axe-core/playwright` package and Playwright infrastructure already used in `e2e/accessibility.spec.ts` and `audits/artifacts/accessibility/run-a11y-audit.mjs` are sufficient.

---

## Technical Context

**Language/Version**: TypeScript 5.x strict, Node 20
**Primary Dependencies**: React 18, Vite 5, Playwright + `@axe-core/playwright` (already in use), GitHub Actions
**Storage**: N/A (frontend-only changes; no schema changes)
**Testing**: Vitest (unit), Playwright E2E, axe-core automated a11y
**Target Platform**: Web (Chromium/Safari/Firefox); screen readers: VoiceOver (macOS), NVDA (Windows)
**Project Type**: Web application (monorepo: api / web / shared)
**Performance Goals**: No regression on existing Lighthouse scores (95–100 baseline)
**Constraints**: WCAG 2.1 AA compliance for all changed areas; existing UX flows preserved
**Scale/Scope**: 4 scoped routes; changes concentrated in `web/src/`

---

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Type Safety | PASS | No new types needed; any ARIA prop additions are typed by React's built-in HTML attribute types |
| II. Bundle Size | PASS | No new dependencies; `@axe-core/playwright` is dev/CI-only, never shipped in browser bundle |
| III. API Response Time | N/A | No API changes |
| IV. Database Query Efficiency | N/A | No database changes |
| V. Test Coverage | PASS | New/extended axe tests in `e2e/accessibility.spec.ts`; CI gate validates coverage |
| VI. Runtime Errors | PASS | ARIA attribute changes are additive; no new failure paths |
| VII. Accessibility Compliance | **PRIMARY SURFACE** — this feature exists to satisfy this principle |

All gates pass. No violations to justify.

---

## Project Structure

### Documentation (this feature)

```text
specs/007-a11y-completion-gates/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output (minimal — no new data entities)
├── quickstart.md        ← Phase 1 output
├── checklists/
│   └── requirements.md
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code (files touched by this feature)

```text
web/src/
├── components/
│   ├── SelectableList.tsx          ← keyboard traversal + ARIA row/cell semantics
│   └── IssuesList.tsx              ← screen-reader announcements for rows/cells
├── pages/
│   ├── Projects.tsx                ← contrast token fix
│   ├── Programs.tsx                ← contrast token fix
│   └── TeamMode.tsx                ← contrast token fix (/team/allocation)

e2e/
└── accessibility.spec.ts           ← extend per-page tests; add keyboard + SR assertions

.github/workflows/
└── ci.yml                          ← add accessibility-gates job

audits/artifacts/accessibility/
├── run-a11y-audit.mjs              ← (read-only reference; no changes needed)
└── results/                        ← before/after evidence stored here

docs/
└── a11y-manual-validation.md       ← new: manual SR validation protocol + evidence template
```

---

## Phase 0: Research

*All unknowns are resolved below. No NEEDS CLARIFICATION markers remain.*

See [research.md](./research.md) for full details.

### Decision Log

| Topic | Decision | Rationale |
|-------|----------|-----------|
| Axe tool for CI | `@axe-core/playwright` already in repo (`e2e/accessibility.spec.ts`); extend existing tests into a dedicated CI job | No new dependency; proven pattern in codebase |
| CI authentication | Use existing `isolated-env` fixture with dev seed credentials (`dev@ship.local` / `admin123`) already used in E2E suite | Same mechanism already works for authenticated E2E runs |
| Table keyboard pattern | `role="grid"` with `aria-rowindex`, `aria-colindex`, `aria-rowcount`, `aria-colcount` on the existing `SelectableList` wrapper; arrow-key handler already partially implemented | ARIA grid pattern is the correct semantic for interactive data grids; avoids full rewrite |
| Screen-reader cell announcement | Add `role="gridcell"` + `aria-label` or `headers` association to each cell renderer inside `SelectableList`; add `role="columnheader"` to header cells | Standard ARIA grid pattern; compatible with existing component structure |
| Contrast fixes | Use existing Tailwind CSS utility classes / CSS custom property tokens already defined; swap failing color tokens to passing alternatives (no design-system overhaul) | Surgical token swaps preserve brand; avoid large visual regression |
| Manual SR protocol | VoiceOver on macOS (primary, testable in dev environment); NVDA on Windows (secondary, documented but optional for this sprint) | VoiceOver available on developer machines; NVDA requires Windows VM |
| CI job placement | New `accessibility-gates` job in `ci.yml`, parallel to `build-and-check`, depends on shared build artifact | Keeps CI fast; gates PRs without serializing the full pipeline |

---

## Phase 1: Design & Contracts

### Data Model

No new database entities or persisted data. The only "data" artifacts are:

- **Axe violation report** (ephemeral CI artifact): JSON produced by `@axe-core/playwright` per page run; uploaded as GitHub Actions artifact.
- **Manual validation record** (durable doc): `docs/a11y-manual-validation.md` — structured evidence table recording pass/fail per route per criterion.

See [data-model.md](./data-model.md) for the evidence schema.

### Interface Contracts

This feature has no new API endpoints or public interfaces. The relevant "contracts" are:

1. **ARIA grid contract on `SelectableList`** — documented in `quickstart.md`: the component exposes `role="grid"` with fully attributed `role="row"`, `role="columnheader"`, `role="gridcell"` children; arrow-key traversal is handled internally.

2. **CI gate contract** — the `accessibility-gates` job in `ci.yml` MUST exit non-zero when `axe-core` finds any violation with `impact === "critical" || impact === "serious"` on covered routes; it MUST exit zero otherwise.

See [contracts/](./contracts/) for both contracts in full.

---

## Implementation Phases

### Phase A — Contrast Fixes (lowest risk, highest visibility)

**Goal**: Zero serious contrast violations on /projects, /programs, /team/allocation.

**Files**:
- `web/src/pages/Projects.tsx`
- `web/src/pages/Programs.tsx`
- `web/src/pages/TeamMode.tsx`

**Approach**:
1. Run `audits/artifacts/accessibility/run-a11y-audit.mjs` locally on the three routes; capture before-state violation list.
2. For each failing element, identify the CSS color token or Tailwind class responsible.
3. Swap to a passing color that satisfies 4.5:1 (normal text) or 3:1 (large text / UI components).
4. Re-run audit; confirm zero serious violations; capture after-state as evidence.

**Test**:
- `e2e/accessibility.spec.ts` existing per-page tests for programs, projects; add one for team/allocation.
- Each test: AxeBuilder scan filtered to `impact === "critical" || "serious"` → `toHaveLength(0)`.

**Evidence required**: before/after axe JSON reports saved to `audits/artifacts/accessibility/results/`.

---

### Phase B — Keyboard Traversal for `/issues` Table

**Goal**: Full keyboard operability across all rows and cells in the issues list.

**Files**:
- `web/src/components/SelectableList.tsx`
- `web/src/components/IssuesList.tsx`

**Approach**:
1. Audit current `SelectableList` keyboard handler (arrow keys, Tab, Enter, Space).
2. Ensure `role="grid"` is on the container, `role="row"` on each row, `role="gridcell"` on each cell, `role="columnheader"` on header cells.
3. Add `aria-rowcount`, `aria-colcount`, `aria-rowindex`, `aria-colindex` attributes.
4. Verify arrow-key handler covers all four directions within the grid; Tab exits the grid to the next focusable element.
5. Ensure all interactive elements inside cells (links, buttons, dropdowns) are reachable via Tab from within the active cell, then resume arrow-key navigation after exiting the cell.

**Test**:
- New E2E test in `e2e/accessibility.spec.ts`:
  ```
  keyboard traversal: navigate to /issues, Tab into grid,
  assert ArrowDown/ArrowRight move focus, Enter activates row action,
  Tab exits grid to next focusable element.
  ```
- Use Playwright `page.keyboard.press()` sequence; assert `page.locator('[role="gridcell"]:focus')` as focus moves.

**Evidence required**: Screen recording or step-by-step keyboard test log in manual validation doc.

---

### Phase C — Screen-Reader Announcements for `/issues` Table

**Goal**: VoiceOver announces column header + cell value for every grid cell; row actions have meaningful labels.

**Files**:
- `web/src/components/SelectableList.tsx` (cell ARIA attributes)
- `web/src/components/IssuesList.tsx` (row action button labels)

**Approach**:
1. Add `aria-label` or `headers` association to each `role="gridcell"` so screen readers announce `"[Column Header]: [Cell Value]"`.
2. Audit all row-level action buttons/links; ensure each has a unique, descriptive `aria-label` (e.g., `"Open issue: Fix login bug"` not just `"Open"`).
3. Verify empty-state region has `role="status"` or an `aria-live` region that announces the empty message.

**Test**:
- Extend `e2e/accessibility.spec.ts` with axe scan of `/issues` asserting zero `aria-required-attr`, `aria-label`, and `aria-labelledby` violations.
- Manual VoiceOver walkthrough documented in `docs/a11y-manual-validation.md`.

**Evidence required**: VoiceOver session notes or recording; axe report diff.

---

### Phase D — CI Accessibility Gate

**Goal**: New serious violations on core routes block PR merges automatically.

**Files**:
- `.github/workflows/ci.yml` — new job `accessibility-gates`
- `e2e/accessibility.spec.ts` — ensure per-page tests are individually runnable as a named group

**Approach**:

New CI job outline (to be added to `ci.yml`):

```yaml
accessibility-gates:
  runs-on: ubuntu-latest
  needs: build-and-check          # reuse built web artifacts
  steps:
    - uses: actions/checkout@v4
    - uses: pnpm/action-setup@v4
    - uses: actions/setup-node@v4
      with:
        node-version: 20
        cache: pnpm
    - run: pnpm install --frozen-lockfile
    - run: pnpm build:shared
    - name: Install Playwright browsers
      run: pnpm --filter e2e exec playwright install --with-deps chromium
    - name: Start app (seeded)
      run: |
        pnpm db:migrate
        pnpm db:seed
        pnpm dev &
        npx wait-on http://localhost:3000/health http://localhost:5173
      env:
        DATABASE_URL: postgresql://postgres:postgres@localhost:5432/ship_test
    - name: Run accessibility gate tests
      run: pnpm --filter e2e exec playwright test e2e/accessibility.spec.ts
      env:
        BASE_URL: http://localhost:5173
    - uses: actions/upload-artifact@v4
      if: always()
      with:
        name: a11y-gate-results
        path: test-results/
```

**Gate semantics**: Each per-page test in `accessibility.spec.ts` already does `expect(criticalViolations).toHaveLength(0)`. Adding `/issues`, `/projects`, `/programs`, `/team/allocation` tests to the suite means the job fails if any serious violation is introduced.

**Test of the gate**: In a scratch branch, intentionally add a low-contrast color to Projects.tsx, run the CI job locally with `act` or push to a test branch; confirm job fails and reports the violation.

---

### Phase E — Manual Screen-Reader Validation Protocol

**Goal**: Documented, reproducible manual test session for all four scoped routes.

**New file**: `docs/a11y-manual-validation.md`

**Protocol structure**:

```markdown
# Manual Screen-Reader Validation Protocol

## Setup
- Browser: Safari (for VoiceOver) or Chrome (for NVDA)
- Seed: pnpm db:seed on local dev instance
- Login: dev@ship.local / admin123

## Test Matrix

| Route | Criterion | VoiceOver Result | Notes |
|-------|-----------|-----------------|-------|
| /issues | All cells announced with column header | PASS / FAIL | [date] |
| /issues | Row actions have meaningful labels | PASS / FAIL | |
| /issues | Empty state announced | PASS / FAIL | |
| /projects | Keyboard traversal complete | PASS / FAIL | |
| /projects | No serious contrast violations | PASS / FAIL | |
| /programs | Keyboard traversal complete | PASS / FAIL | |
| /programs | No serious contrast violations | PASS / FAIL | |
| /team/allocation | Keyboard traversal complete | PASS / FAIL | |
| /team/allocation | No serious contrast violations | PASS / FAIL | |

## Evidence Format
- Each FAIL row MUST include: element selector, violation description, screenshot or screen recording reference.
- Each PASS row MUST include: tester name, date, browser+SR version.
```

---

## Test Strategy

| Layer | What | Tool | Pass Criterion |
|-------|------|------|---------------|
| Automated (CI) | Axe scan per scoped route | `@axe-core/playwright` in `e2e/accessibility.spec.ts` | Zero critical/serious violations |
| Automated (CI) | Keyboard traversal basic flow | Playwright keyboard events | Focus moves correctly, actions fire |
| Manual | Full SR walkthrough per route | VoiceOver + Safari | All rows in test matrix marked PASS |
| Manual | Contrast visual review | Developer eyeball + axe before/after diff | Intended brand preserved, violations gone |
| Regression | Known-violation test branch | `act` or CI test branch | CI job fails on intentional violation |

---

## Rollout & Rollback

**Rollout**:
- Phases A–C are pure frontend CSS/ARIA changes; no feature flags needed.
- Phase D (CI gate) activates on merge; existing passing tests ensure gate doesn't block from day one.
- Phase E (manual protocol doc) is additive; no risk.

**Rollback**:
- Any phase can be reverted independently via `git revert` on the relevant commits.
- CI gate job can be disabled by removing the job from `ci.yml` in an emergency; this MUST be documented as a known exception with an expiration date per the constitution.

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Contrast token swap changes visual appearance beyond contrast | Medium | Low | Review each page visually before/after; get design sign-off if brand tokens are touched |
| `SelectableList` ARIA additions break existing keyboard behavior | Medium | Medium | Run full keyboard smoke test on /projects and /programs (also use SelectableList) before merging |
| CI auth (seed + login) flaky in GitHub Actions | Low | High | Use existing isolated-env fixture pattern already proven in E2E suite |
| VoiceOver behavior differs between macOS versions | Low | Low | Document macOS version used in validation record |
| CI job adds significant time | Low | Low | Job runs parallel to build-and-check; net wall-clock impact is small |

---

## Definition of Done

- [ ] Zero serious axe violations on /projects, /programs, /team/allocation (automated + before/after evidence)
- [ ] `/issues` table passes full keyboard traversal test (automated Playwright + manual log)
- [ ] `/issues` table cells announce column header + value in VoiceOver (manual validation doc entry marked PASS)
- [ ] Row actions on /issues have meaningful accessible labels (axe + manual)
- [ ] `accessibility-gates` job added to `ci.yml` and passing on master
- [ ] Gate verified to fail on an intentionally introduced violation (evidence in PR description)
- [ ] `docs/a11y-manual-validation.md` created with all test-matrix rows filled and dated
- [ ] `pnpm type-check` passes with zero new errors
- [ ] Existing E2E and unit tests continue to pass
- [ ] PR includes before/after axe violation counts per route
