# Data Model: Test Reliability and Critical-Flow Coverage

## Entities

### 1. Deterministic Failure Group

**Purpose**: Represents one or more currently failing web unit tests that share the same repeatable failure mode and fix strategy.

**Fields**

- `group_id`: Stable label for the failure group
- `test_files`: List of affected web test files
- `failure_signature`: Repeatable assertion or runtime failure pattern
- `root_cause_category`: Shared-state leakage, async timing, missing cleanup, environment assumption, or real product defect
- `fix_strategy`: Exact stabilization approach used for the group
- `resolved_in_run`: Baseline rerun where the group first passed cleanly

**Validation rules**

- Every one of the 13 deterministic failures must belong to exactly one group
- Each group must have a documented root cause and fix strategy
- A group is only `resolved` after two consecutive clean reruns

**State transitions**

- `identified` -> `triaged`
- `triaged` -> `fixed`
- `fixed` -> `verified`

### 2. High-Risk Wait Replacement

**Purpose**: Represents a scoped replacement of fixed-delay synchronization in a high-risk E2E path.

**Fields**

- `spec_file`: E2E file being updated
- `interaction_step`: The prior fixed-wait step being replaced
- `observable_condition`: The new assertion, readiness signal, or helper condition
- `helper_dependency`: Shared helper used or added for the replacement
- `risk_area`: Autosave, collaboration convergence, reconnect, or access control

**Validation rules**

- Each replacement must point to an observable condition, not another fixed delay
- High-risk replacements must remain deterministic under isolated worker execution
- Helper-backed replacements should be reused when more than one spec needs the same pattern

**State transitions**

- `identified` -> `replaced`
- `replaced` -> `verified`

### 3. Critical-Flow Scenario

**Purpose**: Represents one of the three required end-to-end collaboration scenarios added by this feature.

**Fields**

- `scenario_id`: `concurrent_overlap`, `offline_replay_exactly_once`, or `rbac_revocation_active_collaboration`
- `seed_bundle`: Required users, roles, documents, associations, and initial content
- `actors`: Users or sessions participating in the scenario
- `live_assertions`: In-session behavior checks
- `persisted_assertions`: Reloaded or server-authoritative checks after the live flow
- `status`: Planned, implemented, verified

**Validation rules**

- Every scenario must have deterministic fixture prerequisites in `isolated-env.ts`
- Every scenario must verify both live-session behavior and persisted post-refresh state
- Missing fixture prerequisites must fail with explicit assertions, not skips

**State transitions**

- `planned` -> `implemented`
- `implemented` -> `verified`

### 4. Fixture Seed Bundle

**Purpose**: Represents the explicit deterministic test data required for targeted high-risk E2E execution.

**Fields**

- `workspace`
- `users`
- `memberships`
- `documents`
- `document_associations`
- `role_changes`
- `initial_editor_content`

**Validation rules**

- Dates must use deterministic UTC-safe values
- Seed bundle must contain at least the minimum collaborator count needed by the scenario plus buffer records where row-count expectations exist
- Seed creation must be centralized in the worker fixture, not duplicated across specs

### 5. Quality Baseline Snapshot

**Purpose**: Represents the published after-rerun evidence used by engineers and release managers.

**Fields**

- `snapshot_date`
- `web_unit_pass_count`
- `web_unit_fail_count`
- `targeted_e2e_pass_count`
- `targeted_e2e_fail_count`
- `targeted_e2e_flaky_count`
- `web_coverage_lines`
- `web_coverage_branches`
- `api_coverage_lines`
- `api_coverage_branches`
- `critical_flow_coverage_status`
- `delta_from_prior_baseline`

**Validation rules**

- Counts must derive from rerun outputs, not estimates
- Deltas must compare against the prior published baseline
- Snapshot publication requires the targeted command set to pass twice

## Relationships

- A `Deterministic Failure Group` can affect multiple web test files but maps to one root-cause category.
- A `High-Risk Wait Replacement` may support one or more `Critical-Flow Scenario` checks by adding reusable helper logic.
- A `Fixture Seed Bundle` is consumed by one or more `Critical-Flow Scenario` runs.
- A `Quality Baseline Snapshot` summarizes the final verified state of all failure groups, wait replacements, and critical-flow scenarios.

## Non-Goals

- No new production persistence model is introduced.
- No new global test framework or reporting platform is introduced.
- No broad conversion of every `waitForTimeout` in the repository is planned in this feature.
