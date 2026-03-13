# Feature Specification: Query Efficiency for Accountability and Search Flows

**Feature Branch**: `004-optimize-query-flows`  
**Created**: 2026-03-11  
**Status**: Draft  
**Input**: User description: "Feature: Query Efficiency for Accountability and Search Flows Problem: Audited flows use avoidable multi-query patterns with execution overhead. Users: API consumers and platform maintainers. Goal: Reduce query count and execution time in targeted flows. In scope: - Set-based batching in accountability service - Combined SQL search (people + documents) with CTE/UNION while preserving per-source limits - Instrumented validation rerun Out of scope: - Schema redesign beyond needed query/index changes Functional requirements: 1. Reduce Search content flow query count from 5 to 4. 2. Validate execution-time improvement against projected target (~63% for that query family). 3. Preserve response semantics and limits. Non-functional requirements: - Query plans must remain stable under seeded load. Acceptance criteria: - Instrumented rerun confirms query-count and latency improvements with no behavior regressions."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Return Search Results with Less Overhead (Priority: P1)

As an API consumer, I need content search to return the same mix of people and document results with fewer database round trips so responses arrive faster without changing what my integration expects.

**Why this priority**: Search is the directly user-facing flow in scope, and reducing avoidable execution overhead improves the experience for every consumer of that endpoint.

**Independent Test**: Can be fully tested by running the instrumented content search flow against seeded data and confirming the same result semantics and per-source limits are preserved while the flow uses four database queries instead of five.

**Acceptance Scenarios**:

1. **Given** a seeded dataset containing both people and documents that match a search term, **When** a content search is executed, **Then** the response includes the same categories of results and respects the existing per-source limits.
2. **Given** the baseline search flow uses five database queries, **When** the optimized content search flow is measured under the same seeded conditions, **Then** the flow completes using no more than four database queries.
3. **Given** a search term that matches only one source type, **When** the content search is executed, **Then** the response still follows the existing response shape and does not add or omit unexpected result groups.

---

### User Story 2 - Batch Accountability Data Efficiently (Priority: P2)

As a platform maintainer, I need accountability retrieval to process related records in grouped batches so high-volume flows avoid repeated single-record lookups and complete more efficiently under normal load.

**Why this priority**: Accountability work is a targeted source of avoidable query overhead, and reducing that overhead lowers cost and latency for platform-owned operational flows.

**Independent Test**: Can be fully tested by running the accountability flow against seeded data with instrumentation enabled and confirming grouped retrieval reduces redundant query activity while preserving the same returned records.

**Acceptance Scenarios**:

1. **Given** an accountability request covering multiple related records, **When** the flow is executed after this feature is delivered, **Then** it retrieves the required related data without issuing one separate database query per individual record.
2. **Given** the accountability flow returns a known set of records before optimization, **When** the same request is run after optimization, **Then** the returned records, ordering rules, and visible associations remain unchanged.

---

### User Story 3 - Prove the Performance Gain Without Regressions (Priority: P3)

As a platform maintainer, I need an instrumented rerun that compares the updated flows against the baseline so I can confirm the projected latency improvement was achieved and no behavior changed under seeded load.

**Why this priority**: Performance work is only trustworthy when the improvement is measured and paired with evidence that query plans and response behavior remain stable.

**Independent Test**: Can be fully tested by rerunning the agreed instrumented validation on seeded data and confirming query counts, latency, and response behavior meet the expected thresholds with no regressions.

**Acceptance Scenarios**:

1. **Given** a recorded baseline for the targeted search flow, **When** the instrumented rerun is completed after optimization, **Then** the measured execution time for that query family improves by approximately 63% or better under equivalent seeded conditions.
2. **Given** the targeted flows have been optimized, **When** the instrumented rerun examines representative seeded requests, **Then** no behavior regressions are detected in returned results, limits, or associations.
3. **Given** the seeded validation workload is executed repeatedly, **When** maintainers compare the resulting plans and timings, **Then** the query plans remain stable enough to support consistent performance conclusions.

### Edge Cases

- A search term matches fewer results than the per-source limit in one source and more than the limit in the other, requiring the combined search flow to preserve the existing cap behavior for each source independently.
- A search term matches no people and no documents, requiring the optimized flow to return the same empty-result semantics without extra fallback queries.
- An accountability request references related records that are missing or no longer visible, requiring the flow to preserve current omission and visibility behavior while still avoiding repeated lookups.
- Instrumented reruns show faster average latency but materially unstable timings across repeated seeded runs, requiring the feature to fail validation until the variance is understood.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST reduce the content search flow from five database queries to no more than four database queries for the targeted seeded validation scenario.
- **FR-002**: The system MUST preserve the current content search response semantics, including result categories, response shape, ordering rules, and per-source limits.
- **FR-003**: The system MUST preserve correct behavior for searches that return matches from both people and documents, only one of those sources, or neither source.
- **FR-004**: The system MUST retrieve related accountability data for in-scope requests without issuing a separate repeated lookup for each individual related record.
- **FR-005**: The system MUST preserve the current accountability flow results, including which records and associations are returned or omitted under the same access conditions.
- **FR-006**: The system MUST provide an instrumented validation rerun for the targeted search and accountability flows using seeded data that is representative of normal verification load.
- **FR-007**: The instrumented validation rerun MUST demonstrate an execution-time improvement of approximately 63% for the targeted search query family relative to the recorded baseline, or clearly report the measured delta if the projection is not met.
- **FR-008**: The instrumented validation rerun MUST confirm that no behavior regressions were introduced in search results, accountability results, or configured limits.
- **FR-009**: The system MUST demonstrate stable query plans for the targeted optimized flows across repeated seeded validation runs.

### Key Entities *(include if feature involves data)*

- **Content Search Request**: A search operation that returns matching people and documents according to existing limits, ordering, and response shape.
- **Accountability Request**: A retrieval flow that gathers related accountability records and associations for a requested scope.
- **Instrumented Validation Run**: A repeatable seeded execution used to compare baseline and optimized query count, latency, and behavioral outcomes.
- **Seeded Validation Dataset**: The representative set of people, documents, and relationships used to verify performance and behavior remain stable.

## Assumptions

- The existing baseline measurement showing five queries for the targeted content search flow is available and remains the comparison point for acceptance.
- "Approximately 63%" is treated as a target for the targeted search query family and will be considered met when the measured improvement is at least 60% under equivalent seeded conditions.
- Existing result semantics include the current response shape, ordering rules, visibility rules, and per-source limits already relied on by API consumers.
- Seeded validation load already represents the query volume and data distribution needed to judge plan stability for the in-scope flows.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In the agreed seeded validation scenario, the targeted content search flow completes using four database queries instead of the five-query baseline.
- **SC-002**: Under equivalent seeded validation conditions, the targeted search query family shows at least a 60% median execution-time improvement over the recorded baseline.
- **SC-003**: In the post-change instrumented rerun, 100% of validated search and accountability scenarios return the same results, limits, and visible associations as the baseline behavior.
- **SC-004**: Across three repeated seeded validation runs, the targeted optimized flows show consistent query plans with no plan change that causes the measured improvement to fall below the accepted threshold.
