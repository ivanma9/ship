# Test Reliability Contracts

## 1. Deterministic Web Suite Contract

### Scope

The repaired web unit suite must eliminate the 13 known deterministic failures without removing behavior coverage.

### Required behavior

- Each repaired failure must map to a documented root-cause category and fix pattern.
- The targeted web coverage command must pass in two consecutive reruns with no manual retries.
- Regression assertions must continue to check user-visible or contract-visible behavior rather than implementation-only details.

## 2. High-Risk E2E Synchronization Contract

### Scope

High-risk collaboration-sensitive E2E paths in this feature must not rely on `waitForTimeout` for correctness.

### Required behavior

- Synchronization must wait on observable conditions such as visible UI state, saved/persisted content, blocked permissions, or helper-backed readiness checks.
- Shared retry/wait logic should live in `e2e/fixtures/test-helpers.ts` when reused across multiple specs.
- Test success must not depend on Playwright retries.

## 3. Critical-Flow Scenario Contract

### Scenario A: Concurrent overlap edit convergence

- Two active collaborators make overlapping edits to the same document.
- Both sessions converge on the same final content.
- A persisted reload verifies the shared final state.

### Scenario B: Offline replay exactly once

- A user edits while disconnected.
- On reconnect, the queued changes are applied once and only once.
- A persisted reload verifies there is no duplicate replay.

### Scenario C: RBAC revocation during active collaboration

- A user begins collaborating with valid access.
- Access is revoked during the active session.
- Subsequent protected edits or sync attempts are blocked, and persisted state excludes revoked writes after the revocation point.

## 4. Fixture and Seed Contract

- All data prerequisites for these scenarios must be created in `e2e/fixtures/isolated-env.ts`.
- Tests must fail with explicit assertions if expected fixture counts or records are missing.
- Seed data must be deterministic across workers and use UTC-safe date handling when dates matter.

## 5. Baseline Reporting Contract

- The refreshed baseline must include:
  - web unit pass/fail counts
  - targeted E2E pass/fail/flaky counts
  - web and API coverage percentages
  - delta from the prior published baseline
  - status of the three required critical-flow scenarios
- E2E status must derive from the approved runner workflow and `test-results/summary.json`.
- The publication surface remains the project’s existing audit/reporting artifacts.
