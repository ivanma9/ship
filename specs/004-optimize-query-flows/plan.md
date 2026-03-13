# Implementation Plan: Query Efficiency for Accountability and Search Flows

**Branch**: `004-optimize-query-flows` | **Date**: 2026-03-11 | **Spec**: [spec.md](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/specs/004-optimize-query-flows/spec.md)
**Input**: Feature specification from `/specs/004-optimize-query-flows/spec.md`

## Summary

Reduce avoidable database work in two audited API paths without changing Ship's architecture or response contracts. The implementation stays inside the current Express plus `pg` stack by replacing accountability per-sprint query loops with set-based batch queries, consolidating mention search into one SQL statement that preserves separate people and document result semantics, and reusing the existing audit runner plus consolidated audit report for before-and-after measurement, `EXPLAIN ANALYZE`, and rollout evidence.

## Technical Context

**Language/Version**: TypeScript across `api/`, `web/`, and `shared/` on Node.js 20+  
**Primary Dependencies**: Express, `pg`, Zod/OpenAPI registry, React, Vite, Vitest, TipTap, Yjs  
**Storage**: PostgreSQL with direct SQL access; JSON audit artifacts in `audits/artifacts/` for performance evidence  
**Testing**: Vitest API tests plus the existing database query efficiency audit runner and consolidated audit report workflow  
**Target Platform**: Monorepo web application with a Node.js API and PostgreSQL-backed seeded local validation environment  
**Project Type**: Monorepo web application  
**Performance Goals**: Reduce audited mention-search flow query count from 5 to 4; achieve a material execution-time gain for the audited search query family, targeting the existing projected ~63% improvement; remove avoidable N+1 behavior from accountability inference paths  
**Constraints**: Preserve response shape and ordering semantics; preserve per-source search limits; no broad schema redesign; use existing Ship stack and patterns; keep query plans stable under seeded load; use numbered migrations only if a new index is required  
**Scale/Scope**: Two API hotspots (`/api/search/mentions` and `/api/accountability/action-items`), one optional performance migration, existing audit runner plus report refresh, and regression coverage for current response behavior

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Type Safety Audit**: Query result rows, measurement summaries, and any helper types will stay explicitly typed in TypeScript. No widened `any` or untyped query helpers are required.
- **Bundle Size Audit**: This work is API and audit-artifact only. No web bundle changes or new browser dependencies are planned.
- **API Response Time**: The feature directly targets constitution latency goals by removing avoidable round trips on changed read paths and documenting before-and-after timing evidence against seeded data.
- **Database Query Efficiency**: The plan eliminates known N+1 behavior, keeps SQL readable in existing route/service modules, and includes an index decision plus `EXPLAIN ANALYZE` evidence for any materially new complex query.
- **Test Coverage and Quality**: Existing API tests will be extended to cover behavior-preserving changes, and the instrumented audit rerun becomes the performance regression guard for the changed flows.
- **Runtime Errors and Edge Cases**: Empty search results, single-source search matches, missing related accountability records, and unstable plan selection are all explicitly covered in the plan and validation steps.
- **Accessibility Compliance**: No UI behavior or controls change. This principle is unaffected for implementation, but preserved because response contracts stay stable for existing UI consumers.

**Gate Result**: Pass. No constitution exception is required before research.

## Project Structure

### Documentation (this feature)

```text
specs/004-optimize-query-flows/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── query-efficiency.md
└── tasks.md
```

### Source Code (repository root)

```text
api/
├── src/
│   ├── routes/
│   │   ├── accountability.ts
│   │   ├── search.ts
│   │   ├── search.test.ts
│   │   └── documents-visibility.test.ts
│   ├── services/
│   │   ├── accountability.ts
│   │   └── accountability.test.ts
│   ├── db/
│   │   └── migrations/
│   │       └── 038_query_efficiency_indexes.sql
│   └── openapi/
│       └── schemas/
│           ├── accountability.ts
│           └── search.ts
audits/
├── artifacts/
│   └── db-query-efficiency-audit.ts
└── consolidated-audit-report-2026-03-10.md
```

**Structure Decision**: Keep all implementation in the existing API route/service modules, direct SQL queries, Vitest coverage, and audit artifacts. No new packages, service layer split, or schema redesign is introduced.

## Phase 0 Research Summary

- The accountability service should keep its current orchestration shape but replace row-by-row lookups with batched set queries keyed by sprint IDs and week numbers.
- Mention search should use one SQL statement with per-source CTEs and `UNION ALL`, then split the merged rows back into the existing `{ people, documents }` response structure in TypeScript.
- Existing association indexes already support most accountability batching; the only migration-worthy index candidate is a partial title-search index for active searchable documents if `EXPLAIN ANALYZE` after query consolidation still shows unstable sequential scans under seeded load.
- The existing audit runner at `audits/artifacts/db-query-efficiency-audit.ts` is the right instrumentation surface for query count and latency reruns because it already wraps `pool.query`, records flow-level totals, and has March 10, 2026 baseline artifacts for comparison.
- Rollout should be guarded by repeated seeded reruns and a fast rollback path that removes the new migration first if an added index causes unexpected planner changes.

## Workstreams

### 1. Accountability batching

**Objective**: Remove per-sprint query loops in accountability inference while preserving returned action items.

**Planned actions**

1. Keep `checkMissingAccountability()` as the top-level orchestrator and preserve its current returned `MissingAccountabilityItem[]` contract.
2. Replace the standup loop in `checkMissingStandups()` with one batch query that returns, per sprint, whether a standup exists today and the latest historical standup date.
3. Replace the sprint loop issue-count query in `checkSprintAccountability()` with one grouped count query keyed by sprint ID.
4. Replace repeated weekly-plan and weekly-retro existence lookups with one batch fetch per doc type and sprint number, then perform `hasContent()` checks in memory.
5. Keep omission, visibility, due-date, and message-generation logic unchanged after the batched inputs are assembled.

**Primary touched modules**

- [api/src/services/accountability.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/services/accountability.ts)
- [api/src/services/accountability.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/services/accountability.test.ts)
- [api/src/routes/accountability.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/accountability.ts)

### 2. Combined mention search SQL

**Objective**: Collapse mention search into one database round trip while preserving separate result buckets and limits.

**Planned actions**

1. Keep the current auth, workspace, and admin-visibility checks in `searchRouter.get('/mentions')`.
2. Replace the separate people and document queries with one SQL statement that:
   - computes `people_matches` and `document_matches` as separate CTEs,
   - applies each source’s existing filters and independent `LIMIT`,
   - unifies rows with `UNION ALL`,
   - tags each row with a source discriminator and a source-local sort key.
3. Reconstruct the response into the existing `people` and `documents` arrays in TypeScript so OpenAPI contracts and web callers remain unchanged.
4. Preserve issue/wiki/project/program ordering and `updated_at DESC` for document results, and preserve alphabetical ordering for people results.

**Primary touched modules**

- [api/src/routes/search.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/search.ts)
- [api/src/routes/search.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/search.test.ts)
- [api/src/routes/documents-visibility.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents-visibility.test.ts)

### 3. Index and migration decision

**Objective**: Add only the minimum schema support needed to keep the new query family stable under seeded load.

**Planned actions**

1. Validate the consolidated search query against current indexes before adding a migration.
2. If the merged mention-search query still relies on an unstable sequential scan or misses the accepted latency target under the seeded benchmark, add migration `038_query_efficiency_indexes.sql`.
3. Scope any migration to targeted performance support only:
   - enable `pg_trgm` if not already available,
   - add a partial trigram index over active searchable document titles for workspace-scoped mention search,
   - avoid schema-table rewrites or non-search-related indexes.
4. Do not edit `schema.sql` for existing tables; the migration becomes the single source of change.

**Primary touched modules**

- [api/src/db/migrations/038_query_efficiency_indexes.sql](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/db/migrations/038_query_efficiency_indexes.sql)
- [audits/consolidated-audit-report-2026-03-10.md](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/consolidated-audit-report-2026-03-10.md)

### 4. Instrumentation and validation rerun

**Objective**: Reuse the existing audit flow to confirm query-count, latency, and behavior outcomes after implementation.

**Planned actions**

1. Extend or reuse `audits/artifacts/db-query-efficiency-audit.ts` so it can capture:
   - total query count per audited flow,
   - slowest query text and duration,
   - repeated-query heuristics,
   - before-and-after JSON snapshots for the updated flows.
2. Add a narrow comparison section for:
   - `/api/search/mentions?q=pro`,
   - `/api/accountability/action-items` under seeded main-page load.
3. Refresh the relevant section of the consolidated audit report with measured before-and-after counts, timing deltas, and `EXPLAIN ANALYZE` summaries.
4. Use the same seeded login and flow sequence as the existing baseline artifacts so comparisons stay valid.

**Primary touched modules**

- [audits/artifacts/db-query-efficiency-audit.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/artifacts/db-query-efficiency-audit.ts)
- [audits/consolidated-audit-report-2026-03-10.md](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/consolidated-audit-report-2026-03-10.md)

## Dependency Order

1. Refactor accountability batching first so the main-page action-items flow stops accumulating per-item queries before final audit reruns.
2. Land the combined mention-search SQL next, because the spec’s explicit query-count target is tied to that route.
3. Run `EXPLAIN ANALYZE` on the merged mention-search query and the new accountability batch queries before deciding whether migration `038_query_efficiency_indexes.sql` is necessary.
4. Add the performance migration only if the explain output or seeded audit rerun shows current indexes are insufficient for stable acceptance.
5. Update audit instrumentation and published before-and-after artifacts after code changes and any needed migration are in place.
6. Refresh or extend regression tests last, once the new SQL shape and any index-backed query plans are fixed.

## Touched Files and Modules

- [api/src/routes/search.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/search.ts)
- [api/src/routes/search.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/search.test.ts)
- [api/src/routes/documents-visibility.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents-visibility.test.ts)
- [api/src/services/accountability.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/services/accountability.ts)
- [api/src/services/accountability.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/services/accountability.test.ts)
- [api/src/routes/accountability.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/accountability.ts)
- [api/src/db/migrations/038_query_efficiency_indexes.sql](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/db/migrations/038_query_efficiency_indexes.sql)
- [audits/artifacts/db-query-efficiency-audit.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/artifacts/db-query-efficiency-audit.ts)
- [audits/consolidated-audit-report-2026-03-10.md](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/consolidated-audit-report-2026-03-10.md)

## SQL Contract Notes

- `/api/search/mentions` remains contract-stable:
  - response stays `{ people, documents }`
  - `people` still contain `id`, `name`, `document_type: 'person'`
  - `documents` still contain `id`, `title`, `document_type`, `visibility`
  - people remain limited to 5, documents remain limited to 10
  - current visibility rules remain intact
- `/api/accountability/action-items` remains contract-stable:
  - returned synthetic IDs, title messages, due-date handling, and urgency sorting stay unchanged
  - batching only changes how source data is gathered, not how action items are derived
- OpenAPI schemas should remain unchanged unless a regression test exposes an undocumented field mismatch already present in the route.

## Data and Migration Impact

- No new content tables, document types, or relationship models are introduced.
- Existing indexes likely sufficient for accountability batching:
  - `idx_document_associations_related_type`
  - `idx_document_associations_document_type`
  - `idx_documents_active`
  - `idx_documents_person_user_id`
- One migration is conditionally planned for search stability:
  - `038_query_efficiency_indexes.sql`
  - purpose: optional `pg_trgm` enablement plus a partial trigram title index for active searchable documents
  - rollback: drop the new index and extension usage from the migration rollback instructions if the planner regresses
- `schema.sql` is not edited because this feature changes existing tables only.

## Query Instrumentation and Measurement Protocol

### Baseline

1. Use `audits/artifacts/db-query-efficiency-audit.ts` as the canonical measurement harness.
2. Capture the current baseline JSON for the five audited flows, keeping March 10, 2026 artifacts as the reference.
3. Record flow-level totals, repeated-query heuristics, and slowest SQL text before any code change.

### After-change rerun

1. Re-run the same audit harness with the same seeded data and authenticated flow sequence.
2. Compare:
   - Search content total queries: target `5 -> 4`
   - Load main page total queries: expect at least one fewer query if accountability batching removes the action-items N+1 hotspot
   - Search query-family execution time: target a material improvement, with success at or above the spec’s accepted 60% median gain threshold if the seeded dataset reproduces the audit profile
3. Publish both raw JSON and the written summary in the consolidated audit report.

### Query count method

- Continue wrapping `pool.query` at the audit layer rather than adding production-only counters.
- Normalize SQL text the same way as the current harness so repeated-query detection remains comparable to prior artifacts.

## EXPLAIN ANALYZE Validation

1. Capture `EXPLAIN ANALYZE` for:
   - the pre-change people query,
   - the pre-change documents query,
   - the merged mention-search query,
   - the batched standup/accountability queries if they become the slowest path in reruns.
2. Compare execution time, scan type, row counts, and whether the planner uses existing or new indexes.
3. Treat a planner shift as acceptable only if:
   - response behavior is unchanged,
   - measured seeded latency still improves,
   - repeated seeded runs keep the same plan shape or stay within the accepted performance band.
4. If the merged search query remains a sequential scan but still meets stability and latency targets on seeded load, document that result and defer further indexing rather than widening schema scope.

## Regression Test Plan

### API behavior tests

- Extend [api/src/routes/search.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/search.test.ts) to prove:
  - mixed people and document results still return in the expected buckets,
  - empty queries and single-source matches keep current semantics,
  - per-source limits are preserved.
- Extend [api/src/routes/documents-visibility.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents-visibility.test.ts) to ensure the merged query does not weaken private-document visibility rules.
- Extend [api/src/services/accountability.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/services/accountability.test.ts) to verify:
  - standup presence and last-standup calculations are unchanged,
  - zero-issue sprints still yield `week_issues`,
  - weekly plan and retro inference still honor missing-content checks after batched fetches.

### Performance regression evidence

- Re-run the audit harness before and after implementation.
- Keep generated JSON snapshots under `audits/artifacts/` and summarize the deltas in the consolidated audit report.
- If a migration is added, run the audit both before and after the migration on the same code to isolate index impact.

### Verification commands

- `pnpm test`
- `pnpm db:migrate` if migration `038` is added
- `pnpm exec tsx audits/artifacts/db-query-efficiency-audit.ts`

## Rollout and Rollback

### Rollout

1. Ship the accountability batching and merged search query behind normal deployment, with no API contract change expected.
2. Apply migration `038_query_efficiency_indexes.sql` only if explain and seeded audit evidence justify it.
3. Publish updated audit artifacts and the written summary in the same change so reviewers can compare counts and timings immediately.

### Rollback

1. Revert the merged search query and accountability batching code if behavior regressions appear in API tests or seeded audit comparisons.
2. If the optional migration causes planner regressions, drop the added index first and re-run the audit before reverting application code.
3. Restore the prior audit baseline artifacts only after the code or migration rollback is complete, so the recorded evidence matches the active state.

## Risks and Mitigations

| Risk | Why it matters | Mitigation |
|------|----------------|------------|
| Merged search query changes result ordering or bucket composition | Breaks mention autocomplete expectations and violates the response contract | Preserve source-local ordering inside CTEs, reconstruct arrays in TypeScript, and add route plus visibility regression tests |
| Batched accountability queries miss edge cases handled by current loops | Could suppress action items or change due-date messages | Keep derivation logic intact after batching, and extend service tests for empty, missing, and no-content scenarios |
| New trigram index changes planner behavior unexpectedly | Could improve one query while regressing other title-search paths | Add the migration only after explain evidence, then validate with repeated seeded reruns and retain a drop-index rollback path |
| Audit rerun drifts from the baseline method | Makes before-and-after numbers incomparable | Reuse the existing audit harness, seeded dataset, and consolidated report surface without changing measurement semantics |

## Definition of Done

- Search mentions flow measures four database queries instead of five in the audit harness.
- Search query-family execution time shows a material seeded improvement and meets or exceeds the accepted 60% target if the dataset reproduces the audited baseline profile.
- Accountability inference no longer performs avoidable per-item query loops for the in-scope standup, sprint-issue, and weekly-doc checks.
- Search and accountability API tests pass with no response-shape, visibility, or semantics regressions.
- `EXPLAIN ANALYZE` evidence is captured for the merged search query and any new index-backed path.
- The consolidated audit report is updated with before-and-after query counts, latency evidence, and planner notes.
- Post-design constitution check still passes with no exceptions.

## Post-Design Constitution Check

- **Type Safety Audit**: Planned typed row mappers, response discriminators, and audit summaries remain explicit. Pass.
- **Bundle Size Audit**: No frontend code path or dependency growth is introduced. Pass.
- **API Response Time**: The changed endpoints now have an explicit measurement plan and seeded timing evidence requirement. Pass.
- **Database Query Efficiency**: The design removes known N+1 behavior, centralizes SQL in the existing route/service modules, and adds `EXPLAIN ANALYZE` plus a minimal migration gate. Pass.
- **Test Coverage and Quality**: Regression coverage and before-and-after audit evidence are defined for all changed paths. Pass.
- **Runtime Errors and Edge Cases**: Empty results, missing records, no-content docs, and planner instability are explicitly covered. Pass.
- **Accessibility Compliance**: No UI surface changes. Pass.

**Post-Design Gate Result**: Pass.
