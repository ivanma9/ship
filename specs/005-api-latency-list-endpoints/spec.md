# Feature Specification: API Latency Improvement for List Endpoints

**Feature Branch**: `005-api-latency-list-endpoints`  
**Created**: 2026-03-12  
**Status**: Approved  
**Input**: User description: "Use the approved API Latency Improvement for List Endpoints spec and produce an implementation plan. Focus on `/api/documents?type=wiki` (`123ms -> <=98ms P95`) and `/api/issues` (`105ms -> <=84ms P95`). Sequence work after DB-efficiency/index prerequisites are in place. Plan payload-size reductions, query/index leverage, and fallback pagination/default limits. Define benchmark protocol using identical seeded volume and c10/c25/c50 matrix. Specify before/after evidence format and acceptance gates. Provide touched files/modules, API contract checks, test coverage, rollout/rollback, risks, and definition of done. Constraints: no response-contract regressions; keep benchmark conditions consistent across baseline and validation runs; use existing Ship stack and patterns."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Faster Wiki List Loads Without Contract Breakage (Priority: P1)

As a Ship user opening the documents area, I need the wiki list endpoint to return faster under representative concurrency so the documents experience feels immediate without changing the response shape my current UI depends on.

**Why this priority**: `/api/documents?type=wiki` is the slowest audited list endpoint and one of the two required acceptance targets.

**Independent Test**: Can be fully tested by benchmarking the wiki list endpoint against the approved seeded dataset at `c10`, `c25`, and `c50`, then confirming the response contract remains compatible with existing document-list consumers.

**Acceptance Scenarios**:

1. **Given** the approved seeded benchmark dataset and authenticated benchmark workflow, **When** `/api/documents?type=wiki` is rerun after the feature changes, **Then** its `c50` P95 latency is `<= 98 ms`.
2. **Given** an existing wiki-list client, **When** it requests `/api/documents?type=wiki` without any new optional query parameters, **Then** it still receives the same response contract and visible wiki set as before.
3. **Given** additive payload-reduction options or default-list guards are introduced, **When** a caller does not opt into the additive options, **Then** no existing response fields required by current Ship clients are removed or renamed.

---

### User Story 2 - Faster Issue List Loads With Current Filters Preserved (Priority: P1)

As a Ship user viewing issue lists and boards, I need `/api/issues` to return faster under representative concurrency so issue workflows stay responsive while preserving the current filters, ordering rules, and association data.

**Why this priority**: `/api/issues` is the second required audited target, and the issue list powers multiple core surfaces in the web app.

**Independent Test**: Can be fully tested by benchmarking `/api/issues` against the same seeded dataset and by running regression tests for state, assignee, sprint, and association-driven filtering.

**Acceptance Scenarios**:

1. **Given** the approved seeded benchmark dataset and authenticated benchmark workflow, **When** `/api/issues` is rerun after the feature changes, **Then** its `c50` P95 latency is `<= 84 ms`.
2. **Given** the existing issue list filters for `state`, `priority`, `assignee_id`, `program_id`, `sprint_id`, `source`, and `parent_filter`, **When** clients use them after the feature changes, **Then** the visible issue set and ordering remain unchanged.
3. **Given** issue associations are still needed by current UI consumers, **When** `/api/issues` returns optimized results, **Then** `belongs_to`, `ticket_number`, and current list sorting semantics are preserved.

---

### User Story 3 - Measured Improvement Under Stable Benchmark Conditions (Priority: P2)

As a reviewer or maintainer, I need before-and-after evidence captured under identical conditions so I can verify that latency gains came from the planned changes rather than benchmark drift.

**Why this priority**: This is performance work, so acceptance depends on reproducible evidence and on preserving the DB-efficiency prerequisite ordering from the audit-remediation roadmap.

**Independent Test**: Can be fully tested by replaying the same seeded benchmark matrix and confirming the before/after artifacts, environment metadata, and acceptance gates match exactly.

**Acceptance Scenarios**:

1. **Given** the approved benchmark baseline in `audits/api-response-time.md`, **When** post-change validation runs, **Then** it uses the same seeded data volume, authenticated setup, concurrency matrix, and measurement format.
2. **Given** the list endpoint work depends on query/index prerequisites, **When** the feature is reviewed for completion, **Then** query-plan and index evidence already exist for the affected list queries before final latency sign-off.
3. **Given** benchmark evidence is published, **When** reviewers compare before and after artifacts, **Then** each endpoint shows baseline metrics, post-change metrics, delta, and pass/fail status for the accepted targets.

### Edge Cases

- If targeted indexes are added but planner choice becomes unstable across repeated seeded runs, the feature fails validation until the plan shape is understood and stabilized.
- If payload reduction requires additive query parameters or summary-mode behavior, the existing unparameterized contract must remain compatible for current callers.
- If default limits are introduced as a fallback to hit the latency target, Ship web clients must explicitly request the required page size so no existing list view silently loses visible rows.
- If DB-efficiency work affecting the same queries changes after baseline capture, latency benchmarks must be rerun before the feature can exit.
- If benchmark runs produce non-2xx responses or rate-limit contamination, the run is invalid and cannot be used as evidence.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST improve `/api/documents?type=wiki` so its post-change `c50` P95 latency is `<= 98 ms` under the approved seeded benchmark conditions.
- **FR-002**: The system MUST improve `/api/issues` so its post-change `c50` P95 latency is `<= 84 ms` under the approved seeded benchmark conditions.
- **FR-003**: The system MUST preserve the current response contracts for existing callers of `/api/documents?type=wiki` and `/api/issues`; any new optimization parameters MUST be additive and optional.
- **FR-004**: The system MUST sequence endpoint-level latency changes only after the relevant query-plan and index prerequisite work has been reviewed for the affected list queries.
- **FR-005**: The system MUST reduce request-path cost using a combination of payload-size reduction, query/index leverage, and request bounding within the existing Ship stack and patterns.
- **FR-006**: The system MUST keep benchmark conditions identical across baseline and validation runs, including seeded data volume, authentication approach, local API target, and concurrency matrix `c10/c25/c50`.
- **FR-007**: The system MUST produce durable before-and-after evidence for both targeted endpoints showing P50, P95, and P99 results, plus pass/fail status against the approved targets.
- **FR-008**: The system MUST define contract checks that prove existing list filters, ordering, visibility, and association semantics remain intact after optimization.
- **FR-009**: The system MUST define fallback pagination or default-limit behavior that can be used if payload and index changes alone miss the latency targets, without silently regressing current web behavior.
- **FR-010**: The system MUST identify rollout and rollback steps for API changes, any web hook adjustments, and any performance-related database migration.

### Key Entities *(include if feature involves data)*

- **Wiki List Request**: A request to `/api/documents?type=wiki` including current visibility and parent filters plus any future additive optimization parameters.
- **Issue List Request**: A request to `/api/issues` including current filter semantics plus any future additive optimization parameters.
- **List Response Contract**: The set of fields, ordering, visibility behavior, and association semantics currently relied on by Ship clients for each endpoint.
- **Benchmark Run**: One authenticated benchmark execution over the seeded dataset for a specific endpoint and concurrency level.
- **Latency Evidence Package**: The durable before/after artifact set containing environment metadata, benchmark results, deltas, and acceptance status.
- **Index Decision**: The documented outcome for whether existing indexes are sufficient or a narrow new migration is required for stable target attainment.

## Assumptions

- The approved API latency baseline is the March 10, 2026 audit in `audits/api-response-time.md` and the corresponding section in `audits/consolidated-audit-report-2026-03-10.md`.
- Database-query-efficiency remains the prerequisite category for this work, per `specs/001-order-audit-remediation/spec.md`.
- The representative seeded dataset remains: 572 documents, 104 issues, 26 users, and 35 sprints.
- Existing Ship web clients for these routes can be updated to send additive query parameters if needed, but existing route behavior without those parameters must remain contract-compatible.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `/api/documents?type=wiki` achieves `<= 98 ms` P95 at `c50` under the approved seeded benchmark conditions.
- **SC-002**: `/api/issues` achieves `<= 84 ms` P95 at `c50` under the approved seeded benchmark conditions.
- **SC-003**: For both endpoints, before and after evidence is captured with the same seeded volume, authenticated setup, benchmark matrix, and measurement format.
- **SC-004**: Regression coverage demonstrates that existing visibility, filtering, ordering, and association semantics remain unchanged for the optimized endpoints.
- **SC-005**: Any added database migration is narrowly scoped to the targeted list-query access patterns and has explicit rollback instructions.
