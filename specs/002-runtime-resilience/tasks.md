# Tasks: Runtime Resilience for Concurrency, Reconnect, and Autosave

**Input**: Design documents from `/specs/002-runtime-resilience/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/runtime-resilience.md

**Tests**: Add the unit, integration, and E2E coverage explicitly required by the spec and plan.

**Organization**: Tasks are grouped by user story so each story can be implemented and tested independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on unfinished tasks)
- **[Story]**: User story label for story-specific phases only
- Every task includes exact file paths

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Align the implementation surface, test targets, and evidence files before code changes begin.

- [X] T001 Review and reconcile scope, contracts, and execution order in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/specs/002-runtime-resilience/plan.md`, `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/specs/002-runtime-resilience/spec.md`, and `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/specs/002-runtime-resilience/contracts/runtime-resilience.md`
- [X] T002 Create a runtime resilience implementation checklist and evidence scratchpad in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/specs/002-runtime-resilience/quickstart.md`
- [X] T003 [P] Inspect existing server conflict coverage in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents.test.ts` and existing client request error handling in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/http-error.ts`
- [X] T004 [P] Inspect existing client save/auth status surfaces in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.tsx`, `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/hooks/useAutoSave.ts`, and `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/api.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish shared contracts and instrumentation points required by all three stories.

**⚠️ CRITICAL**: No user story work should start until this phase is complete.

- [x] T005 Update shared error-code and API schema expectations in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/shared/src/constants.ts` and `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/openapi/schemas/documents.ts`
- [X] T006 [P] Extend typed request-error parsing for conflict metadata in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/http-error.ts`
- [X] T007 [P] Add reusable runtime resilience logging and measurement hooks in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents.ts` and `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/api.ts`
- [x] T008 Define shared test data expectations for runtime resilience scenarios in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/fixtures/isolated-env.ts`

**Checkpoint**: Shared contracts, parsing, logging, and fixture expectations are ready for story work.

---

## Phase 3: User Story 1 - Preserve Correct Titles During Concurrent Edits (Priority: P1) 🎯 MVP

**Goal**: Prevent silent title overwrite by enforcing compare-and-swap title writes and surfacing a safe client conflict flow.

**Independent Test**: Two sessions edit the same title; the stale writer receives `409 WRITE_CONFLICT`, the authoritative title remains intact, and the stale writer can refresh/retry without losing local text.

### Tests for User Story 1

- [X] T009 [P] [US1] Add API regression tests for fresh title CAS, stale title conflict, and idempotent retry in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents.test.ts`
- [x] T010 [P] [US1] Add client conflict parsing and retry-state tests in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/http-error.test.ts` and `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.conflict.test.tsx`
- [X] T011 [P] [US1] Add E2E coverage for concurrent title edits in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-title-conflict.spec.ts`

### Implementation for User Story 1

- [X] T012 [US1] Replace title-lock branching with `expected_updated_at` CAS and `attempted_title` conflict payload in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents.ts`
- [X] T013 [US1] Update the unified document title mutation to send and refresh authoritative `updated_at` tokens in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/UnifiedDocumentPage.tsx`
- [X] T014 [P] [US1] Update title autosave conflict state and safe retry UI in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.tsx`
- [X] T015 [P] [US1] Bring person-title autosave onto the same conflict contract in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/PersonEditor.tsx`
- [X] T016 [US1] Reconcile OpenAPI response documentation for `409 WRITE_CONFLICT` in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/openapi/schemas/documents.ts`

**Checkpoint**: Title updates are CAS-protected and conflict handling is visible and retryable without affecting normal title saves.

---

## Phase 4: User Story 2 - Avoid Premature Session-Expired Redirects During Reconnect (Priority: P2)

**Goal**: Prevent redirect storms during transient auth turbulence while preserving normal session-expiry behavior outside the grace window.

**Independent Test**: Simulate transient authenticated `401` failures; requests retry within the grace window without redirecting, and only one redirect occurs after unrecoverable exhaustion.

### Tests for User Story 2

- [X] T017 [P] [US2] Add retry-gate and duplicate-redirect suppression tests in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/api.test.ts`
- [X] T018 [P] [US2] Add E2E reconnect turbulence coverage in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-reconnect.spec.ts`

### Implementation for User Story 2

- [X] T019 [US2] Refactor reconnect turbulence state, bounded retry gating, and deferred redirect circuit breaking in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/api.ts`
- [x] T020 [P] [US2] Coordinate editor-visible save/session status with reconnect turbulence outcomes in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/Editor.tsx`
- [x] T021 [US2] Preserve existing non-turbulence auth-expiry redirect behavior and return-to semantics in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/App.tsx`

**Checkpoint**: Temporary reconnect/auth churn no longer causes redirect storms, while real expiry still redirects correctly.

---

## Phase 5: User Story 3 - Surface Terminal Autosave Failures (Priority: P3)

**Goal**: Expose terminal autosave failure with exponential backoff, sticky visible error state, and recovery only after a later successful save.

**Independent Test**: Force repeated save failures until retry exhaustion and verify the sticky error appears, remains visible, and clears only after a subsequent successful save.

### Tests for User Story 3

- [X] T022 [P] [US3] Add autosave backoff and terminal-failure hook tests in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/hooks/useAutoSave.test.ts`
- [x] T023 [P] [US3] Add sticky save-failure UI tests in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.autosave.test.tsx`
- [X] T024 [P] [US3] Add E2E autosave terminal-failure UX coverage in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-autosave.spec.ts`

### Implementation for User Story 3

- [X] T025 [US3] Implement exponential backoff, retry metadata, and terminal `onFailure` semantics in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/hooks/useAutoSave.ts`
- [X] T026 [P] [US3] Surface sticky autosave failure state and recovery clearing in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.tsx`
- [X] T027 [P] [US3] Apply terminal autosave failure visibility to person title editing in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/PersonEditor.tsx`

**Checkpoint**: Autosave retry exhaustion is visible, persistent, and only cleared by successful recovery.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finish observability, accessibility, and verification across all three stories.

- [x] T028 [P] Capture conflict-rate, reconnect-deferral, and autosave-failure observability evidence in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/specs/002-runtime-resilience/quickstart.md`
- [x] T029 [P] Run keyboard and screen-reader-focused accessibility verification for conflict and save-failure alerts in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.tsx` and `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/Editor.tsx`
- [X] T030 Run type-check and targeted API/web test suites, then record results in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/specs/002-runtime-resilience/quickstart.md`
- [x] T031 Run the required E2E runner for `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-title-conflict.spec.ts`, `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-reconnect.spec.ts`, and `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-autosave.spec.ts`, then record outcomes in `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/specs/002-runtime-resilience/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup**: No dependencies
- **Phase 2: Foundational**: Depends on Phase 1 and blocks all user stories
- **Phase 3: US1**: Depends on Phase 2; this is the MVP slice
- **Phase 4: US2**: Depends on Phase 2; can proceed after foundational work and in parallel with later US1 stabilization if staffed
- **Phase 5: US3**: Depends on Phase 2; can proceed after foundational work and in parallel with later US2 work if staffed
- **Phase 6: Polish**: Depends on the user stories that are included in the release scope

### User Story Dependencies

- **US1 (P1)**: No dependency on other user stories
- **US2 (P2)**: No dependency on US1, but should reuse the shared error/observability groundwork from Phase 2
- **US3 (P3)**: No dependency on US1 or US2, but should reuse the shared error/observability groundwork from Phase 2

### Within Each User Story

- Tests should be added before or alongside implementation and must fail for the targeted regression before the fix is considered complete
- Server/client contracts should be updated before dependent UI behavior
- Mutation logic should be implemented before E2E verification
- Accessibility and observability checks should be completed before the story is closed

## Parallel Opportunities

- `T003` and `T004` can run in parallel during setup
- `T006`, `T007`, and `T008` can run in parallel after `T005`
- In US1, `T009`, `T010`, and `T011` can run in parallel; `T014` and `T015` can run in parallel after `T013`
- In US2, `T017` and `T018` can run in parallel; `T020` can run in parallel with `T021` after `T019`
- In US3, `T022`, `T023`, and `T024` can run in parallel; `T026` and `T027` can run in parallel after `T025`
- In polish, `T028` and `T029` can run in parallel before the final verification tasks

## Parallel Example: User Story 1

```bash
Task: "Add API regression tests in /Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents.test.ts"
Task: "Add client conflict tests in /Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/http-error.test.ts and /Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.conflict.test.tsx"
Task: "Add E2E concurrent title conflict coverage in /Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-title-conflict.spec.ts"
```

## Parallel Example: User Story 2

```bash
Task: "Add reconnect gating tests in /Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/api.test.ts"
Task: "Add reconnect turbulence E2E coverage in /Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-reconnect.spec.ts"
```

## Parallel Example: User Story 3

```bash
Task: "Add autosave hook tests in /Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/hooks/useAutoSave.test.ts"
Task: "Add sticky autosave UI tests in /Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.autosave.test.tsx"
Task: "Add autosave terminal-failure E2E coverage in /Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-autosave.spec.ts"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Validate concurrent title conflict handling independently before moving on

### Incremental Delivery

1. Deliver US1 to eliminate silent title divergence first
2. Deliver US2 to stop redirect storms during reconnect turbulence
3. Deliver US3 to make autosave terminal failure visible and recoverable
4. Finish with cross-cutting observability, accessibility, and verification

### Parallel Team Strategy

1. One engineer completes Phases 1-2
2. Then split across US1, US2, and US3 using the parallel opportunities above
3. Rejoin for Phase 6 verification and evidence capture
