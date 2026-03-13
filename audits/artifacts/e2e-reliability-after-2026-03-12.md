# E2E Reliability After Snapshot (2026-03-12)

## Scope

This snapshot records the post-remediation state for the targeted E2E reliability pass focused on:

- runtime verification of the dark-logic collaboration specs
- high-risk `waitForTimeout(...)` cleanup in selected collaboration and auth specs

## Measurement Method

Commands:

```bash
rg -o "waitForTimeout\\(" e2e/*.spec.ts | wc -l
for f in \
  e2e/admin-workspace-members.spec.ts \
  e2e/session-timeout.spec.ts \
  e2e/content-caching.spec.ts \
  e2e/rbac-revocation-collaboration.spec.ts \
  e2e/offline-replay-exactly-once.spec.ts \
  e2e/collaboration-convergence.spec.ts; do
  rg -o "waitForTimeout\\(" -c "$f" || true
done

PLAYWRIGHT_WORKERS=1 pnpm exec playwright test \
  e2e/collaboration-convergence.spec.ts \
  e2e/offline-replay-exactly-once.spec.ts \
  e2e/rbac-revocation-collaboration.spec.ts \
  --project=chromium --reporter=line
```

## Results

- Global `waitForTimeout(...)` count in `e2e/*.spec.ts`: `537`
- Net reduction versus `HEAD`: `-82`
- Targeted file counts after this pass:
  - `e2e/admin-workspace-members.spec.ts`: `0`
  - `e2e/session-timeout.spec.ts`: `0`
  - `e2e/content-caching.spec.ts`: `0`
  - `e2e/rbac-revocation-collaboration.spec.ts`: `0`
  - `e2e/offline-replay-exactly-once.spec.ts`: `0`
  - `e2e/collaboration-convergence.spec.ts`: `0`
- Reduction in the explicitly targeted files: `8 -> 0`

## Runtime Evidence

Grouped dark-logic run:

- command: `PLAYWRIGHT_WORKERS=1 pnpm exec playwright test e2e/collaboration-convergence.spec.ts e2e/offline-replay-exactly-once.spec.ts e2e/rbac-revocation-collaboration.spec.ts --project=chromium --reporter=line`
- outcome: `3 passed (44.4s)`
- grouped runtime passes:
  - `e2e/collaboration-convergence.spec.ts`
  - `e2e/offline-replay-exactly-once.spec.ts`
  - `e2e/rbac-revocation-collaboration.spec.ts` retried under grouped low-memory execution
  - `e2e/rbac-revocation-collaboration.spec.ts`

## Interpretation

- The concurrent convergence, offline replay, and RBAC revocation dark-logic gaps now have runtime-verified targeted coverage.
- The fixed-wait cleanup is materially improved in the targeted high-risk specs, but broad repo-wide E2E wait cleanup remains open.
