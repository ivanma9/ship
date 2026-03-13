# Tasks: Accessibility Completion and Regression Gates

**Input**: Design documents from `/specs/007-a11y-completion-gates/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. No test-first tasks are generated (not requested in spec).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Capture before-state evidence and confirm local dev environment is ready. All implementation work depends on this baseline.

- [x] T001 Run `node audits/artifacts/accessibility/run-a11y-audit.mjs` locally against the running app and save the output as the before-state baseline to `audits/artifacts/accessibility/results/007-before/` — this evidence is required by FR-001 and SC-001
- [x] T002 Confirm `@axe-core/playwright` is listed in `e2e/package.json` (or root `package.json`); if missing, add it as a dev dependency — required for CI gate (T024–T028)
- [x] T003 Create `docs/a11y-manual-validation.md` using the protocol and evidence table defined in `specs/007-a11y-completion-gates/plan.md` Phase E — this doc is the durable evidence artifact required by FR-004 and SC-005; MUST be complete before T011 and T017 can record results

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No user story work depends on shared foundational infrastructure for this feature — all four user stories are independent UI/CI changes. This phase is therefore empty; proceed directly to user story phases.

**Checkpoint**: Setup complete → begin user story phases (all four can proceed in parallel).

---

## Phase 3: User Story 1 — Keyboard-Only Table Navigation on /issues (Priority: P1) 🎯 MVP

**Goal**: Every initially loaded row and cell in the /issues table is reachable and operable using keyboard alone.

**Independent Test**: Navigate to `/issues` using only Tab and arrow keys; confirm every row and cell is reachable, every interactive element fires on Enter/Space, Tab exits the grid.

### Implementation

- [x] T004 [US1] Audit current `web/src/components/SelectableList.tsx` keyboard handler: read the file, identify which arrow-key directions are handled, which are missing, and note any gaps in focus management
- [x] T005 [US1] In `web/src/components/SelectableList.tsx`, ensure the grid container has `role="grid"`, `aria-rowcount`, and `aria-colcount` attributes populated from actual row/column counts
- [x] T006 [US1] In `web/src/components/SelectableList.tsx`, ensure each header row element has `role="row"` and `aria-rowindex="1"`; ensure each header cell has `role="columnheader"`
- [x] T007 [US1] In `web/src/components/SelectableList.tsx`, ensure each data row has `role="row"` and `aria-rowindex` set to its 1-based position (starting at 2 after header)
- [x] T008 [US1] In `web/src/components/SelectableList.tsx`, ensure each data cell has `role="gridcell"` and `aria-colindex` set to its 1-based column position
- [x] T009 [US1] In `web/src/components/SelectableList.tsx`, complete the arrow-key handler: ArrowDown/ArrowUp move row focus, ArrowRight/ArrowLeft move cell focus within the active row; confirm Tab exits the grid to the next focusable page element
- [x] T010 [US1] In `web/src/components/SelectableList.tsx`, confirm Enter activates the primary action of the focused row/cell and Space toggles selection; add handlers if missing
- [x] T011 [US1] Manually verify keyboard traversal on `/issues` in the browser: Tab into grid → ArrowDown through rows → ArrowRight through cells → Enter to open → Tab to exit; log results in `docs/a11y-manual-validation.md` under the `/issues` keyboard rows
- [x] T012 [US1] Add a Playwright keyboard traversal test to `e2e/accessibility.spec.ts`: navigate to `/issues`, Tab into grid, assert `ArrowDown` moves focus to next row (`[role="row"]:focus-within`), assert `Enter` opens the issue detail, assert `Tab` moves focus outside the grid

**Checkpoint**: A keyboard-only user can navigate the entire /issues table without a mouse. US1 independently testable.

---

## Phase 4: User Story 2 — Screen-Reader Row/Cell Announcements on /issues (Priority: P2)

**Goal**: VoiceOver (and compatible screen readers) announce column header plus cell value for every grid cell; row-level actions have meaningful accessible labels; empty state is announced.

**Independent Test**: Run axe scan on `/issues` — zero `aria-required-attr`, `aria-label`, or `aria-labelledby` violations; VoiceOver walkthrough produces complete cell announcements.

### Implementation

- [x] T013 [US2] In `web/src/components/SelectableList.tsx`, add `aria-label="<columnHeader>: <cellValue>"` to each `role="gridcell"` element, constructing the label from the column definition's header name and the rendered cell value
- [x] T014 [US2] In `web/src/components/IssuesList.tsx`, audit all row-level action buttons and links; ensure each has a unique descriptive `aria-label` (e.g., `"Open issue: <title>"`) rather than a generic label
- [x] T015 [US2] In `web/src/components/IssuesList.tsx`, ensure the empty-state region has `role="status"` or an `aria-live="polite"` region so screen readers announce the empty message when no issues are present
- [x] T016 [US2] Run the axe scan on `/issues` locally (`pnpm --filter e2e exec playwright test e2e/accessibility.spec.ts --grep issues`) and confirm zero critical/serious violations including `aria-required-attr` and labeling rules
- [x] T017 [US2] Perform VoiceOver manual validation on `/issues`: enable VoiceOver, navigate table with VO+Right Arrow, confirm each cell announces `"<Column>: <Value>"`, confirm row actions announce their purpose; fill in the `/issues` SR rows in `docs/a11y-manual-validation.md`

**Checkpoint**: Screen-reader users receive complete, meaningful table announcements on /issues. US2 independently testable.

---

## Phase 5: User Story 3 — Contrast Compliance on /projects, /programs, /team/allocation (Priority: P2)

**Goal**: Zero serious contrast violations on all three routes; brand appearance preserved.

**Independent Test**: Run axe contrast scan on each route — zero serious `color-contrast` violations; visual review confirms colors look correct.

### Implementation

- [x] T018 [P] [US3] For `/projects` (`web/src/pages/Projects.tsx`): identify each failing element from the T001 before-state audit; swap the failing Tailwind color class or CSS token to a passing alternative that meets 4.5:1 (normal text) or 3:1 (large text/UI) ratio
- [x] T019 [P] [US3] For `/programs` (`web/src/pages/Programs.tsx`): same process — identify failing element(s) from before-state audit; swap to passing color token
- [x] T020 [P] [US3] For `/team/allocation` (`web/src/pages/TeamMode.tsx`): same process — identify failing element(s); swap to passing color token
- [x] T021 [US3] Re-run `node audits/artifacts/accessibility/run-a11y-audit.mjs` and save after-state output to `audits/artifacts/accessibility/results/007-after/`; confirm zero serious `color-contrast` violations on all three routes
- [x] T022 [P] [US3] Do a visual review of `/projects`, `/programs`, and `/team/allocation` in the browser — confirm brand colors and layout look correct; note any concerns in the PR description
- [x] T023 [P] [US3] Extend `e2e/accessibility.spec.ts` to add per-page axe tests for `/projects`, `/programs`, and `/team/allocation` if not already present; each test asserts zero critical/serious violations using the existing pattern

**Checkpoint**: All three routes have zero serious contrast violations. US3 independently testable.

---

## Phase 6: User Story 4 — CI Accessibility Gate Prevents Regressions (Priority: P3)

**Goal**: `accessibility-gates` job in CI runs on every PR, fails on any serious violation across core routes, uploads artifact.

**Independent Test**: Introduce a known contrast violation in a scratch change → confirm CI job fails and reports the violation; revert → confirm job passes.

### Implementation

- [x] T024 [US4] Add the `accessibility-gates` job to `.github/workflows/ci.yml` per the contract in `specs/007-a11y-completion-gates/contracts/ci-gate.md`: checkout, install deps, build shared, install Playwright Chromium, start app with seed data, run `e2e/accessibility.spec.ts`, upload `test-results/` artifact as `a11y-gate-results`
- [x] T025 [US4] In `.github/workflows/ci.yml`, add a `postgres` service block to the `accessibility-gates` job matching the existing `build-and-check` job's postgres config (image, env, ports, health options) — required for `pnpm db:seed` to run in CI
- [x] T026 [US4] Verify `e2e/accessibility.spec.ts` has tests covering all required routes: `/login`, `/dashboard`, `/issues`, `/projects`, `/programs`, `/team/allocation`; add any missing per-page tests using the existing AxeBuilder pattern
- [x] T027 [US4] Validate the gate locally: temporarily add a low-contrast color to `web/src/pages/Projects.tsx`, run `pnpm --filter e2e exec playwright test e2e/accessibility.spec.ts` locally, confirm the projects test fails with a contrast violation; revert the change and confirm tests pass
- [x] T028 [US4] Record the gate validation evidence (failing run output showing violation, passing run output) in the PR description or as a comment in `docs/a11y-manual-validation.md` — required by SC-004

**Checkpoint**: CI gate is live, zero-tolerance enforced, regression test documented. US4 independently testable.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Evidence consolidation, manual validation completion, and spec/plan alignment.

- [x] T029 [P] Complete all remaining rows in `docs/a11y-manual-validation.md`: fill tester name, date, SR version, and PASS/FAIL for every route × criterion in the test matrix (FR-004, SC-005)
- [x] T030 [P] Run `pnpm type-check` and confirm zero new TypeScript errors introduced by any changes in this feature
- [x] T031 [P] Run the full existing test suite (`pnpm test`) and confirm all unit tests still pass (SC-006 — no regressions in functional behavior)
- [x] T032 Run `pnpm --filter e2e exec playwright test e2e/accessibility.spec.ts` one final time against the fully patched app; confirm all per-page tests pass; save the final run output as the definitive after-state evidence
- [x] T033 [P] Update the checklist at `specs/007-a11y-completion-gates/checklists/requirements.md` — mark all Definition of Done items from `plan.md` as complete with evidence references

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Empty — no blocking prerequisites
- **Phases 3–6 (User Stories)**: All depend on Phase 1 completion; can proceed in parallel after T001–T003
- **Phase 7 (Polish)**: Depends on all user story phases complete

### User Story Dependencies

- **US1 (P1)**: No dependency on other stories — start after Phase 1
- **US2 (P2)**: No dependency on other stories — start after Phase 1; shares `SelectableList.tsx` with US1 (coordinate edits or sequence after US1)
- **US3 (P2)**: No dependency on other stories — fully independent (different files)
- **US4 (P3)**: Depends on US1–US3 being complete so the gate starts at zero violations

### File Conflict Note

US1 and US2 both modify `web/src/components/SelectableList.tsx`. Sequence them (complete US1 first, then US2) or coordinate carefully if working in parallel.

### Parallel Opportunities

- T018, T019, T020 (contrast fixes) — different files, fully parallel
- T022, T023 (visual review + E2E extension) — parallel with each other
- T029, T030, T031, T033 — all parallel in Phase 7

---

## Parallel Execution Example: US3 (Contrast Fixes)

```bash
# All three contrast fix tasks can run simultaneously (different files):
Task: T018 — fix Projects.tsx contrast
Task: T019 — fix Programs.tsx contrast
Task: T020 — fix TeamMode.tsx contrast
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 3: US1 keyboard traversal (T004–T012)
3. **STOP and VALIDATE**: keyboard-only navigation on /issues fully works
4. Merge US1 if needed; continue with US2–US4

### Incremental Delivery

1. Setup → US1 (keyboard) → validate → merge
2. US2 (screen-reader) → validate → merge
3. US3 (contrast fixes, parallel) → validate → merge
4. US4 (CI gate) → validate + regression test → merge
5. Phase 7 polish → final evidence consolidation → mark done

### Parallel Team Strategy

With two developers after Phase 1:
- Developer A: US1 → US2 (sequential, share SelectableList.tsx)
- Developer B: US3 (parallel, independent files) → US4 (after A finishes)

---

## Notes

- [P] tasks = different files, no shared state dependencies
- [Story] label maps task to specific user story for traceability
- T001 before-state evidence is mandatory — do not skip
- Commit at each checkpoint (after each US phase completes)
- US4 CI gate MUST be activated only after US1–US3 are merged (zero-tolerance gate requires zero violations to exist first)
