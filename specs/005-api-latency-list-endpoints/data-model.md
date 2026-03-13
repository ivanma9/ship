# Data Model: API Latency Improvement for List Endpoints

## Entity: Wiki List Request

**Represents**: A request to `/api/documents?type=wiki` for the documents list experience.

**Fields**

- `workspace_id`: resolved from session context
- `user_id`: resolved from session context
- `type`: fixed to `wiki` for the primary target path
- `parent_id`: optional existing filter
- `limit`: optional additive fallback control if introduced
- `cursor` or `offset`: optional additive fallback control if introduced
- `summary_mode`: optional additive payload-reduction control if introduced

**Validation rules**

- Authentication is required.
- Existing `type` and `parent_id` behavior must remain valid.
- Any new optimization parameters must be optional and bounded.

**Relationships**

- Reads from `documents`
- Depends on workspace membership and visibility rules

## Entity: Issue List Request

**Represents**: A request to `/api/issues` for issue list and board experiences.

**Fields**

- `workspace_id`: resolved from session context
- `user_id`: resolved from session context
- existing filters:
  - `state`
  - `priority`
  - `assignee_id`
  - `program_id`
  - `sprint_id`
  - `source`
  - `parent_filter`
- optional additive controls:
  - `limit`
  - `cursor` or `offset`
  - `summary_mode`

**Validation rules**

- Authentication is required.
- Existing filter semantics must not change.
- Any new optimization parameters must be optional, typed, and explicitly documented.

**Relationships**

- Reads from `documents`
- Reads from `document_associations`
- Reads assignee/user and person-document data for list display

## Entity: List Response Contract

**Represents**: The response shape currently returned by each list endpoint and relied on by Ship consumers.

### Wiki list contract fields

- `id`
- `workspace_id`
- `document_type`
- `title`
- `parent_id`
- `position`
- `ticket_number`
- `properties`
- `created_at`
- `updated_at`
- `created_by`
- `visibility`
- flattened compatibility fields where currently present

### Issue list contract fields

- `id`
- `title`
- `state`
- `priority`
- `assignee_id`
- `assignee_name`
- `assignee_archived`
- `estimate`
- `source`
- `rejection_reason`
- `ticket_number`
- `display_id`
- `belongs_to`
- lifecycle timestamps
- any currently returned optional fields used by list consumers

**Validation rules**

- Default route behavior must remain compatible for current callers.
- Additive parameters may create optimized modes, but they cannot break default behavior.

## Entity: Index Decision

**Represents**: The documented decision on whether the feature requires a narrow performance migration.

**Fields**

- `query_name`
- `baseline_plan_summary`
- `current_indexes_used`
- `candidate_index`
- `decision`: `keep_existing` | `add_index`
- `rationale`
- `rollback_note`

**Validation rules**

- Must be backed by `EXPLAIN ANALYZE`.
- Must remain limited to the affected list-query access patterns.

## Entity: Benchmark Run

**Represents**: One latency measurement execution for a targeted endpoint and concurrency level.

**Fields**

- `captured_at`
- `branch`
- `endpoint`
- `tool`
- `concurrency`
- `p50_ms`
- `p95_ms`
- `p99_ms`
- `non_2xx`
- `seeded_volume`
- `api_base_url`
- `e2e_test`

**Validation rules**

- Must use the approved seeded volume.
- Must use authenticated local requests.
- Must use one of the approved concurrency levels: `10`, `25`, `50`.

## State Transitions

### Benchmark evidence state

- `baseline-recorded` -> `post-change-recorded` -> `accepted`
- `baseline-recorded` -> `post-change-recorded` -> `rejected`

### Index decision state

- `undecided` -> `existing-indexes-sufficient`
- `undecided` -> `migration-required`

### Fallback bounding state

- `not-needed`
- `planned-but-disabled`
- `enabled-with-explicit-client-adoption`
