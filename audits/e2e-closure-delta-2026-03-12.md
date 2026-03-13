# E2E Closure Delta Memo (2026-03-12)

## Summary

This memo records the delta between the published March 10 test audit position and the final Layer 2 plus Layer 3 grouped E2E closure evidence completed on 2026-03-12.

It does not replace the historical baseline documents:

- `audits/consolidated-audit-report-2026-03-10.md`
- `audits/test-coverage-quality-audit-2026-03-10.md`

Those documents remain accurate as baseline snapshots. This memo captures what changed after the final grouped Playwright closure work.

## Before vs After

| Claim area | Before (published audit position) | After (2026-03-12 closure evidence) |
| --- | --- | --- |
| Web unit reliability | Web coverage had been repaired to a trustworthy deterministic gate. | Unchanged. `pnpm --filter @ship/web test:coverage -- --reporter=dot` still stood clean at `156/156` on 2026-03-11. |
| Layer 2 reliability slices | Layer 2 targeted E2E slices were closed, but broader E2E publication was still separate work. | Confirmed complete. Layer 2 grouped execution is recorded in `specs/003-improve-test-reliability/quickstart.md` with final clean reruns after documented old-test stabilizations. |
| Broader E2E drift outside targeted slices | The main remaining risk was broader drift outside the remediated reliability slices. | Narrowed materially. Layer 3 Groups 4, 5, 6, and 7 all ended clean on 2026-03-12, covering the previously unconfirmed sprint/accountability, planning/review, issues/program core, and issue/program integration categories. |
| Old-test stabilization status | The audits captured Layer 2 stabilizations and expected further grouped evaluation. | Additional pre-March 9 old-test rationale is now recorded in `ERROR_ANALYSIS.md` for `my-week-stale-data`, `project-weeks`, `weekly-accountability`, and `status-overview-heatmap`. |
| Final Playwright authority source | `test-results/summary.json` was the intended grouped-run reporting surface. | Final Layer 3 authority came from worktree `test-results/.last-run.json` because `summary.json` overcounted retries and preserved stale counters across interrupted runs. |
| Full-suite closure boundary | The audits did not claim a monolithic all-spec Playwright rerun. | Still true. The evidence now supports grouped Layer 2 plus Layer 3 closure across the targeted inventory, but not a single fresh all-spec Playwright run. |

## Updated Closure Evidence

### Layer 2

The March 10 audits already reflected the Layer 2 closure direction. That status is now fully recorded in `specs/003-improve-test-reliability/quickstart.md`, including:

- Group 1 accessibility/error/performance slice closed after isolated `tooltips` stabilization rerun.
- Group 6 collaboration/offline/RBAC slice closed after deterministic helper hardening.
- Group 8 autosave/runtime-resilience/race slice closed after reconnect wait hardening in `e2e/race-conditions.spec.ts`.

### Layer 3

The previously unconfirmed Layer 3 categories are now closed as follows:

- Group 4 sprint/accountability core flows: `40 passed`, `0 failed`, `0 flaky`
- Group 5 sprint planning/team/review flows: passed cleanly on final rerun after old-test stabilization in `e2e/status-overview-heatmap.spec.ts`
- Group 6 issues/program core flows: final rerun `49 passed`, `0 failed`, `0 flaky`
- Group 7 issue/program APIs and integration flows: `71 passed`, `0 failed`, `0 flaky`

Final grouped-run authority came from the following worktree artifacts:

- `../ship-g4/test-results/.last-run.json`
- `../ship-g5/test-results/.last-run.json`
- `../ship-g6b/test-results/.last-run.json`
- `../ship-g7/test-results/.last-run.json`

All four recorded `status: "passed"` on 2026-03-12.

## Old-Test Changes Since The Audit Baseline

The following pre-March 9, 2026 failing or flaky E2E tests required documented test-only changes during closure:

- `e2e/tooltips.spec.ts`
- `e2e/race-conditions.spec.ts`
- `e2e/my-week-stale-data.spec.ts`
- `e2e/project-weeks.spec.ts`
- `e2e/weekly-accountability.spec.ts`
- `e2e/status-overview-heatmap.spec.ts`

The rationale for each change is recorded in `ERROR_ANALYSIS.md`. The pattern across the Layer 3 additions was old-test dependence on grouped-run timing or worker-scoped database state, not confirmed product regressions.

## Current Boundary

The current evidence supports the following claim:

- Layer 2 plus Layer 3 grouped E2E closure is complete for the reliability program documented in `specs/003-improve-test-reliability/quickstart.md`.

The current evidence does not support the stronger claim:

- a single fresh monolithic Playwright rerun of the entire E2E inventory completed cleanly in one command.

Additional known boundary conditions:

- Playwright app-code coverage is still not instrumented.
- The grouped closure relied on `.last-run.json` as the final authority for Layer 3 status where `summary.json` was unreliable under retries.

## Targeted Reliability Follow-Up

Separate before/after artifacts now record the post-audit targeted reliability pass that focused on dark-logic coverage and high-risk fixed-wait cleanup:

- `audits/artifacts/e2e-reliability-before-2026-03-12.md`
- `audits/artifacts/e2e-reliability-after-2026-03-12.md`

That follow-up improved the targeted reliability position, but it does not supersede the boundary above:

- `waitForTimeout(...)` usage across `e2e/*.spec.ts` dropped from `619` at `HEAD` to `537` in the current worktree
- targeted high-risk files in that pass dropped from `8` fixed waits to `0`
- all three dark-logic specs now have grouped runtime evidence:
  - `collaboration-convergence`
  - `offline-replay-exactly-once`
  - `rbac-revocation-collaboration`

So the reliability program is stronger than the original audit position. Broad repo-wide fixed-wait elimination is still not complete, but the targeted dark-logic grouped closure for this pass is now complete.
