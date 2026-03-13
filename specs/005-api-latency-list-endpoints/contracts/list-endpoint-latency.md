# Contract Notes: List Endpoint Latency Improvements

This feature does not redesign the public API. It preserves the existing default contracts for the two targeted list endpoints and allows only additive optimization controls if implementation requires them.

## Endpoint: `GET /api/documents`

### In-scope target

- Existing target path: `GET /api/documents?type=wiki`

### Current default contract expectations

- Response remains a top-level JSON array.
- Existing visibility behavior remains unchanged.
- Existing fields consumed by Ship’s wiki list flow remain present.

### Allowed additive contract changes

- Optional `limit`
- Optional `cursor` or `offset`
- Optional summary or field-selection hint if needed for payload reduction

### Non-regression checks

- Existing callers omitting new query parameters still receive a compatible response.
- No field required by current Ship wiki consumers is removed or renamed.
- OpenAPI list schema must match shipped behavior.

## Endpoint: `GET /api/issues`

### Current default contract expectations

- Response remains a top-level JSON array.
- Existing filter semantics remain unchanged.
- Existing ordering remains unchanged:
  - priority bucket ordering
  - `updated_at DESC` within buckets
- `belongs_to` remains available for current web list consumers.

### Allowed additive contract changes

- Optional `limit`
- Optional `cursor` or `offset`
- Optional summary or payload-reduction hint if required to hit targets

### Non-regression checks

- Existing callers omitting new query parameters still receive a compatible response.
- Existing filter semantics and visible issue set do not change.
- Existing Ship consumers still receive the identifiers, associations, and display data they depend on.

## Evidence required before merge

- Route tests covering unchanged default behavior
- OpenAPI schema updates if route behavior and schema are currently out of sync
- Before/after benchmark artifacts under identical seeded conditions
