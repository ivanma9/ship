# Consolidated Audit Report — 2026-03-14

> This report records improvements made on 2026-03-14. The 2026-03-10 report is frozen.

---

## 08 — Image Command Fix (Cloudflare R2)

**Category:** Runtime / Infrastructure
**Status:** Code complete; infrastructure manual steps pending

### Summary

The `/image` slash command was broken in production due to three independent failures:

1. No object storage configured → uploads went to ephemeral Railway disk (lost on redeploy)
2. `CDN_DOMAIN` env var not set on Railway → upload confirmation returned HTTP 500
3. `authMiddleware` on the serve route → `<img>` tags could not load images (browsers do not send cookies on image requests)

### Code Changes (this commit)

- `api/src/routes/files.ts` — Updated `getS3Client()` to detect `R2_ENDPOINT` env var and configure `S3Client` for Cloudflare R2 (`region: 'auto'`, custom endpoint, R2 credentials). Falls back to legacy AWS S3 when `R2_ENDPOINT` is absent.
- `api/src/routes/files.ts` — Removed `authMiddleware` from `GET /api/files/:id/serve`; removed workspace scoping from DB query on that route.

### Manual Steps Remaining

| Step | Owner | Where |
|------|-------|-------|
| Create R2 bucket | Infra | Cloudflare dashboard |
| Create R2 API token | Infra | Cloudflare dashboard |
| Set `R2_ENDPOINT`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `S3_UPLOADS_BUCKET`, `CDN_DOMAIN` | Infra | Railway environment |
| Redeploy Railway service | Infra | Railway dashboard |

### Full Deliverable

See `audits/deliverables/08-image-command-fix.md` for complete before/after analysis and verification steps.
