# Quickstart: Test Reliability and Critical-Flow Coverage

## Execution Order

1. Reproduce the web failure baseline with the current web coverage command and record the 13 deterministic failures by root-cause group.
2. Stabilize shared web test setup and fix the failing web test files in place.
3. Add any reusable E2E wait helpers needed in [e2e/fixtures/test-helpers.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/fixtures/test-helpers.ts).
4. Replace fixed-delay waits in the scoped high-risk E2E specs.
5. Extend [e2e/fixtures/isolated-env.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/fixtures/isolated-env.ts) with deterministic seed data for overlap, offline replay, and revocation scenarios.
6. Add the three new critical-flow specs and verify persisted reload behavior in each.
7. Refresh the audit baseline and gating configuration only after the targeted suites pass twice.

## Verification Commands

```bash
pnpm type-check
pnpm --filter @ship/web test:coverage -- --reporter=dot
pnpm --filter @ship/api test:coverage -- --reporter=dot
pnpm exec playwright test e2e/collaboration-convergence.spec.ts e2e/offline-replay-exactly-once.spec.ts e2e/rbac-revocation-collaboration.spec.ts --list
```

For E2E execution, use the repo’s approved runner workflow so progress is monitored through `test-results/summary.json` rather than running `pnpm test:e2e` directly.

## Current Verification Notes

- `pnpm type-check` passed on 2026-03-11.
- `pnpm --filter @ship/web test:coverage -- --reporter=dot` passed on 2026-03-11 with 19/19 files and 156/156 tests passing.
- The refreshed web coverage baseline is 33.93% lines, 22.97% branches, 33.03% statements, and 31.06% functions.
- `pnpm exec playwright test ... --list` confirmed the 3 new critical-flow specs are registered and loadable on 2026-03-11.
- Layer 2 grouped E2E execution was completed on 2026-03-12 across the scoped reliability slices.
- Grouped E2E results on 2026-03-12:
  - Group 1 accessibility/error/performance slice: `127 passed`, `1 flaky`, then isolated stabilization rerun `e2e/tooltips.spec.ts` -> `4 passed`
  - Group 2 auth/security slice: `120 passed`
  - Group 3 workspace/admin slice: `44 passed`
  - Group 4 mentions/comments/uploads/images slice: `44 passed`
  - Group 5 documents/workflows slice: `20 passed`, `2 skipped` (the known intentional `fixme` skips in `e2e/data-integrity.spec.ts`)
  - Group 6 collaboration/offline/RBAC slice: initial `2 failed`, then rerun `3 passed` after deterministic editor-authoring helper hardening
  - Group 7 editor-structure/rendering slice: `75 passed`
  - Group 8 autosave/runtime-resilience/race slice: initial `18 passed`, `1 flaky`, then rerun `19 passed` after reconnect status wait hardening in `e2e/race-conditions.spec.ts`
- The old-test rationale for the two pre-March 9, 2026 E2E stabilizations was recorded in `ERROR_ANALYSIS.md`:
  - `e2e/tooltips.spec.ts`
  - `e2e/race-conditions.spec.ts`
- Layer 3 grouped E2E execution was completed on 2026-03-12 for the previously unconfirmed categories.
- Layer 3 grouped E2E results on 2026-03-12:
  - Group 1 document workflow leftovers: passed cleanly in prior closure work
  - Group 2 collaboration/reconnect leftovers: passed after `/my-week` product fix plus stale-data test hardening
  - Group 3 editor/file leftovers: `11 passed`
  - Group 4 sprint/accountability core flows: `40 passed`, `0 failed`, `0 flaky`
  - Group 5 sprint planning/team/review flows: final rerun passed after old-test heatmap stabilization in `e2e/status-overview-heatmap.spec.ts`
  - Group 6 issues/program core flows: final rerun `49 passed`, `0 failed`, `0 flaky`
  - Group 7 issue/program APIs and integration flows: `71 passed`, `0 failed`, `0 flaky`
- For final Layer 3 reporting, worktree `test-results/.last-run.json` was treated as authoritative when `test-results/summary.json` overcounted retries or preserved stale counters across interrupted runs.
- Additional old-test rationale recorded in `ERROR_ANALYSIS.md` during Layer 3 closure:
  - `e2e/my-week-stale-data.spec.ts`
  - `e2e/project-weeks.spec.ts`
  - `e2e/weekly-accountability.spec.ts`
  - `e2e/status-overview-heatmap.spec.ts`

## Layer 3 Closure Plan

Layer 2 closed the scoped reliability slices, but it did not prove coverage for the remaining unconfirmed categories and partially covered leftovers in the current `877`-test Playwright inventory. Layer 3 is the execution layer for those remaining areas.

### Coverage Gaps After Layer 2

- Fully covered by Layer 2:
  - Auth / authorization / security
  - Accessibility / visual / UI quality
  - Resilience / error handling / performance
- Mostly covered by Layer 2, with leftovers still requiring execution:
  - Document CRUD / workflows:
    - `e2e/backlinks.spec.ts`
    - `e2e/bulk-selection.spec.ts`
    - `e2e/docs-mode.spec.ts`
    - `e2e/wiki-document-properties.spec.ts`
  - Real-time collaboration / sync / race conditions:
    - `e2e/content-caching.spec.ts`
    - `e2e/my-week-stale-data.spec.ts`
    - `e2e/runtime-resilience-reconnect.spec.ts`
  - Editor UX and content features:
    - `e2e/context-menus.spec.ts`
  - Files / media / attachments:
    - `e2e/file-upload-api.spec.ts`
- Not covered by confirmed Layer 2:
  - Sprint / week / accountability workflows
  - Issues / program / project management

### Proposed Layer 3 Groups

1. Group 1: document workflow leftovers

```bash
PLAYWRIGHT_WORKERS=1 pnpm exec playwright test \
  e2e/backlinks.spec.ts \
  e2e/bulk-selection.spec.ts \
  e2e/docs-mode.spec.ts \
  e2e/wiki-document-properties.spec.ts
```

2. Group 2: collaboration and reconnect leftovers

```bash
PLAYWRIGHT_WORKERS=1 pnpm exec playwright test \
  e2e/content-caching.spec.ts \
  e2e/my-week-stale-data.spec.ts \
  e2e/runtime-resilience-reconnect.spec.ts
```

3. Group 3: editor/file leftovers

```bash
PLAYWRIGHT_WORKERS=1 pnpm exec playwright test \
  e2e/context-menus.spec.ts \
  e2e/file-upload-api.spec.ts
```

4. Group 4: sprint and accountability core flows

```bash
PLAYWRIGHT_WORKERS=1 pnpm exec playwright test \
  e2e/weeks.spec.ts \
  e2e/weekly-accountability.spec.ts \
  e2e/project-weeks.spec.ts \
  e2e/accountability-banner-urgency.spec.ts \
  e2e/accountability-owner-change.spec.ts \
  e2e/accountability-standup.spec.ts \
  e2e/accountability-week.spec.ts
```

5. Group 5: sprint planning, team, and review flows

```bash
PLAYWRIGHT_WORKERS=1 pnpm exec playwright test \
  e2e/program-mode-week-ux.spec.ts \
  e2e/pending-invites-allocation.spec.ts \
  e2e/status-overview-heatmap.spec.ts \
  e2e/team-mode.spec.ts \
  e2e/manager-reviews.spec.ts \
  e2e/manager-reviews-visual.spec.ts \
  e2e/feedback-consolidation.spec.ts
```

6. Group 6: issues and programs core flows

```bash
PLAYWRIGHT_WORKERS=1 pnpm exec playwright test \
  e2e/issues.spec.ts \
  e2e/issues-bulk-operations.spec.ts \
  e2e/issue-display-id.spec.ts \
  e2e/issue-estimates.spec.ts \
  e2e/programs.spec.ts
```

7. Group 7: issue/program APIs and integration flows

```bash
PLAYWRIGHT_WORKERS=1 pnpm exec playwright test \
  e2e/ai-analysis-api.spec.ts \
  e2e/changes-requested-notifications.spec.ts \
  e2e/features-real.spec.ts \
  e2e/real-integration.spec.ts \
  e2e/request-changes-api.spec.ts \
  e2e/request-changes-ui.spec.ts \
  e2e/search-api.spec.ts
```

### Layer 3 Reporting Rules

- Report each group with:
  - current group result
  - hard failures vs flaky failures
  - whether any old tests were changed
  - any updates made to `ERROR_ANALYSIS.md`
- If a pre-March 9, 2026 old failing or flaky E2E test is changed after evaluation, record the rationale in `ERROR_ANALYSIS.md`.
- Treat Batch A-E as non-authoritative for coverage closure unless their exact file membership is reconstructed from recorded commands or artifacts.

## Manual Verification Focus

- The previously failing web tests pass consistently in normal suite order.
- Collaboration-sensitive E2E paths advance on observable state, not fixed sleeps.
- Concurrent overlap edits converge after reload.
- Offline edits replay exactly once after reconnect.
- Revoked collaborators lose write capability during an active session and cannot persist post-revocation edits.
- The updated audit baseline clearly shows pass/fail/flaky and coverage deltas from the prior published snapshot.

## Definition of Ready for `/speckit.tasks`

- Root-cause groupings for the 13 web failures are known.
- Target high-risk E2E files for wait replacement are identified.
- Deterministic fixture additions for all three new scenarios are specified.
- Baseline publication files and command outputs to refresh are identified.
