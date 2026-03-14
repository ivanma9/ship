# Tasks: Test Reliability and Critical-Flow Coverage

**Input**: Design documents from `/specs/003-improve-test-reliability/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/test-reliability.md, quickstart.md

**Tests**: This feature explicitly requires unit, integration, and E2E verification updates. Test tasks are included in each user story phase.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g. US1, US2, US3)
- Every task includes an exact file path

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the working baseline inputs and task-specific reporting surfaces.

- [X] T001 Capture the current web failure inventory and root-cause worksheet in `audits/consolidated-audit-report-2026-03-10.md`
- [X] T002 Capture the scoped high-risk E2E wait-replacement target list in `specs/003-improve-test-reliability/research.md`
- [X] T003 [P] Review and align the feature execution notes in `specs/003-improve-test-reliability/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared blocking work that must be in place before any story implementation can be completed safely.

**⚠️ CRITICAL**: No user story is complete until this phase is done.

- [x] T004 Stabilize shared web test cleanup, mock reset, and environment defaults in `web/src/test/setup.ts`
- [X] T005 [P] Add reusable high-risk wait helpers and convergence utilities in `e2e/fixtures/test-helpers.ts`
- [X] T006 [P] Extend deterministic collaboration, offline, and RBAC seed data in `e2e/fixtures/isolated-env.ts`
- [X] T007 Define targeted E2E progress/baseline summary fields for flaky tracking in `e2e/progress-reporter.ts`

**Checkpoint**: Shared test setup, helper primitives, seed fixtures, and reporting primitives are ready.

---

## Phase 3: User Story 1 - Restore Trust in Existing Test Results (Priority: P1) 🎯 MVP

**Goal**: Remove the 13 deterministic web unit failures and document their root causes so the web suite becomes a trustworthy gate again.

**Independent Test**: Run the web coverage command twice and confirm the previously failing tests pass consistently with preserved behavior coverage.

### Tests for User Story 1

- [X] T008 [P] [US1] Reproduce and document the failing behavior groups for the web unit suite in `audits/consolidated-audit-report-2026-03-10.md`
- [x] T009 [P] [US1] Add regression-safe setup coverage for shared cleanup behavior in `web/src/test/setup.ts`

### Implementation for User Story 1

- [X] T010 [P] [US1] Repair deterministic editor-extension assertions in `web/src/components/editor/DetailsExtension.test.ts`
- [x] T011 [P] [US1] Repair deterministic drag-handle behavior coverage in `web/src/components/editor/DragHandle.test.ts`
- [x] T012 [P] [US1] Repair deterministic attachment and upload tests in `web/src/components/editor/FileAttachment.test.ts`
- [x] T013 [P] [US1] Repair deterministic image upload timing and cleanup in `web/src/components/editor/ImageUpload.test.ts`
- [x] T014 [P] [US1] Repair deterministic mention and table-of-contents tests in `web/src/components/editor/MentionExtension.test.ts`
- [x] T015 [P] [US1] Repair deterministic TOC rendering assertions in `web/src/components/editor/TableOfContents.test.ts`
- [x] T016 [P] [US1] Repair deterministic context and hook tests in `web/src/contexts/SelectionPersistenceContext.test.tsx`
- [x] T017 [P] [US1] Repair deterministic autosave and selection hook tests in `web/src/hooks/useAutoSave.test.ts`
- [x] T018 [P] [US1] Repair deterministic selection hook state transitions in `web/src/hooks/useSelection.test.ts`
- [X] T019 [P] [US1] Repair deterministic session-timeout behavior tests in `web/src/hooks/useSessionTimeout.test.ts`
- [x] T020 [P] [US1] Repair deterministic lib and page tests in `web/src/lib/accountability.test.ts`
- [x] T021 [P] [US1] Repair deterministic API and document-tab tests in `web/src/lib/api.test.ts`
- [X] T022 [P] [US1] Repair deterministic document-tab coverage in `web/src/lib/document-tabs.test.ts`
- [x] T023 [P] [US1] Repair deterministic HTTP error and dashboard tests in `web/src/lib/http-error.test.ts`
- [x] T024 [P] [US1] Repair deterministic dashboard rendering coverage in `web/src/pages/Dashboard.test.tsx`
- [x] T025 [P] [US1] Repair deterministic style-level drag-handle coverage in `web/src/styles/drag-handle.test.ts`
- [X] T026 [US1] Publish grouped root causes and fix notes for the 13 deterministic failures in `audits/consolidated-audit-report-2026-03-10.md`

**Checkpoint**: User Story 1 is complete when the web coverage command passes twice without manual retries and the root-cause notes are published.

---

## Phase 4: User Story 2 - Verify High-Risk Collaboration Flows Reliably (Priority: P2)

**Goal**: Replace high-risk fixed waits and add the three missing critical-flow E2E scenarios using deterministic fixtures and observable-state assertions.

**Independent Test**: Run the approved E2E runner against the targeted high-risk subset twice and confirm the updated scoped specs and three new scenarios pass without sleep-based synchronization.

### Tests for User Story 2

- [x] T027 [P] [US2] Add helper-level regression coverage for new wait and convergence utilities in `e2e/fixtures/test-helpers.ts`
- [x] T028 [P] [US2] Add deterministic fixture assertions for seeded collaborators, roles, and documents in `e2e/fixtures/isolated-env.ts`

### Implementation for User Story 2

- [X] T029 [P] [US2] Replace sleep-based autosave race waits with observable assertions in `e2e/autosave-race-conditions.spec.ts`
- [X] T030 [P] [US2] Replace sleep-based data-integrity waits with observable assertions in `e2e/data-integrity.spec.ts`
- [X] T031 [P] [US2] Replace sleep-based collaboration race waits with observable assertions in `e2e/race-conditions.spec.ts`
- [X] T032 [P] [US2] Replace sleep-based runtime autosave waits with observable assertions in `e2e/runtime-resilience-autosave.spec.ts`
- [X] T033 [P] [US2] Replace sleep-based reconnect waits with observable assertions in `e2e/runtime-resilience-reconnect.spec.ts`
- [X] T034 [P] [US2] Replace sleep-based authorization timing waits with observable assertions in `e2e/security.spec.ts`
- [X] T035 [US2] Implement the concurrent overlap convergence scenario with persisted reload verification in `e2e/collaboration-convergence.spec.ts`
- [X] T036 [US2] Implement the offline replay exactly-once scenario with persisted reload verification in `e2e/offline-replay-exactly-once.spec.ts`
- [X] T037 [US2] Implement the RBAC revocation during active collaboration scenario in `e2e/rbac-revocation-collaboration.spec.ts`
- [X] T038 [US2] Record the final high-risk wait-replacement coverage decisions in `specs/003-improve-test-reliability/research.md`

**Checkpoint**: User Story 2 is complete when the high-risk targeted E2E subset and the three new scenarios pass twice through the approved runner workflow.

---

## Phase 5: User Story 3 - Publish Updated Quality Baselines (Priority: P3)

**Goal**: Refresh pass/fail/flaky and coverage baselines so release stakeholders can review current evidence rather than stale numbers.

**Independent Test**: Re-run the targeted web and E2E baselines, update the audit artifact, and confirm the published summary shows current values plus deltas from the prior baseline.

### Tests for User Story 3

- [x] T039 [P] [US3] Validate that targeted E2E summary output exposes pass, fail, pending, and flaky-friendly counters in `scripts/watch-tests.sh`
- [x] T040 [P] [US3] Validate the baseline publication sections and delta fields in `audits/consolidated-audit-report-2026-03-10.md`

### Implementation for User Story 3

- [X] T041 [US3] Update targeted E2E watch and summary handling for baseline publication in `scripts/watch-tests.sh`
- [x] T042 [P] [US3] Adjust targeted E2E retry and reporting settings for the scoped gate in `playwright.config.ts`
- [x] T043 [P] [US3] Update pre-commit quality gate notes for the repaired command set in `.husky/pre-commit`
- [X] T044 [US3] Publish the refreshed pass/fail/flaky and coverage deltas in `audits/consolidated-audit-report-2026-03-10.md`

**Checkpoint**: User Story 3 is complete when the updated audit artifact publishes current baseline values and deltas for the repaired test surfaces.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and closeout across all stories.

- [X] T045 [P] Run and record the final task-phase verification notes in `specs/003-improve-test-reliability/quickstart.md`
- [X] T046 Reconcile final task completion, story checkpoints, and execution notes in `specs/003-improve-test-reliability/tasks.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup**: Starts immediately.
- **Phase 2: Foundational**: Depends on Phase 1 and blocks story completion.
- **Phase 3: US1**: Depends on Phase 2.
- **Phase 4: US2**: Depends on Phase 2. It can proceed in parallel with US1 once the shared foundation is done, but baseline publication still depends on US1 outcomes.
- **Phase 5: US3**: Depends on US1 and US2 because it publishes the final evidence.
- **Phase 6: Polish**: Depends on all selected stories being complete.

### User Story Dependencies

- **US1 (P1)**: No dependency on other stories after foundational work.
- **US2 (P2)**: No dependency on US1 for implementation, but both stories must finish before final baseline publication.
- **US3 (P3)**: Depends on completed outputs from US1 and US2.

### Within Each User Story

- Reproduction or validation tasks come before file-by-file fixes.
- Shared helper or fixture tasks come before scenario implementation.
- Publication tasks come after rerun evidence exists.

## Parallel Opportunities

### User Story 1

```bash
Task: "Repair deterministic editor-extension assertions in web/src/components/editor/DetailsExtension.test.ts"
Task: "Repair deterministic drag-handle behavior coverage in web/src/components/editor/DragHandle.test.ts"
Task: "Repair deterministic attachment and upload tests in web/src/components/editor/FileAttachment.test.ts"
Task: "Repair deterministic image upload timing and cleanup in web/src/components/editor/ImageUpload.test.ts"
Task: "Repair deterministic mention and table-of-contents tests in web/src/components/editor/MentionExtension.test.ts"
Task: "Repair deterministic TOC rendering assertions in web/src/components/editor/TableOfContents.test.ts"
```

### User Story 2

```bash
Task: "Replace sleep-based autosave race waits with observable assertions in e2e/autosave-race-conditions.spec.ts"
Task: "Replace sleep-based data-integrity waits with observable assertions in e2e/data-integrity.spec.ts"
Task: "Replace sleep-based collaboration race waits with observable assertions in e2e/race-conditions.spec.ts"
Task: "Replace sleep-based runtime autosave waits with observable assertions in e2e/runtime-resilience-autosave.spec.ts"
Task: "Replace sleep-based reconnect waits with observable assertions in e2e/runtime-resilience-reconnect.spec.ts"
Task: "Replace sleep-based authorization timing waits with observable assertions in e2e/security.spec.ts"
```

### User Story 3

```bash
Task: "Adjust targeted E2E retry and reporting settings for the scoped gate in playwright.config.ts"
Task: "Update pre-commit quality gate notes for the repaired command set in .husky/pre-commit"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Setup and Foundational work.
2. Finish User Story 1 and rerun the web coverage baseline twice.
3. Stop and validate that the web suite is trustworthy again.

### Incremental Delivery

1. Finish US1 to restore the primary gate.
2. Finish US2 to close the highest-risk collaboration gaps.
3. Finish US3 to publish the updated evidence and tighten gates.

### Parallel Team Strategy

1. One engineer stabilizes shared setup and helper primitives.
2. One engineer tackles the web deterministic failures in parallel groups.
3. One engineer handles the E2E helper replacement and new critical-flow specs.
4. Baseline publication and gating updates land after the repaired suites are green.

## Notes

- [P] tasks touch different files and can run in parallel after dependencies are met.
- Each user story phase is independently testable using the criteria listed in the phase header.
- E2E execution must use the project-approved runner workflow rather than `pnpm test:e2e`.
