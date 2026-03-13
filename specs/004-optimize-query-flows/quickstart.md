# Quickstart: Query Efficiency for Accountability and Search Flows

## 1. Prepare the environment

1. Ensure PostgreSQL is running locally.
2. Install dependencies with `pnpm install`.
3. Build shared types with `pnpm build:shared`.
4. Run migrations with `pnpm db:migrate`.

## 2. Capture the current baseline

1. Run `pnpm test` to confirm the API baseline is green before performance changes.
2. Run `pnpm exec tsx audits/artifacts/db-query-efficiency-audit.ts` and keep the JSON output as the feature baseline if a fresh snapshot is needed.
3. Note the current March 10, 2026 audit values for:
   - Search content flow query count: `5`
   - Projected optimized search flow query count: `4`
   - Search query-family execution-time target: approximately `63%` faster

## 3. Implement the API changes

1. Refactor `api/src/services/accountability.ts` to batch standup, issue-count, and weekly-doc support queries.
2. Update `api/src/routes/search.ts` to use one consolidated mention-search SQL statement and split the merged rows back into the existing response buckets.
3. Add migration `038_query_efficiency_indexes.sql` only if explain evidence shows the merged search query still needs targeted index support.

## 4. Update regression coverage

1. Extend `api/src/services/accountability.test.ts` for batched-lookup edge cases.
2. Extend `api/src/routes/search.test.ts` for mixed-source, single-source, and empty-result semantics.
3. Extend `api/src/routes/documents-visibility.test.ts` to confirm private-document visibility is unchanged.

## 5. Validate performance and stability

1. Run `pnpm test`.
2. If a migration was added, run `pnpm db:migrate`.
3. Run `pnpm exec tsx audits/artifacts/db-query-efficiency-audit.ts`.
4. Capture `EXPLAIN ANALYZE` for the merged mention-search query and any new batched accountability query that becomes performance-critical.
5. Update `audits/consolidated-audit-report-2026-03-10.md` with before-and-after deltas and explain notes.

## 6. Feature completion check

- Search content flow measures four queries instead of five.
- Seeded rerun shows a material search latency improvement and no contract regressions.
- Accountability action-items preserve current behavior while avoiding per-item query loops.
- Audit artifacts and report are updated in the same change set.
