# ADR-002: Upgrade CI to pnpm v9 / Node 24

**Date:** 2026-03-13
**Status:** Accepted
**Deciders:** Ivan

## Context

CI was using `pnpm/action-setup@v3` (pnpm 8) and `node-version: 20`. The build failed with `ERR_PNPM_UNSUPPORTED_ENGINE` because `package.json` already specifies `engines.pnpm: >=9.0.0`. Additionally, GitHub Actions deprecated Node 20 runners, forcing Node 24 by default from June 2, 2026.

## Decision

Upgrade CI to `pnpm/action-setup@v4` (pnpm 9) and keep `node-version: 20` for now (Node 24 upgrade deferred — no breaking need yet, only a deprecation warning).

## Why

The pnpm upgrade is non-optional — the project's `engines.pnpm` field hard-requires v9 and CI was failing. Node 24 is a deprecation warning only; deferring avoids churn until there's a functional need.

## Consequences

**Good:** CI passes. Unblocks all future PRs.
**Bad:** Node 20 deprecation warning persists until Node 24 is adopted.
**Risks:** Node 24 becomes mandatory on June 2, 2026 — must upgrade before then.

## Alternatives Considered

| Option | Why rejected |
|--------|-------------|
| Keep pnpm v8 | Hard failure — `engines.pnpm >=9.0.0` enforced by pnpm itself |
| Upgrade to Node 24 now | Deprecation warning only, no functional failure; deferred to reduce scope |

## Follow-up

Before June 2, 2026: bump `node-version` to `24` in ci.yml and verify tests pass.
