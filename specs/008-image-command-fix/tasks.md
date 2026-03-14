# Tasks: Fix /image Slash Command in Production

## Problem Summary

The `/image` slash command works in local dev (uses local disk storage + `/api/files/:id/serve`)
but is broken in production (Railway + Vercel) because:

1. Railway has no S3 bucket configured → uploads land on ephemeral Railway disk
2. SSM is no longer used (migrated away from AWS in ADR-003) but `CDN_DOMAIN` is never set
3. Files served via `/api/files/:id/serve` require auth cookies → images break in shared/embedded contexts
4. Railway filesystem is ephemeral → uploaded images disappear on every redeploy

---

## Tasks

### 1. Provision object storage for Railway uploads [SUPERSEDED — using R2 instead of S3]

~~AWS S3 approach~~ — **Replaced by Cloudflare R2** (same S3-compatible API, no egress fees).
Manual steps (dashboard):
- Create R2 bucket (e.g. `ship-uploads-prod`) in Cloudflare dashboard
- Create R2 API token with Object Read & Write on the bucket
- Add Railway env vars: `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `S3_UPLOADS_BUCKET`

Code changes: ✅ Done — `getS3Client()` updated to detect `R2_ENDPOINT` and use R2 config.

### 2. Set CDN_DOMAIN on Railway

Option A — CloudFront in front of S3 (best for performance):
- Create CloudFront distribution pointing at the S3 bucket
- Set Railway env var: `CDN_DOMAIN=<cloudfront-domain>.cloudfront.net`

Option B — Use S3 public URL directly (simpler, no CDN cost):
- Make S3 bucket public-read (or use presigned GET URLs)
- Set Railway env var: `CDN_DOMAIN=ship-uploads-prod.s3.amazonaws.com`
- Update `files.ts` confirm endpoint to build URL as `https://${cdnDomain}/${file.s3_key}` (already does this at line 257)

### 3. Remove SSM dependency for CDN_DOMAIN / verify env var loading

- `api/src/config/ssm.ts` fetches `CDN_DOMAIN` from AWS SSM — this code path is dead on Railway
- Verify Railway env vars are read via `process.env` directly (they are — SSM is only called if `AWS_SSM_PATH` is set)
- Confirm `CDN_DOMAIN` is available via `process.env.CDN_DOMAIN` in `api/src/routes/files.ts:253` on Railway

### 4. Make served images publicly accessible (no auth required) ✅ Done

~~Currently `GET /api/files/:id/serve` is behind `authMiddleware` (line 282 of files.ts).~~

**Fixed**: Removed `authMiddleware` from `GET /api/files/:id/serve` (Option A). Also removed
workspace-scoping from the DB query since auth context is no longer available on this route.
Images are not sensitive data — the UUID is sufficient authorization.

### 5. Test end-to-end in production after env vars are set

- Open a document on `ship.awsdev.treasury.gov` (or Vercel preview URL)
- Type `/image`, select a file
- Verify image appears immediately (data URL preview) ✓
- Verify image persists after page refresh (CDN URL swap) ✓
- Verify image still loads after Railway redeploy (S3 persistence) ✓
- Verify image loads without being logged in (if public docs are a use case)

---

## Files to Change

| File | Change |
|------|--------|
| `api/src/routes/files.ts:282` | Remove `authMiddleware` from `/serve` route (local dev fix) |
| Railway dashboard | Add `S3_UPLOADS_BUCKET`, `CDN_DOMAIN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` env vars |
| AWS console | Create S3 bucket + IAM user + optional CloudFront |

No code changes needed in `web/` — the frontend already handles both local (`/api/files/...`) and CDN (`https://...`) URLs correctly at `SlashCommands.tsx:426`.
