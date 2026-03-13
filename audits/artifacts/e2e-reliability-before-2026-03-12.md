# E2E Reliability Before Snapshot (2026-03-12)

## Scope

This snapshot records the pre-remediation state for the targeted E2E reliability pass focused on:

- dark-logic collaboration scenarios introduced after the March 10 audit
- high-risk `waitForTimeout(...)` cleanup in selected collaboration and auth specs

## Measurement Method

Commands:

```bash
git grep -h -o "waitForTimeout(" HEAD -- 'e2e/*.spec.ts' | wc -l
for f in \
  e2e/admin-workspace-members.spec.ts \
  e2e/session-timeout.spec.ts \
  e2e/content-caching.spec.ts \
  e2e/rbac-revocation-collaboration.spec.ts \
  e2e/offline-replay-exactly-once.spec.ts \
  e2e/collaboration-convergence.spec.ts; do
  git show HEAD:"$f" 2>/dev/null | rg -o "waitForTimeout\\(" -c || true
done
```

## Baseline

- Global `waitForTimeout(...)` count in `e2e/*.spec.ts` at `HEAD`: `619`
- Targeted file counts at `HEAD`:
  - `e2e/admin-workspace-members.spec.ts`: `3`
  - `e2e/session-timeout.spec.ts`: `3`
  - `e2e/content-caching.spec.ts`: `2`
  - `e2e/rbac-revocation-collaboration.spec.ts`: `0`
  - `e2e/offline-replay-exactly-once.spec.ts`: `0`
  - `e2e/collaboration-convergence.spec.ts`: `0`

## Audit Position Before This Pass

From `audits/test-coverage-quality-audit-2026-03-10.md`:

- broad fixed waits remained a P1 flakiness risk
- dark-logic gaps were open for:
  - concurrent same-document edit convergence
  - offline replay exactly-once semantics
  - RBAC revocation during active collaboration
