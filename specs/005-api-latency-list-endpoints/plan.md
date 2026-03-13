# Implementation Plan: API Latency Improvement for List Endpoints

**Branch**: `005-api-latency-list-endpoints` | **Date**: 2026-03-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-api-latency-list-endpoints/spec.md`

## Summary

Reduce the P95 latency on `/api/documents?type=wiki` (123ms → ≤98ms) and `/api/issues` (105ms → ≤84ms) using the existing Ship architecture. Follow the DB-efficiency/index prerequisite sequence, tighten query shapes and payloads, and only introduce additive pagination or default-limit fallback behavior if the direct optimizations miss the targets. Capture before/after evidence under the same seeded `c10/c25/c50` benchmark matrix.

## Technical Context

**Language/Version**: TypeScript across `api/`, `web/`, and `shared/` on Node.js 20+  
**Primary Dependencies**: Express, `pg`, Zod/OpenAPI registry, React, Vite, TanStack Query, Vitest, TipTap, Yjs  
**Storage**: PostgreSQL with direct SQL; before/after evidence stored in `audits/api-response-time.md`, `audits/consolidated-audit-report-2026-03-10.md`, and `audits/artifacts/`  
**Testing**: Vitest API tests, existing hook + component sanity checks, canonical benchmark matrix (ApacheBench + `k6` at `c10/c25/c50`)  
**Target Platform**: Ship monorepo running on local PostgreSQL with seeded data  
**Project Type**: Monorepo web service  
**Performance Goals**: `/api/documents?type=wiki` P95 ≤ 98ms, `/api/issues` P95 ≤ 84ms under `c50`; maintain `c10/c25/c50` comparability  
**Constraints**: No response-contract regressions; sequence after DB-efficiency/index review; reuse existing stack/patterns; add pagination/default limits only as fallback with explicit opt-in; benchmark run must mirror baseline conditions exactly  
**Scale/Scope**: Two major list endpoints, their web consumers, optional narrow migration, updated benchmark artifacts, and regression tests for filters/visibility/ordering

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Type Safety Audit**: Typed route parsing, query helpers, and evidence artifacts are already explicit; no new untyped boundaries are introduced.
- **Bundle Size Audit**: Frontend work is limited to adjusting existing hooks/contexts; no new dependencies are planned.
- **API Response Time**: Work targets the constitution metric directly with documented P95 goals and measured evidence.
- **Database Query Efficiency**: Query-plan/index prerequisite review precedes endpoint changes and any migration is narrow and justified.
- **Test Coverage and Quality**: Updates include route tests plus benchmark/regression evidence; before/after metrics use the same commands.
- **Runtime Errors and Edge Cases**: Edge cases (planner instability, additive parameters, rate-limit pollution) are called out with fallback plans.
- **Accessibility Compliance**: No UI interaction changes—existing flows remain unchanged.

**Gate Result**: Pass. No constitution exception is needed before research.

## Project Structure

### Documentation (this feature)

```text
specs/005-api-latency-list-endpoints/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── list-endpoint-latency.md
└── tasks.md
```

### Source Code (repository root)

```text
api/
├── src/
│   ├── routes/
│   │   ├── documents.ts
│   │   ├── issues.ts
│   │   ├── documents.test.ts
│   │   ├── documents-visibility.test.ts
│   │   └── issues.test.ts
│   ├── openapi/
│   │   └── schemas/
│   │       ├── documents.ts
│   │       └── issues.ts
│   └── db/
│       └── migrations/
│           └── 038_api_list_latency_indexes.sql
web/
├── src/
│   ├── hooks/
│   │   ├── useDocumentsQuery.ts
│   │   └── useIssuesQuery.ts
│   ├── contexts/
│   │   └── DocumentsContext.tsx
│   ├── pages/
│   │   └── Documents.tsx
│   └── components/
│       ├── IssuesList.tsx
│       └── sidebars/ProjectContextSidebar.tsx
audits/
├── api-response-time.md
├── consolidated-audit-report-2026-03-10.md
└── artifacts/
    ├── api-latency-list-endpoints-before.json
    └── api-latency-list-endpoints-after.json
```

**Structure Decision**: Keep work inside current API routes, OpenAPI schemas, query hooks, and audit artifacts; no new packages or frameworks.

## Phase 0 Research Summary

1. Baseline evidence comes from `audits/api-response-time.md` (auth local runs with `c10/c25/c50` under seeded data).  
2. DB-efficiency prerequisites require `EXPLAIN ANALYZE` of the wiki and issue list queries to validate or extend indexes before benchmarking any latency work.  
3. `/api/documents?type=wiki` already excludes heavy `content`, so gains are from sort/supporting indexes, query narrowing, and optional bounding.  
4. `/api/issues` currently loads `content`, assignee joins, and association data; improvements expect tighter projections, selective indexes, and optional payload controls.  
5. Fallback pagination/default-limit behavior must be opt-in to avoid contract regressions; Ship web clients should explicitly request those modes.

## Workstreams

### 1. DB-efficiency + index prerequisite review

**Objective**: Prove the wiki and issue list queries have approved plans/indexes before endpoint work.

**Planned actions**

1. Capture `EXPLAIN ANALYZE` for the current `/api/documents?type=wiki` query and for `/api/issues` with representative filter combinations.  
2. Map planner usage against indexes (`idx_documents_active`, `idx_documents_visibility`, `idx_document_associations_*`, etc.).  
3. Decide whether to add migration `038_api_list_latency_indexes.sql` with partial indexes optimized for the shown sort/filters; document rationale and rollback.  
4. Gate the rest of the plan on this review: no benchmarking, no route edits until the prerequisite evidence is recorded.

**Primary touched modules**  
- `api/src/routes/documents.ts`  
- `api/src/routes/issues.ts`  
- `api/src/db/migrations/038_api_list_latency_indexes.sql`  
- `audits/api-response-time.md`

### 2. Wiki list query + payload tightening

**Objective**: Reduce `/api/documents?type=wiki` latency without changing its contract.

**Planned actions**

1. Narrow the query projection and ordering, reusing the same visibility filter logic.  
2. Ensure the route keeps returning the same array and fields used by the Documents UI; optional `limit`/cursor/Summary hints remain additive.  
3. Align OpenAPI schema with the actual response, so contract tests stay valid before/after.  
4. Add tests in `api/src/routes/documents.test.ts` and `documents-visibility.test.ts` to assert unchanged visibility/results.

**Primary touched modules**  
- `api/src/routes/documents.ts`  
- `api/src/openapi/schemas/documents.ts`  
- `api/src/routes/documents.test.ts`  
- `api/src/routes/documents-visibility.test.ts`  
- `web/src/hooks/useDocumentsQuery.ts`  
- `web/src/contexts/DocumentsContext.tsx`

### 3. Issue list query + payload tightening

**Objective**: Reduce `/api/issues` latency while preserving filters, sorting, and associations.

**Planned actions**

1. Review selected columns, joins (assignee/person), and JSON filters; keep projection minimal.  
2. Preserve filters for `state`, `priority`, `assignee_id`, `program_id`, `sprint_id`, `source`, `parent_filter`.  
3. Keep `getBelongsToAssociationsBatch()` and avoid introducing new N+1 patterns.  
4. Test additive parameters or fallback default limits with explicit opt-in so default callers are unaffected.  
5. Update `api/src/routes/issues.test.ts` plus relevant hook/component tests if optional parameters land.

**Primary touched modules**  
- `api/src/routes/issues.ts`  
- `api/src/openapi/schemas/issues.ts`  
- `api/src/routes/issues.test.ts`  
- `web/src/hooks/useIssuesQuery.ts`  
- `web/src/components/IssuesList.tsx`  
- `web/src/components/sidebars/ProjectContextSidebar.tsx`

### 4. Benchmark evidence + acceptance artifacts

**Objective**: Produce durable before/after evidence using the identical `c10/c25/c50` matrix and seeded volume.

**Planned actions**

1. Record the before/after JSON artifacts for both endpoints under `audits/artifacts/api-latency-list-endpoints-before.json` and `...-after.json`.  
2. Capture P50/P95/P99 for `c10`, `c25`, `c50`, tool (`ab` + `k6`), non-2xx counts, and seeded metadata.  
3. Update `audits/api-response-time.md` and the API Response Time section of `audits/consolidated-audit-report-2026-03-10.md` with baseline, after, delta, and success status (pass/fail).  
4. Document whether fallback pagination/default limits were needed, plus the reasons.

**Primary touched modules**  
- `audits/api-response-time.md`  
- `audits/consolidated-audit-report-2026-03-10.md`  
- `audits/artifacts/api-latency-list-endpoints-before.json`  
- `audits/artifacts/api-latency-list-endpoints-after.json`

## Dependency Order

1. Approve DB-efficiency prerequisites via `EXPLAIN` + index review.  
2. Apply migration `038_api_list_latency_indexes.sql` only if needed.  
3. Optimize `/api/documents?type=wiki`.  
4. Optimize `/api/issues`.  
5. Introduce additive pagination/default-limit fallback only if direct optimizations miss the target.  
6. Update web hooks (hooks/context) if additive controls are introduced.  
7. Rerun the identical benchmark matrix and publish before/after artifacts.

## Touched Files and Modules

- `api/src/routes/documents.ts`  
- `api/src/routes/issues.ts`  
- `api/src/routes/documents.test.ts`  
- `api/src/routes/documents-visibility.test.ts`  
- `api/src/routes/issues.test.ts`  
- `api/src/openapi/schemas/documents.ts`  
- `api/src/openapi/schemas/issues.ts`  
- `api/src/db/migrations/038_api_list_latency_indexes.sql`  
- `web/src/hooks/useDocumentsQuery.ts`  
- `web/src/hooks/useIssuesQuery.ts`  
- `web/src/contexts/DocumentsContext.tsx`  
- `web/src/pages/Documents.tsx`  
- `web/src/components/IssuesList.tsx`  
- `web/src/components/sidebars/ProjectContextSidebar.tsx`  
- `audits/api-response-time.md`  
- `audits/consolidated-audit-report-2026-03-10.md`  
- `audits/artifacts/api-latency-list-endpoints-before.json`  
- `audits/artifacts/api-latency-list-endpoints-after.json`

## API Contract Checks

- `/api/documents?type=wiki`
  - Preserve top-level array, visibility, and fields relied on by the Documents page (`id`, `title`, `document_type`, `parent_id`, `position`, `created_at`, `updated_at`, `created_by`, `properties`, `visibility`).
  - Document optional `limit`, `cursor`, or summary parameters in OpenAPI; default callers remain unaffected.
- `/api/issues`
  - Maintain filter order (priority bucket + `updated_at DESC`), `belongs_to`, `ticket_number`, `display_id`, and association data.
  - Fields consumed by Issues UI remain accessible.
  - Optional pagination or summary controls must be opt-in and documented.
- OpenAPI schemas reflect the shipped behavior before and after optimizations.

## Benchmark Protocol

### Baseline configuration

- Seeded volume: 572 documents, 104 issues, 26 users, 35 sprints.
- Environment: local PostgreSQL, local API at `http://127.0.0.1:3000`, authenticated requests, `E2E_TEST=1`.
- Concurrency matrix: `c10`, `c25`, `c50`.
- Tools: ApacheBench (`ab`) for baseline, `k6` for validation.

### Measurement rules

1. Use the identical seeded data + authenticated workflow for both baseline and validation runs.  
2. Capture P50, P95, P99 for each concurrency level and include non-2xx counts.  
3. Invalidate any run with different volume, auth, concurrency, or rate-limit contamination.  
4. If migration or index change occurs after baseline, rerun the full matrix before acceptance.

## Before/After Evidence Format

- `audits/artifacts/api-latency-list-endpoints-before.json` (baseline)  
- `audits/artifacts/api-latency-list-endpoints-after.json` (post-change)  

Each artifact includes:

```json
{
  "captured_at": "ISO timestamp",
  "branch": "005-api-latency-list-endpoints",
  "seeded_volume": {...},
  "environment": {...},
  "results": [
    {
      "endpoint": "/api/documents?type=wiki",
      "tool": "ab",
      "concurrency": 50,
      "p50_ms": 101,
      "p95_ms": 123,
      "p99_ms": 131,
      "non_2xx": 0
    }
  ]
}
```

Markdown updates include baseline, after, delta, pass/fail versus targets, and notes on fallback limits if used.

## Acceptance Gates

1. **DB Gate**: `EXPLAIN` + index decisions documented before endpoint work.  
2. **Contract Gate**: Route/OpenAPI tests proving default behavior and optional parameters remain backward compatible.  
3. **Benchmark Gate**: `c50` P95 ≤ 98ms for wiki, ≤ 84ms for issues; identical benchmark conditions; zero invalid runs.  
4. **Regression Gate**: Visibility/filter/service work covered by regression tests; additive parameters validated if introduced.

## Test Coverage Plan

- Extend `api/src/routes/documents.test.ts` plus `documents-visibility.test.ts` for wiki response checks.  
- Extend `api/src/routes/issues.test.ts` for existing filters, ordering, and association expectations.  
- Update OpenAPI schema files (`api/src/openapi/schemas/documents.ts`, `issues.ts`) and ensure contract tests pass.  
- Validate optional parameter behavior via hook/component tests if they exist.  
- Run `pnpm type-check`, `pnpm build:shared`, and `pnpm test`.

## Rollout / Rollback

### Rollout

1. Land migration (if needed) with rollback steps documented.  
2. Deploy API optimizations.  
3. Update web hooks/component usage for optional parameters only if they ship.  
4. Re-run benchmarks + update artifacts.  

### Rollback

1. Revert API changes if latency regression or contract issues arise.  
2. Remove optional parameters from consumers when rolling back.  
3. Drop added indexes if they cause planner regressions and rerun benchmarks.  
4. Restore previous audit summaries explaining the rollback.

## Risks

- Hidden field dependencies in current issue/list consumers limit aggressive payload trimming.  
- Partial indexes may shift planner behavior for other concurrency levels.  
- Optional pagination limits risk silent truncation unless explicitly adopted.  
- OpenAPI list schemas already lag route behavior; alignment may uncover pre-existing mismatches.  
- Benchmark reproducibility requires strict adherence to the approval matrix; any drift invalidates acceptance.

## Definition of Done

- DB prerequisite review and any index migration complete.  
- `/api/documents?type=wiki` and `/api/issues` meet their P95 targets under the benchmark matrix.  
- Default contracts remain unchanged unless callers opt into additive controls.  
- Optional pagination/limits documented, tested, and adopted by consumers if needed.  
- Benchmark artifacts and markdown summaries updated with identical conditions.  
- `pnpm build:shared`, `pnpm test`, `pnpm type-check` pass.  
- Rollout/rollback notes recorded with evidence.

## Post-Design Constitution Check

- **Type Safety Audit**: Pass. Typed route parsing, schema updates, and evidence artifacts are explicit.  
- **Bundle Size Audit**: Pass. No new dependencies; web changes stay within existing hooks.  
- **API Response Time**: Pass. Targets and benchmark evidence aligned with the constitution metric.  
- **Database Query Efficiency**: Pass. Index review and `EXPLAIN` evidence precede workload changes.  
- **Test Coverage and Quality**: Pass. Route tests and benchmark evidence are part of the plan.  
- **Runtime Errors and Edge Cases**: Pass. Edge cases (planner instability, additive parameters, invalid runs) are explicitly addressed.  
- **Accessibility Compliance**: Pass. No UI changes.

**Post-Design Gate Result**: Pass.
