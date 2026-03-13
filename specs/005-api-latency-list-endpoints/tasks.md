# Tasks: API Latency Improvement for List Endpoints

**Input**: Design documents from `/specs/005-api-latency-list-endpoints/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md  

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare the seeded environment and API instance used across all stories.

- [ ] T001 Run the Step 1 commands listed in `specs/005-api-latency-list-endpoints/quickstart.md` to ensure the database is created, seeded, and migrations are current (`pg_isready`, `pnpm install`, `pnpm build:shared`, `pnpm db:migrate`, `pnpm db:seed`).  
- [ ] T002 Start the API locally with `E2E_TEST=1 pnpm dev:api` per Step 2 of `specs/005-api-latency-list-endpoints/quickstart.md` so Story tasks can hit the same authenticated surface used in benchmarks.

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Capture query plans and finalize any index migration before story work.

- [ ] T003 Use `EXPLAIN ANALYZE` against the `/api/documents?type=wiki` query defined in `api/src/routes/documents.ts` to capture the baseline plan documented in the plan and quickstart.  
- [ ] T004 Use `EXPLAIN ANALYZE` against `/api/issues` (with typical filters from `api/src/routes/issues.ts`) to capture its baseline plan per the plan’s DB prerequisite step.  
- [ ] T005 Review current indexes (`api/src/db/schema.sql` and existing migrations) versus the plan’s candidate `038_api_list_latency_indexes.sql` and decide whether to keep existing indexes or add the new migration; document the decision in the same migration file with rollback notes.  
- [ ] T006 Record the index-plan decision and prerequisite evidence in `audits/api-response-time.md` before implementation work proceeds, referencing the plan’s benchmark requirements.

## Phase 3: User Story 1 - Faster Wiki List (Priority: P1)

**Goal**: Reduce `/api/documents?type=wiki` latency to ≤ 98 ms P95 at `c50` while keeping the existing JSON array contract and visibility filtering.  
**Independent Test**: Run Wiki list regression tests plus the canonical benchmark matrix for `/api/documents?type=wiki` to confirm latency and contract stability.

- [ ] T007 [US1] Narrow the SELECT projection and filters in `api/src/routes/documents.ts` so only fields used by the Docs page are returned and optional limit/cursor/summary parameters remain additive.  
- [ ] T008 [US1] Align `api/src/openapi/schemas/documents.ts` with the actual list response so the schema continues to match the exported contract.  
- [ ] T009 [US1] Update `api/src/routes/documents.test.ts` to assert that the wiki list returns the expected visibility-filtered rows and field set unchanged.  
- [ ] T010 [US1] Extend `api/src/routes/documents-visibility.test.ts` to ensure private/workspace visibility behavior remains untouched after the query edits.  
- [ ] T011 [US1] Adjust `web/src/hooks/useDocumentsQuery.ts` (and the Documents context it supports) to consume the tightened contract and to expose any new additive parameters explicitly without breaking default behavior.

## Phase 4: User Story 2 - Faster Issue List (Priority: P1)

**Goal**: Reduce `/api/issues` latency to ≤ 84 ms P95 at `c50` while preserving filters (`state`, `priority`, `assignee_id`, `program_id`, `sprint_id`, `source`, `parent_filter`) and association data.  
**Independent Test**: Execute the current issue list regression test suite and run the benchmark matrix against `/api/issues` to confirm latency reduction and functional parity.

- [ ] T012 [US2] Rework the query in `api/src/routes/issues.ts` to minimize payload (drop unnecessary fields, avoid extra joins) while keeping the existing ordering and association batch helpers.  
- [ ] T013 [US2] Update `api/src/openapi/schemas/issues.ts` so the documented schema matches the fields the endpoint now returns.  
- [ ] T014 [US2] Enhance `api/src/routes/issues.test.ts` to cover filter semantics, ticket_number/display_id preservation, and populated `belongs_to` after the tighter query executes.  
- [ ] T015 [US2] Adjust `web/src/hooks/useIssuesQuery.ts` to handle any optional pagination or summary parameters explicitly while leaving default consumers unaware.  
- [ ] T016 [US2] Update `web/src/components/IssuesList.tsx` + `web/src/components/sidebars/ProjectContextSidebar.tsx` to keep rendering association titles, filters, and optional parameter toggles without breaking existing views.

## Phase 5: User Story 3 - Benchmark Evidence (Priority: P2)

**Goal**: Capture before/after artifacts for the canonical `c10/c25/c50` matrix and document whether the targets were met or fallback limits were needed.  
**Independent Test**: Execute ApacheBench + `k6` runs for both endpoints using the same seeded volume and compare JSON artifacts plus markdown summaries.

- [ ] T017 [US3] Populate `audits/artifacts/api-latency-list-endpoints-before.json` with the baseline metric set (seeded volume, concurrency levels, tool, and P50/P95/P99 values) referenced in `audits/api-response-time.md`.  
- [ ] T018 [US3] After implementing the optimizations, rerun the identical benchmark matrix and write the results to `audits/artifacts/api-latency-list-endpoints-after.json`.  
- [ ] T019 [US3] Update `audits/api-response-time.md` with before/after tables, delta calculations, and whether the wiki/issue targets passed or required fallback limits.  
- [ ] T020 [US3] Refresh the API Response Time section of `audits/consolidated-audit-report-2026-03-10.md` to include the new evidence, success status, and any fallback pagination notes.

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Tie up documentation, quickstart guidance, and rollout notes.

- [ ] T021 Update `specs/005-api-latency-list-endpoints/quickstart.md` to reflect the latest benchmark commands, prerequisite steps, and acceptance checklist for future contributors.  
- [ ] T022 Document the rollout/rollback instructions, evidence requirements, and cross-cutting acceptance gates in `audits/api-response-time.md` so reviewers can follow the updated workflow.  
- [ ] T023 Confirm `pnpm build:shared`, `pnpm test`, and `pnpm type-check` pass after each story completes; cite the commands in `specs/005-api-latency-list-endpoints/plan.md` or `quickstart.md` as the final verification steps.

## Dependencies & Execution Order

- Phase 1 Setup must finish before Phase 2 Foundational or any story work.  
- Phase 2 Foundational (EXPLAIN + index decision) blocks all story phases.  
- User Stories 1 and 2 can execute in parallel once foundation is ready; each should remain independently testable.  
- User Story 3 depends on both US1 and US2 optimizations finishing so benchmarks reflect final code.  
- Phase 6 (Polish) runs after all stories are complete.

## Parallel Execution Examples

- **US1**: `T009` and `T010` (visibility + contract tests) can run together while `T007` edits `api/src/routes/documents.ts`.  
- **US2**: `T014` (route tests) and `T015` (hook updates) can happen concurrently while `T012` refines the issue query.  
- **US3**: `T017` (baseline artifact) and `T018` (after artifact) are sequential by nature, but `T019` (markdown update) can start as soon as the new JSON is ready.

## Implementation Strategy

1. MVP: Complete Setup + Foundational + US1 – confirm wiki list latency target, then stop for verification.  
2. Incrementally add US2: tighten the issue list, verify filters, and rerun the benchmark subset.  
3. Add US3: capture new artifacts, refresh markdown, and confirm the pass/fail statements.  
4. Finish with Phase 6 to document the workflow and verification commands; keep cross-story tasks light.  

## Notes

- All tasks reference specific files so they can be executed without further clarification.  
- [US3] tasks expect the benchmark matrix from `audits/api-response-time.md` to be followed exactly.  
- No tests were explicitly requested beyond regression coverage, so Task 3 phases focus on route/hooks adjustments and documentation.  
