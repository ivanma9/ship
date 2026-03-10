# Test Coverage and Quality Audit (2026-03-10)

## Audit Deliverable


| Metric                            | Your Baseline                                                                                                                                                                                                                              |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Total tests                       | 1,471 (API: 451 + Web: 151 + E2E: 869)                                                                                                                                                                                                     |
| Pass / Fail / Flaky               | 451 / 0 / 0 (pnpm test)                                                                                                                                                                                                                    |
| Suite runtime                     | 20.88 s (pnpm test)                                                                                                                                                                                                                        |
| Critical flows with zero coverage | 1) Concurrent same-document edit convergence with persisted reload verification 2) Offline edit queue replay exactly-once semantics after reconnect 3) RBAC revocation during active collaboration (write rejection + persistence check) |
| Code coverage % (if measured)     | web: 28.53% lines / 19.38% branches / api: 40.52% lines / 33.44% branches (Web measured with `coverage.reportOnFailure=true` while 13 tests fail)                                                                                          |


## 1. Scope and Intent

- Category: Category 5 - Test Coverage and Quality (Playwright E2E emphasis + test instrumentation readiness)
- Repository: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`
- Purpose: establish a trustworthy baseline, identify highest-risk blind spots, and prioritize coverage improvements.
- Assumptions:
  - `pnpm test` is the official baseline command (currently `@ship/api` Vitest tests).
  - E2E audit used Playwright specs/config analysis without executing all 869 E2E tests.
  - Total tests = API + Web + E2E across all suites.
  - This audit is diagnostic only; no remediation changes were made.

## 2. Measurement Method


| Metric                             | Tool / Command                                                             | How Measured                                                                | Limitation                                             |
| ---------------------------------- | -------------------------------------------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------ |
| Baseline determinism               | `for i in 1 2 3; do /usr/bin/time -p pnpm -s test -- --reporter=dot; done` | Compared pass/fail consistency and runtime spread across 3 consecutive runs | API test path only; excludes Playwright E2E            |
| E2E suite size                     | `pnpm exec playwright test --list`                                         | Counted listed tests and spec files                                         | Inventory only; not execution quality                  |
| Critical-flow traceability         | filename mapping + spot checks                                             | Mapped specs to CRUD, Sync, Auth, Sprint flows and looked for dark logic    | Filename intent can over/under represent behavior      |
| Flakiness risk indicators          | `rg -n "waitForTimeout\(" e2e/*.spec.ts`                                   | Flagged fixed-wait usage in high-risk flows                                 | Static indicator only                                  |
| Coverage instrumentation readiness | config inspection + `vitest --coverage` execution                          | Verified provider setup and collected API/Web line+branch baselines         | Web baseline currently includes 13 known failing tests |


## 3. Findings (Ranked)

1. **P1 - Web coverage baseline reliability is constrained by failing web tests**
  - Evidence: coverage now runs, but Web coverage execution still reports 13 test failures.
  - Impact: web line/branch percentages are measurable but reliability is reduced until failing tests are resolved.
  - Scope: `web` unit test suite and web coverage quality gates.
2. **P1 - Real-time sync/concurrency tests are underrepresented**
  - Evidence: only 4 sync-focused specs out of 71 (`autosave-race-conditions`, `content-caching`, `my-week-stale-data`, `race-conditions`).
  - Impact: stale-write, lost-update, and ordering regressions may escape detection.
  - Scope: editor + WebSocket/Yjs collaboration.
3. **P1 - Extensive fixed waits increase flake risk**
  - Evidence: widespread `waitForTimeout(...)` in key specs (`autosave-race-conditions`, `data-integrity`, `drag-handle`, `inline-comments`, etc.).
  - Impact: CI nondeterminism, false failures, and noisy reruns.
  - Scope: multiple E2E feature areas.
4. **P2 - `pnpm test` baseline is deterministic in current environment**
  - Evidence: 3/3 runs clean; stable runtime band.
  - Impact: good confidence for API regression checks.
5. **P2 - Web unit suite currently has deterministic failures**
  - Evidence: `pnpm --filter @ship/web test -- --coverage --run --reporter=dot` reported 13 failed tests.
  - Impact: weak web test signal and reduced confidence in web coverage quality.

## 4. Critical-Flow Traceability


| Flow              | Mapped E2E Coverage                                                                                               | Signal      |
| ----------------- | ----------------------------------------------------------------------------------------------------------------- | ----------- |
| CRUD              | 11 mapped files (`documents`, `document-workflows`, `issues`, `wiki-document-properties`, `bulk-selection`, etc.) | Strong      |
| Real-time Sync    | 4 mapped files (`autosave-race-conditions`, `content-caching`, `my-week-stale-data`, `race-conditions`)           | Medium-Weak |
| Auth / RBAC       | 8 mapped files (`auth`, `authorization`, `session-timeout`, `security`, `admin-workspace-members`, etc.)          | Strong      |
| Sprint Management | 12 mapped files (`weeks`, `weekly-accountability`, `accountability-`*, `manager-reviews`*, `project-weeks`, etc.) | Strong      |


## 5. Highest-Risk Dark Logic Gaps

1. **Concurrent same-document edit convergence**
  - Missing explicit two-user overlapping edit assertions with persisted reload verification.
  - Needed checks: both markers visible in both sessions, stable order after reload, merged content persisted server-side.
2. **Offline edit queue replay exactly-once semantics**
  - Missing explicit validation that reconnect replay does not duplicate operations.
  - Needed checks: each offline edit appears exactly once, save status converges, expected revision progression, reload parity.
3. **RBAC revocation during active collaboration**
  - Missing explicit mid-session permission revocation write-block test.
  - Needed checks: write attempts rejected (UI + 403), no unauthorized persisted changes, revoked session remains denied on reload.

## 6. Coverage Instrumentation and Reporting Status

- Attempted commands:
  - `pnpm --filter @ship/api test:coverage -- --reporter=dot`
  - `pnpm --filter @ship/web test:coverage -- --reporter=dot`
  - `pnpm --filter @ship/web exec vitest run --coverage --reporter=dot --coverage.reportOnFailure=true`
- Coverage runtime status:
  - Operational for both packages (`Coverage enabled with v8`).
- Current caveat:
  - Web run has 13 failing tests; used `coverage.reportOnFailure=true` to emit numeric coverage anyway.
- `api/vitest.config.ts` and `web/vitest.config.ts` now both use `coverage.provider: 'v8'`.
- Playwright is not currently configured to emit app code coverage artifacts.
- To produce E2E coverage metrics, the app needs instrumentation (for example Istanbul) plus a merge/report pipeline.

## 7. Execution and Flakiness Snapshot (`pnpm test`)

1. Run 1: pass (451/451), 20.57s
2. Run 2: pass (451/451), 22.08s
3. Run 3: pass (451/451), 19.99s

Flaky tests observed in this command path: **0**.

## 8. Improvement Target and Plan

- Coverage unlock goal:
  - Keep runnable coverage active in `api` and `web` and improve both line/branch baselines over time.
- Reliability goal:
  - Resolve the current 13 deterministic Web unit test failures, then re-run Web coverage without `coverage.reportOnFailure=true`.
  - Replace fixed-wait patterns (`waitForTimeout`) in high-risk E2E specs with event/assertion-based waits.
  - Track flaky rate with repeated baseline runs and record trend in this report.
- Flow goal:
  - Add 3 E2E scenarios for current dark logic gaps:
    - concurrent same-document overlap edit convergence,
    - offline edit replay exactly-once,
    - RBAC revocation during active collaboration.
- Reporting goal:
  - Re-run audit after coverage/runtime fixes and update Section 9 with numeric coverage percentages and refreshed Pass/Fail/Flaky/runtime baselines.

## 9. Residual Risk Summary

- Highest risk: collaboration correctness during concurrent edits, reconnects, and permission transitions.
- Confidence: medium-high for measured baselines; medium for dark-logic inference (mapping + config analysis).
- Blind spots:
  - No CI-history flake-rate sampling in this audit.
  - Web coverage percentages are currently sampled with failing tests present; treat as provisional until web suite is stabilized.

## 10. Audit Boundary Reminder

- This report is diagnosis only.
- No fixes were implemented during this audit.

