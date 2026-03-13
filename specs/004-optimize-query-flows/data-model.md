# Data Model: Query Efficiency for Accountability and Search Flows

## Overview

This feature does not introduce new persisted domain entities. It changes how existing document and association data is fetched and measured for two API paths.

## Entities

### 1. Mention Search Result Row

**Purpose**: Represents one row returned from the consolidated mention-search SQL before the route splits rows into the existing `people` and `documents` arrays.

**Fields**

- `source_type`: `person` or `document`
- `id`: document identifier
- `name`: populated for person results
- `title`: populated for document results
- `document_type`: `person`, `wiki`, `issue`, `project`, or `program`
- `visibility`: present for document results
- `source_order`: source-local order key used to preserve per-source ordering

**Validation rules**

- Person rows must only represent active `person` documents in the current workspace.
- Document rows must only represent active `wiki`, `issue`, `project`, or `program` documents visible to the caller.
- The merged rowset must split cleanly back into the existing API response contract.

### 2. Accountability Batch Input Set

**Purpose**: The grouped identifiers used to fetch accountability support data in one query per concern instead of one query per sprint or allocation.

**Fields**

- `sprint_ids`: active sprint IDs relevant to the current user
- `sprint_numbers`: current and next sprint numbers for weekly document checks
- `person_id`: current user’s person document ID
- `workspace_id`: workspace scope for all queries
- `user_id`: current authenticated user ID

**Relationships**

- `sprint_ids` map to `documents` rows with `document_type = 'sprint'`
- `sprint_ids` relate to issues through `document_associations`
- `person_id` links weekly plans and retros through document `properties`

**Validation rules**

- Empty identifier sets must short-circuit the relevant batched queries.
- Missing related rows must preserve today’s omission behavior rather than create synthetic placeholders.

### 3. Batched Accountability Support Row

**Purpose**: Carries grouped database results that feed the unchanged action-item derivation logic.

**Examples**

- standup status by sprint (`has_standup_today`, `last_standup_date`, `issue_count`)
- sprint issue counts by sprint ID
- weekly plan and retro existence plus content payload by week number and person

**Validation rules**

- Grouped counts must be keyed uniquely enough to map back to the relevant sprint or week.
- Missing grouped rows must be interpreted the same way the current one-row-per-query logic interprets empty result sets.

### 4. Query Measurement Record

**Purpose**: The audit-layer record for before-and-after comparison in the database query efficiency audit.

**Fields**

- `flow`: audited user flow name
- `total_queries`: number of `pool.query` executions in that flow
- `slowest_ms`: duration of the slowest query in the flow
- `slowest_sql`: normalized SQL text for the slowest query
- `n_plus_one_detected`: heuristic flag for repeated query shapes
- `repeated_query_count`: highest repeat count of one normalized query shape

**Validation rules**

- Measurement records must be generated with the same instrumentation method before and after the change.
- Flow names and flow order must remain stable so comparisons are meaningful.

## Relationships

- One `Mention Search Result Row` becomes either one entry in `people` or one entry in `documents`.
- One `Accountability Batch Input Set` produces many `Batched Accountability Support Row` records.
- Many `Query Measurement Record` entries roll up into one audit report for the rerun.

## State Considerations

- No persisted state transitions are introduced.
- The only behavioral transition is from loop-based fetching to grouped fetching while preserving current output semantics.
- The only schema transition is optional: a performance-only index migration if explain evidence proves it necessary.
