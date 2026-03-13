# ADR-004: Vercel Deployment Lessons and Final Configuration

**Date:** 2026-03-13
**Status:** Accepted
**Deciders:** Ivan Ma

## Context

After deciding to migrate from AWS to Railway + Vercel (ADR-003), we attempted to deploy the frontend via the Vercel CLI in GitHub Actions. This resulted in ~10 failed deploy attempts across multiple PRs. This document records what failed, why, and what the final working configuration is — so we never repeat these mistakes.

## What We Tried (and Why It Failed)

| Attempt | Command / Approach | Error | Root Cause |
|---------|-------------------|-------|------------|
| 1 | `railway up --detach` with `RAILWAY_TOKEN` env var | "No linked project found" | Railway CLI v4 uses `RAILWAY_API_TOKEN`, not `RAILWAY_TOKEN` |
| 2 | `vercel deploy --prod --prebuilt` | "No existing credentials" | Vercel CLI needs `--token` flag, not just `VERCEL_TOKEN` env var |
| 3 | Write `.railway/config.json` + `railway up` | Still "No linked project" | Config JSON format was wrong; Railway CLI v4 ignores env project ID |
| 4 | `vercel build` then `vercel deploy --prebuilt` | `spawn sh ENOENT` | `vercel build` ran the custom install command locally in CI sandbox where `sh` was unavailable |
| 5 | `vercel deploy dist --prod` from `web/` | Path `web/dist/web` not found | Vercel appended `rootDirectory` setting ("web") to our path arg |
| 6 | `vercel deploy web/dist` from repo root | File conflict: `orphan-diagnostic.ts` vs `.sql` | Vercel uploaded entire repo; files with same name but different extensions conflict |
| 7 | `vercel deploy --prod` from repo root with `.vercelignore` | `cd .. && pnpm install` exit 128 | Vercel build sandbox doesn't allow navigating to parent directory |
| 8 | `pnpm install --frozen-lockfile` as Vercel install command | Exit 128 | Corepack attempting to fetch pnpm@10.27.0 fails in Vercel's sandbox |
| 9 | `pnpm install` (without frozen) | Exit 128 | Same corepack issue |
| 10 | **GitHub App integration** (not CLI) | ✓ Worked | Vercel's native GitHub integration handles pnpm/corepack correctly |

## What Actually Worked

**Do not use the Vercel CLI in GitHub Actions to deploy this app.**

Use Vercel's **native GitHub App integration**:
1. Go to vercel.com → New Project → Import from GitHub → select repo
2. Set **Root Directory** to `web`
3. Set **Build Command** to `cd .. && pnpm build:shared && pnpm --filter web build`
4. Set **Install Command** to `cd .. && pnpm install`
5. Set **Output Directory** to `dist`
6. Set env var `VITE_API_URL` to the Railway API URL

Vercel then auto-deploys on every push to `master` — no CI steps needed.

## Railway Lessons

Railway CLI v4 quirks:
- Env var is `RAILWAY_API_TOKEN` (not `RAILWAY_TOKEN`)
- Project linking requires `.railway/config.json` file; env vars alone don't work
- **Easiest approach**: connect service to GitHub repo in Railway dashboard — auto-deploys on push, no CLI needed in CI

Railway Dockerfile requirements for a monorepo:
- Must copy root `tsconfig.json` (shared package extends it): `COPY tsconfig.json ./`
- Must install ALL deps (not `--prod`) before building, then prune after
- `DATABASE_URL` from the Postgres service does **not** auto-link to other services — must be set explicitly as an env var on the web service

## Final Working Architecture

```
Push to master
  ├── Railway: detects push → builds Dockerfile → deploys API
  │     Dockerfile: copies tsconfig.json + source → builds shared + api → prunes to prod
  └── Vercel: detects push → cd .. → pnpm install → pnpm build:shared → pnpm build:web → deploys
```

**GitHub Actions deploy.yml** is now a no-op — both platforms handle deployment natively. The CI workflow (ci.yml) still runs tests/type-checks as a quality gate.

## Environment Variables Required on Railway Web Service

```
DATABASE_URL        # from Postgres service — must be set manually (not auto-linked)
SESSION_SECRET      # random 64-char hex string
CORS_ORIGIN         # Vercel frontend URL
APP_BASE_URL        # Vercel frontend URL
NODE_ENV            # production
```

Note: `AWS_REGION` must NOT be set — its absence triggers the non-AWS config path in `ssm.ts`. CAIA (AWS OAuth) will log a non-fatal warning and skip initialization, which is expected.

## Key Files Changed

| File | What Changed |
|------|-------------|
| `Dockerfile` | Added `tsconfig.json` to COPY; switched to build-inside-Docker (install all deps → build → prune) |
| `api/src/config/ssm.ts` | Added env-var fallback when `AWS_REGION` not set (non-AWS deployments) |
| `.github/workflows/deploy.yml` | Simplified to no-op — both platforms auto-deploy |
| `railway.json` | Added health check config and restart policy |
| `.vercelignore` | Excludes `api/`, `terraform/`, `docs/`, etc. from Vercel uploads |
| `web/.vercel/` | Created by Vercel GitHub App (git-ignored) |
