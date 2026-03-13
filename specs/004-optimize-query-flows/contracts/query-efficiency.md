# Query Efficiency Contracts

## 1. Mention Search Response Contract

### Scope

`GET /api/search/mentions?q=...`

### Required behavior

- The response remains a JSON object with `people` and `documents` arrays.
- `people` results continue to contain:
  - `id`
  - `name`
  - `document_type: "person"`
- `documents` results continue to contain:
  - `id`
  - `title`
  - `document_type`
  - `visibility`
- People results remain capped at 5.
- Document results remain capped at 10.
- Document visibility rules remain unchanged:
  - workspace-visible documents are returned,
  - a caller’s own private documents are returned,
  - admins can see all matching documents in the workspace.
- Ordering remains unchanged:
  - people sorted by title/name ascending,
  - documents ordered by existing type priority and then most recently updated.

## 2. Accountability Action-Items Contract

### Scope

`GET /api/accountability/action-items`

### Required behavior

- The response shape remains unchanged for the Action Items modal and API consumers.
- Synthetic IDs, titles, urgency sorting, due-date handling, and derived metadata remain compatible with the current route contract.
- Batching may change the internal query count, but it must not change:
  - which items appear,
  - item ordering by urgency,
  - due-date interpretation,
  - omission behavior for missing or invisible related records.

## 3. SQL and Migration Contract

### Required behavior

- Any new SQL must stay inside the existing route/service modules and remain readable enough for routine maintenance.
- Any performance migration must be narrowly scoped to index support and use a numbered SQL migration file.
- Existing OpenAPI schemas remain valid unless a test exposes an already undocumented route field that must be formalized separately.

## 4. Audit Evidence Contract

### Required behavior

- Before-and-after measurements must come from the existing `db-query-efficiency-audit.ts` harness.
- The same seeded flow sequence must be used for baseline and rerun comparisons.
- The consolidated audit report must publish:
  - query-count deltas,
  - execution-time deltas,
  - `EXPLAIN ANALYZE` notes,
  - any index decision and its rationale.
