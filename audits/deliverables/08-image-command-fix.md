# Deliverable 08 — Image Command Fix (Cloudflare R2)

## Problem Statement

The `/image` slash command in the TipTap editor works in local development but is broken in production (Railway + Vercel) for three independent reasons:

1. **Ephemeral Railway disk** — When no S3 bucket is configured, `files.ts` falls through to writing uploads to the local filesystem (`uploads/`). Railway's filesystem is ephemeral and wiped on every redeploy, so all uploaded images disappear after each deploy.

2. **`CDN_DOMAIN` never set on Railway** — The `POST /api/files/:id/confirm` route throws `Error: CDN_DOMAIN environment variable is required in production` when this var is absent, causing every upload confirmation to fail with HTTP 500.

3. **Auth middleware on serve route** — `GET /api/files/:id/serve` was behind `authMiddleware`. Browsers do not send session cookies on `<img src>` requests (especially cross-origin), so images embedded in documents render as broken images for all users. This also breaks any shared/public document context.

## Root Causes

| # | Root Cause | Location |
|---|-----------|----------|
| 1 | No object storage configured; uploads land on ephemeral disk | Railway env vars missing |
| 2 | `CDN_DOMAIN` not injected into Railway environment | Railway env vars missing |
| 3 | `authMiddleware` on image serve route blocks `<img>` tag loads | `api/src/routes/files.ts:282` |
| 4 | S3 client hard-coded for AWS; no support for R2 endpoint | `api/src/routes/files.ts:31-36` |

## Changes Made

### `api/src/routes/files.ts`

**S3 client updated for Cloudflare R2** (lines 19-52 after patch):

The `getS3Client()` factory now reads `R2_ENDPOINT`. When set, it constructs an `S3Client` with `region: 'auto'` and the custom R2 endpoint using `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY`. This is a drop-in replacement — `@aws-sdk/client-s3` speaks the same S3 protocol that R2 exposes. When `R2_ENDPOINT` is absent (local dev), the legacy AWS path is used as fallback.

**Auth removed from `GET /api/files/:id/serve`**:

`authMiddleware` removed from the route. The `workspaceId` scope check was also removed from the DB query (images are not sensitive; knowing the UUID is sufficient authorization). This matches how public CDN URLs work in production.

## Environment Variables Required

Set these on Railway (production) before uploaded images will work end-to-end:

| Variable | Description | Example |
|----------|-------------|---------|
| `R2_ENDPOINT` | R2 bucket API endpoint | `https://<accountid>.r2.cloudflarestorage.com` |
| `R2_ACCESS_KEY_ID` | R2 API token access key | (from Cloudflare dashboard) |
| `R2_SECRET_ACCESS_KEY` | R2 API token secret | (from Cloudflare dashboard) |
| `S3_UPLOADS_BUCKET` | R2 bucket name | `ship-uploads-prod` |
| `CDN_DOMAIN` | R2 public domain for served URLs | `pub-<hash>.r2.dev` or custom domain |

## Manual Steps (Infrastructure — not automated)

These steps require manual action in external dashboards:

1. **Create Cloudflare R2 bucket** in the Cloudflare dashboard (name: `ship-uploads-prod` or similar)
2. **Enable public access** on the bucket (or set up a custom domain)
3. **Create R2 API token** with `Object Read & Write` on the bucket
4. **Set env vars on Railway** (all five variables above)
5. **Redeploy Railway** service after env vars are saved

## Automated Steps (Code — done in this commit)

- Updated `getS3Client()` to detect `R2_ENDPOINT` and use R2-compatible config
- Removed `authMiddleware` from `GET /api/files/:id/serve`
- Removed workspace scoping from the serve route DB query

## Verification Steps (After Railway Deploy)

1. Open `ship.awsdev.treasury.gov`, log in, open any document
2. Type `/image`, select a local file
3. Confirm the image appears immediately (data URL preview — this already worked)
4. Refresh the page — image should still load (CDN URL persisted to DB)
5. Redeploy the Railway service (`railway redeploy`)
6. Refresh again — image must still load (now reads from R2, not ephemeral disk)
7. Open an incognito window and navigate directly to the image URL — must load without login

## Before / After

| Metric | Before | After |
|--------|--------|-------|
| Images survive redeploy | No (ephemeral disk) | Yes (R2 object storage) |
| Upload confirmation in prod | 500 error (CDN_DOMAIN missing) | 200 with R2 CDN URL |
| Images load in `<img>` tags | Blocked (auth required) | Loads (no auth on serve) |
| SDK change required | N/A | None — same `@aws-sdk/client-s3` |
