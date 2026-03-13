# Phase 0 Research: Test Reliability and Critical-Flow Coverage

## Decision 1: Repair deterministic web failures by removing shared-state and async leakage, not by weakening assertions

**Decision**: Fix the 13 deterministic web unit failures by stabilizing test setup, cleanup, timer control, mock reset, and async observation boundaries inside the current Vitest suite.

**Rationale**: The audit already shows these failures are deterministic, which means the suite is currently signaling a real repeatable defect in the test harness, the test itself, or the covered behavior. Preserving confidence requires removing the determinism source rather than muting it with retries, skips, or broader assertions.

**Alternatives considered**:

- Add retries or `test.retry`: rejected because deterministic failures should never require reruns.
- Mark tests flaky or skipped: rejected because the feature goal is to restore trustworthy signal, not hide failures.
- Replace the test framework: rejected by feature constraints.

## Decision 2: Replace `waitForTimeout` in high-risk E2E with observable-state waits and reusable helpers

**Decision**: For the scoped high-risk E2E files, replace sleep-based waits with explicit assertions, `toPass`, DOM-stability helpers, page/network readiness checks, and persisted reload verification.

**Rationale**: The repo already documents this as the preferred pattern in [e2e/AGENTS.md](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/AGENTS.md), and the current helper module already provides retryable primitives. Extending that approach keeps timing logic centralized and reduces repeated brittle inline waits.

**Alternatives considered**:

- Increase `waitForTimeout` durations: rejected because longer sleeps still guess timing and slow the suite.
- Depend on Playwright retries only: rejected because retries diagnose instability but do not make the test logic deterministic.
- Convert all E2E files in one pass: rejected because the feature scope is only the highest-risk paths.

**Scoped target list captured for this feature**:

- `e2e/autosave-race-conditions.spec.ts`
- `e2e/race-conditions.spec.ts`
- `e2e/security.spec.ts`
- `e2e/data-integrity.spec.ts`
- `e2e/runtime-resilience-autosave.spec.ts`
- `e2e/runtime-resilience-reconnect.spec.ts`

## Decision 3: Seed all new critical-flow prerequisites through `e2e/fixtures/isolated-env.ts`

**Decision**: Put the full collaboration, offline, and RBAC prerequisites for the three new scenarios into the isolated worker fixture so every worker receives deterministic users, roles, documents, associations, and content state.

**Rationale**: The repository’s E2E guidance explicitly requires seed-data needs to be handled in `isolated-env.ts`, not inside individual tests or by conditional skips. Centralizing seed creation keeps scenario files focused on behavior and prevents hidden divergence across tests.

**Alternatives considered**:

- Insert data ad hoc inside each spec: rejected because it duplicates setup logic and makes failures harder to reason about.
- Use `test.skip()` when data is missing: rejected because the repo forbids silent skipping for missing fixture coverage.
- Reuse mutable shared records across scenarios: rejected because worker isolation and deterministic replay are required.

## Decision 4: Keep baseline reporting in the current audit and progress-reporting surfaces

**Decision**: Publish refreshed quality baselines by rerunning the existing coverage commands, collecting E2E runner results from `test-results/summary.json`, and updating the consolidated audit report with pass/fail/flaky and coverage deltas.

**Rationale**: The audit already contains the March 10, 2026 baseline and explicitly calls for these reliability and coverage improvements. Reusing that artifact provides a before/after comparison without adding a new reporting system.

**Alternatives considered**:

- Build a new dashboard or metrics pipeline: rejected because reporting refresh is in scope, but framework/tool replacement is out of scope.
- Store baseline notes only in PR text: rejected because the requirement calls for a published updated baseline.

## Decision 5: Tighten gates around the repaired command set, not around new tooling

**Decision**: CI/pre-merge updates should rely on the existing type-check, web coverage, empty-test guard, API coverage guard, approved E2E runner workflow, and Playwright summary outputs.

**Rationale**: The repo already has working hooks and progress reporting. The missing ingredient is trustworthy targeted coverage and deterministic evidence, not another layer of tooling.

**Alternatives considered**:

- Add a new test orchestrator or flaky-test service: rejected because it violates the constraint against framework replacement.
- Gate on the entire E2E suite for this feature: rejected because the approved workflow is designed to run scoped E2E work without output explosion.

## Decision 6: Emit explicit flaky counters in the existing Playwright summary artifact

**Decision**: Extend `e2e/progress-reporter.ts` and `scripts/watch-tests.sh` so the approved runner workflow records `flaky` and `retried` counters in `test-results/summary.json` rather than inferring them from ad hoc console output.

**Rationale**: The feature requires refreshed pass/fail/flaky baselines. The current summary artifact already exists and is the least disruptive place to make those counters durable and machine-readable.

**Alternatives considered**:

- Publish flaky counts only in human-written audit notes: rejected because it is easy to drift from the actual rerun output.
- Add a second reporting file just for flaky counts: rejected because the existing summary artifact already serves the runner workflow.
