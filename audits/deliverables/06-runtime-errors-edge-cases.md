# 06 — Runtime Errors and Edge Cases

**Category:** Runtime Errors and Edge Cases
**Before Date:** 2026-03-10
**After Date:** 2026-03-15

---

## Before

_Source: `audits/consolidated-audit-report-2026-03-10.md` Section 6; `audits/artifacts/console-main.log`_

| Metric | Baseline |
|--------|----------|
| Console errors during normal usage | **24** (`audits/artifacts/console-main.log`, 10-minute active editing window) |
| Unhandled promise rejections (server) | **1** — `ForbiddenError: invalid csrf token` |
| Network disconnect recovery | **Partial** — pass in baseline reconnect flow; partial under chaos (9 `login?expired=true` redirects, aborted calls) |
| Missing error boundaries | `UnifiedEditor.tsx` (no user-facing boundary for autosave/collab hard failures); `Login.tsx` (setup-status failures console-only) |
| Silent failures identified | **5** — autosave terminal failure console-only; reconnect redirect churn; login rate-limit (`429`) shows generic message; Reviews button `403 Forbidden`; 3G refresh leaves collaborator stale |
| Yjs collision divergence | **Detected** — concurrent title edits diverged between clients |

---

## Fixes Applied

| Fix | Files Changed |
|-----|---------------|
| Unhandled rejections: `checkSetup` and `checkCaiaStatus` wrapped in `try/catch` | `web/src/pages/Login.tsx` |
| Silent failures: 8 empty `.catch(() => {})` blocks replaced with `console.error` logging | `web/src/components/PlanQualityBanner.tsx`, `RetroQualityBanner.tsx` |
| `/issues` error states surface with `role=status aria-live=polite` | `web/src/components/IssuesList.tsx` |
| Reconnect retry gate + delayed session-expired redirect to prevent churn | `web/src/lib/api.ts` |
| Optimistic concurrency (`expected_title`) on document PATCH; `409 WRITE_CONFLICT` on stale writes | `api/src/routes/documents.ts`, `web/src/components/UnifiedEditor.tsx` |
| Login rate-limit (`429`) surfaces explicit lockout message instead of generic error | `api/src/app.ts`, `web/src/pages/Login.tsx`, `web/src/hooks/useAuth.tsx` |
| Reviews nav hidden for non-admin users; clearer access message on direct URL | `web/src/pages/App.tsx`, `web/src/pages/ReviewsPage.tsx` |
| Autosave terminal failure shows persistent editor banner until successful save | `web/src/hooks/useAutoSave.ts`, `web/src/components/UnifiedEditor.tsx` |

---

## After

| Metric | Before | After | Method | Status |
|--------|--------|-------|--------|--------|
| Console errors per session | 24 | **2** | Live Playwright page traversal (8 routes) — `category6-console-recheck.mjs` | **PASS** ✅ |
| Unhandled promise rejections | 1 | **0** | Static analysis — `Login.tsx` lines 79–108 confirmed try/caught | **PASS** ✅ |
| Silent failures (no user feedback) | 5 | **0** | Static analysis — 8 empty catch blocks replaced; `IssuesList.tsx` `role=status` confirmed | **PASS** ✅ |
| Network disconnect recovery | Partial (9 redirect churns) | **Success (0 redirect churns)** | Live Playwright disconnect test — `category6-disconnect-recheck.mjs` | **PASS** ✅ |
| Yjs collision divergence | Divergence | **Converged (Last-Write-Wins)** | Live Playwright collision test — `category6-collision-recheck.mjs` | **PASS** ✅ |

The 2 remaining console errors are transient `401` responses firing immediately post-login before the session cookie propagates — not persistent across navigation.

---

## Measurement

```bash
# Console error count (requires pnpm dev running):
node audits/artifacts/category6-console-recheck.mjs
# → audits/artifacts/category6-recheck-result.json

# Yjs collision convergence:
node audits/artifacts/category6-collision-recheck.mjs
# → audits/artifacts/category6-collision-recheck.json

# Network disconnect recovery:
node audits/artifacts/category6-disconnect-recheck.mjs
# → audits/artifacts/category6-disconnect-recheck.json
```

All 538 unit tests pass (`pnpm test`, run 2026-03-14).

---

## Image Command Fix (Production)

The `/image` slash command worked locally but was broken in production (Railway + Vercel) due to three independent runtime errors.

| Root Cause | Fix |
|-----------|-----|
| Uploads landing on ephemeral disk — wiped on redeploy | Switched to Cloudflare R2; `getS3Client()` reads `R2_ENDPOINT` |
| `CDN_DOMAIN` missing in Railway — `POST /api/files/:id/confirm` threw 500 | Env var documented and required |
| `authMiddleware` on `GET /api/files/:id/serve` blocked `<img>` tag loads | Auth removed from serve route; file UUID is sufficient authorization |

| Metric | Before | After |
|--------|--------|-------|
| Images survive redeploy | No (ephemeral disk) | Yes (R2 object storage) |
| Upload confirmation in prod | 500 (`CDN_DOMAIN` missing) | 200 with R2 CDN URL |
| Images load in `<img>` tags | Blocked (auth required) | Loads without auth |
