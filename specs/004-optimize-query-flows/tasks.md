# Tasks: Query Efficiency for Accountability and Search Flows

**Input**: Design documents from `/specs/004-optimize-query-flows/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/query-efficiency.md, quickstart.md

**Tests**: API regression and performance-validation tasks are included because the specification explicitly requires instrumented reruns, behavior preservation, and no regressions.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (`US1`, `US2`, `US3`)
- Every task includes an exact file path

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Refresh the local performance baseline and pin the validation surfaces used throughout the feature.

- [X] T001 Capture a fresh pre-change query-efficiency baseline with `pnpm exec tsx audits/artifacts/db-query-efficiency-audit.ts` and store the output in `audits/artifacts/db-query-efficiency-baseline.json`
- [X] T002 Capture pre-change `EXPLAIN ANALYZE` notes for mention search and accountability hotspot queries in `audits/consolidated-audit-report-2026-03-10.md`
- [X] T003 Verify the implementation and validation command sequence in `specs/004-optimize-query-flows/quickstart.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Put shared measurement and typing scaffolding in place before story work starts.

**⚠️ CRITICAL**: No user story work should begin until this phase is complete

- [X] T004 Add typed before/after flow comparison fields and stable flow labels in `audits/artifacts/db-query-efficiency-audit.ts`
- [X] T005 [P] Add typed merged-row and discriminator helpers for mention-search result reconstruction in `api/src/routes/search.ts`
- [X] T006 [P] Add typed batched-row helper interfaces and ID-set helpers for accountability support queries in `api/src/services/accountability.ts`

**Checkpoint**: Baseline instrumentation and shared query-row typing are ready for story implementation

---

## Phase 3: User Story 1 - Return Search Results with Less Overhead (Priority: P1) 🎯 MVP

**Goal**: Reduce mention-search database round trips while preserving response shape, ordering, limits, and visibility rules.

**Independent Test**: Run the mention-search API tests plus the instrumented search-content audit flow and confirm `{ people, documents }` semantics are unchanged while the flow uses four queries instead of five.

### Tests for User Story 1

- [X] T007 [P] [US1] Extend mixed-source, single-source, empty-result, and per-source limit coverage in `api/src/routes/search.test.ts`
- [X] T008 [P] [US1] Extend private-document and admin-visibility regression coverage for merged mention search in `api/src/routes/documents-visibility.test.ts`

### Implementation for User Story 1

- [X] T009 [US1] Replace the dual-query mention-search implementation with one CTE plus `UNION ALL` statement that preserves independent source filtering, ordering, and limits in `api/src/routes/search.ts`
- [X] T010 [US1] Reconstruct merged mention-search rows back into the existing `people` and `documents` contract in `api/src/routes/search.ts`
- [X] T011 [US1] Capture post-change mention-search `EXPLAIN ANALYZE` findings and record the index decision in `audits/consolidated-audit-report-2026-03-10.md`
- [X] T012 [US1] Add targeted title-search support only if repeated seeded runs or `EXPLAIN ANALYZE` show the merged search query misses the latency target or uses unstable plans in `api/src/db/migrations/038_query_efficiency_indexes.sql` — SKIPPED: latency 0.229 ms < 5 ms target, plan stable; no migration needed

**Checkpoint**: User Story 1 is complete when mention search remains contract-stable and the audited search-content flow drops to four queries

---

## Phase 4: User Story 2 - Batch Accountability Data Efficiently (Priority: P2)

**Goal**: Remove per-item accountability query loops without changing inferred action items, ordering, or omission behavior.

**Independent Test**: Run the accountability service and route regression tests plus the instrumented main-page/action-items audit flow and confirm grouped retrieval preserves current results while eliminating repeated per-record queries.

### Tests for User Story 2

- [X] T013 [P] [US2] Extend batched standup, sprint issue-count, weekly-doc reuse, and missing-related-record regression coverage in `api/src/services/accountability.test.ts`
- [X] T014 [P] [US2] Create route-level action-item response-shape and urgency-order regression coverage in `api/src/routes/accountability.test.ts`

### Implementation for User Story 2

- [X] T015 [US2] Replace standup existence and last-standup per-sprint loops with grouped queries while keeping message generation and omission behavior unchanged in `api/src/services/accountability.ts`
- [X] T016 [US2] Replace per-sprint issue-count lookups with grouped sprint issue counts while keeping sprint date and status checks unchanged in `api/src/services/accountability.ts`
- [X] T017 [US2] Batch weekly-plan and weekly-retro lookups inside `checkWeeklyPersonAccountability()` so one `(workspace, person, sprint)` fetch is reused across all allocations in `api/src/services/accountability.ts`
- [X] T018 [US2] Preserve synthetic action-item mapping, urgency sorting, due-date handling, and route compatibility after service batching in `api/src/routes/accountability.ts`

**Checkpoint**: User Story 2 is complete when accountability action items are behaviorally unchanged and no longer rely on avoidable per-item query loops

---

## Phase 5: User Story 3 - Prove the Performance Gain Without Regressions (Priority: P3)

**Goal**: Produce before-and-after measurement evidence, stable query-plan validation, and published audit results for the optimized flows.

**Independent Test**: Re-run the seeded audit harness and compare the generated artifacts plus audit report to confirm query-count, latency, and regression targets are met across repeated runs.

### Tests for User Story 3

- [X] T019 [P] [US3] Add before-and-after flow comparison coverage for search and accountability metrics in `audits/artifacts/db-query-efficiency-audit.ts`

### Implementation for User Story 3

- [X] T020 [US3] Run the seeded post-change audit harness and store the first after snapshot in `audits/artifacts/db-query-efficiency-after.json`
- [X] T021 [US3] Run the seeded audit harness a second time to confirm plan stability and store the follow-up snapshot in `audits/artifacts/db-query-efficiency-after2.json`
- [X] T022 [US3] Publish before-and-after query counts, execution-time deltas, `EXPLAIN ANALYZE` notes, and migration rationale in `audits/consolidated-audit-report-2026-03-10.md`

**Checkpoint**: User Story 3 is complete when the audit artifacts and report prove the performance gains and confirm no behavior regressions

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation updates that cut across all stories

- [X] T023 [P] Refresh final verification steps, current baseline notes, and conditional migration guidance in `specs/004-optimize-query-flows/quickstart.md`
- [X] T024 Run final regression and performance validation commands referenced in `specs/004-optimize-query-flows/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup completion
- **User Story 1 (Phase 3)**: Depends on Foundational completion
- **User Story 2 (Phase 4)**: Depends on Foundational completion
- **User Story 3 (Phase 5)**: Depends on User Story 1 and User Story 2 completion
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Starts after Phase 2 and is the MVP scope
- **US2 (P2)**: Starts after Phase 2 and can proceed in parallel with US1 if staffed separately
- **US3 (P3)**: Requires US1 and US2 because it validates the combined outcome and publishes the evidence

### Within Each User Story

- Test tasks precede implementation tasks
- Query-shape changes precede `EXPLAIN ANALYZE` capture
- Migration task `T012` is conditional and only executes if repeated measurement or explain evidence justifies it
- Audit publication follows successful reruns

## Parallel Opportunities

- **Setup**: `T001` and `T002` can run in parallel once the environment is ready
- **Foundational**: `T005` and `T006` can run in parallel
- **US1**: `T007` and `T008` can run in parallel before `T009`
- **US2**: `T013` and `T014` can run in parallel before `T015`
- **US3**: `T019` can proceed while implementation evidence is being gathered, but `T020` and `T021` stay sequential to preserve repeated-run ordering

## Parallel Example: User Story 1

```bash
Task: "Extend mixed-source, single-source, empty-result, and per-source limit coverage in api/src/routes/search.test.ts"
Task: "Extend private-document and admin-visibility regression coverage for merged mention search in api/src/routes/documents-visibility.test.ts"
```

## Parallel Example: User Story 2

```bash
Task: "Extend batched standup, sprint issue-count, weekly-doc reuse, and missing-related-record regression coverage in api/src/services/accountability.test.ts"
Task: "Create route-level action-item response-shape and urgency-order regression coverage in api/src/routes/accountability.test.ts"
```

## Parallel Example: User Story 3

```bash
Task: "Add before-and-after flow comparison coverage for search and accountability metrics in audits/artifacts/db-query-efficiency-audit.ts"
Task: "Refresh final verification steps, current baseline notes, and conditional migration guidance in specs/004-optimize-query-flows/quickstart.md"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2
2. Complete Phase 3 (US1)
3. Validate the search route contract and query-count reduction
4. Stop if only the MVP scope is desired

### Incremental Delivery

1. Deliver US1 to hit the explicit `5 -> 4` search query target
2. Deliver US2 to remove accountability query loops without waiting for the audit publication work
3. Deliver US3 to publish the measured evidence and plan-stability confirmation

### Parallel Team Strategy

1. One developer can take US1 after foundational work
2. A second developer can take US2 in parallel after foundational work
3. US3 begins once both implementation tracks are merged and ready for repeated reruns

## Notes

- `[P]` tasks touch different files or can be executed without waiting on each other
- All tasks include exact file paths and use the required checklist format
- The suggested MVP scope is **User Story 1 only**
- `api/src/routes/accountability.test.ts` does not exist yet, so `T014` intentionally creates that regression surface
