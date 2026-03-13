# ADR-002: Pin CI to Node 20 / pnpm v8 until lockfile migration is validated

**Date:** 2026-03-13
**Status:** Accepted
**Deciders:** Ivan

## Context

GitHub Actions deprecated Node 20 runners and will force Node 24 by default from June 2, 2026. The CI workflow uses `actions/checkout@v4`, `pnpm/action-setup@v3` (pnpm 8), and `actions/setup-node@v4` (Node 20). Upgrading to Node 24 + pnpm v9 was attempted but deferred because the current `pnpm-lock.yaml` was generated with pnpm v8 — running `pnpm install --frozen-lockfile` under pnpm v9 may fail due to lockfile format differences.

## Decision

Keep `pnpm/action-setup@v3` (pnpm 8) and `node-version: 20` in `.github/workflows/ci.yml` until the lockfile is explicitly regenerated and validated under pnpm v9 + Node 24.

## Why

The deprecation is a warning, not a hard failure — builds continue to pass. Bumping both pnpm and Node in CI without first regenerating the lockfile locally risks a broken CI with no easy rollback path. The safer upgrade path is: regenerate lockfile locally with pnpm v9 → verify `pnpm install --frozen-lockfile` passes → then bump CI.

## Consequences

**Good:** CI remains stable; no surprise lockfile failures.
**Bad:** Deprecation warning persists in CI logs until migration is done; must be resolved before June 2, 2026.
**Risks:** If GitHub forces Node 24 earlier than announced, CI will break without warning.

## Alternatives Considered

| Option | Why rejected |
|--------|-------------|
| Upgrade to pnpm v9 + Node 24 now | Deferred — lockfile regeneration not yet validated; risk of breaking CI |
| Set `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` env var | Opts into Node 24 without upgrading pnpm; same lockfile risk applies |
| Set `ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION=true` | Suppresses the warning but doesn't fix the underlying version debt |

## Follow-up

Before June 2, 2026:
1. Run `pnpm install` locally with pnpm v9 to regenerate `pnpm-lock.yaml`
2. Verify all tests pass
3. Bump `pnpm/action-setup` to `@v4` with `version: 9` and `node-version` to `24`
4. Update this ADR status to Superseded
