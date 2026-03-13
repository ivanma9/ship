# Research: Query Efficiency for Accountability and Search Flows

## Decision 1: Keep accountability orchestration and replace row-by-row lookups with set-based batches

**Decision**: Preserve `checkMissingAccountability()` and its helper structure, but change the in-scope helpers so they fetch standup presence, latest standup dates, sprint issue counts, and weekly document existence in grouped queries keyed by sprint IDs and week numbers.

**Rationale**: The audit identified N+1 behavior in `checkMissingStandups()` and `checkSprintAccountability()`, not a flaw in the action-item derivation model itself. Keeping the orchestration shape limits regression risk while removing the avoidable repeated SQL that drives extra work in `/api/accountability/action-items`.

**Alternatives considered**:

- Rewrite accountability inference into one very large SQL statement: rejected because it would compress business rules, due-date logic, and `hasContent()` checks into a harder-to-review query with higher regression risk.
- Move accountability inference into a new repository or data-access layer: rejected because the repo already uses direct SQL in existing modules, and the feature does not justify architectural churn.

## Decision 2: Merge mention search into one SQL statement with source-specific CTEs plus `UNION ALL`

**Decision**: Replace the two query calls in `api/src/routes/search.ts` with one SQL statement that builds `people_matches` and `document_matches` separately, applies each source’s current filters and limits independently, and returns a tagged merged rowset for TypeScript to split back into the existing response buckets.

**Rationale**: This is the smallest change that meets the explicit query-count target (`5 -> 4` for the audited search flow) while preserving the current output contract. Separate CTEs let each source keep its own limit and ordering semantics, and the route can still return `{ people, documents }` unchanged.

**Alternatives considered**:

- Return a single flat merged array from the API: rejected because it changes the external contract and would force web caller changes.
- Keep two SQL queries and only optimize with indexes: rejected because it cannot meet the required query-count reduction.

## Decision 3: Treat the index change as conditional, and only add a targeted search index if explain evidence shows it is needed

**Decision**: Do not assume a migration is required for acceptance. First validate the merged query on the seeded dataset using existing indexes. If the explain plan remains unstable or the seeded rerun misses the accepted latency target, add one narrow migration for title-search support on active documents.

**Rationale**: The existing audit already projects a large execution-time improvement from query consolidation alone. A migration should be justified by explain and rerun evidence, not added automatically. This respects the feature’s "no broad schema redesign" constraint and Ship’s preference for minimal, boring changes.

**Alternatives considered**:

- Add `pg_trgm` and a title index unconditionally: rejected because it widens operational scope before proving necessity.
- Avoid any migration regardless of explain output: rejected because the spec requires plan stability under seeded load, and explain evidence may show the merged path still needs index support.

## Decision 4: If a migration is needed, scope it to active searchable document titles only

**Decision**: If search stability requires an index, add a numbered migration that enables `pg_trgm` if necessary and creates a partial trigram index on active searchable document titles rather than a broad full-table index or unrelated accountability indexes.

**Rationale**: The search hotspot is `%ILIKE%` on `documents.title` for active content documents. A narrow partial index targets the real bottleneck without redesigning the schema or changing unrelated write paths. Accountability batching should primarily benefit from existing association and active-document indexes.

**Alternatives considered**:

- Add composite expression indexes for every accountability helper query up front: rejected because the current schema already has relevant association and active-document indexes, and batching should remove most of the problem without new schema.
- Add a full-table B-tree title index: rejected because `%ILIKE%` does not materially benefit from it.

## Decision 5: Reuse the existing audit runner as the only query instrumentation surface

**Decision**: Continue instrumenting query count and timing in `audits/artifacts/db-query-efficiency-audit.ts` by wrapping `pool.query`, and keep the consolidated audit report as the written publication surface.

**Rationale**: The repository already has baseline JSON snapshots and an audit summary for these exact flows dated March 10, 2026. Reusing that harness keeps the measurement method stable, avoids production-only counters, and provides direct before-and-after comparability.

**Alternatives considered**:

- Add runtime counters to production routes: rejected because it changes application code for a measurement concern already handled by audit tooling.
- Create a separate benchmark harness for only this feature: rejected because it would fragment the baseline and make deltas harder to compare to the existing audit.
