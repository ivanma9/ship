# 02 — Bundle Size

**Category:** Frontend Production Bundle Size
**Before Date:** 2026-03-09
**After Date:** 2026-03-13
**Sources:** `audits/bundle-size-audit-2026-03-09.md`, `audits/bundle-size-audit-after-006.md`

**How to Reproduce:**
```bash
pnpm build
node web/scripts/check-bundle-budget.mjs
# Output: PASS/FAIL with gzip size vs 275 KB budget
```

Bundle size was measured by summing exact byte sizes of all files in `web/dist/index.html` and `web/dist/assets/*` after a production `pnpm build`. Entry chunk gzip size was measured by the `web/scripts/check-bundle-budget.mjs` script using Node's `zlib.gzipSync`. The optimization work is on branch `006-bundle-size-reduction`.

---

## Before

_Source: `audits/bundle-size-audit-2026-03-09.md`, Section 3_

| Metric | Value |
|--------|-------|
| Total production payload | 2,321,505 bytes (2,267.09 KB, **2.21 MB**) |
| Largest entry chunk (raw) | `index-C2vAyoQ1.js` — 2,073.70 KB minified |
| Entry chunk gzip | **587.59 KB** |
| Emitted JS files | 263 |
| Dominant chunk share | 94.90% (`index-C2vAyoQ1.js`) |

### Before — Top Dependencies (Visualizer Rendered Size)

| Rank | Dependency | Rendered Size | Location |
|------|------------|--------------|----------|
| 1 | `emoji-picker-react` | 399.60 KB | Bundled into entry chunk |
| 2 | `highlight.js` | 377.94 KB | Bundled into entry chunk |
| 3 | `yjs` | 264.93 KB | Bundled into entry chunk |

---

## After

_Source: `audits/bundle-size-audit-after-006.md`, Sections 3–4_

| Metric | Value |
|--------|-------|
| Total production payload | 3,441,011 bytes (3,360.36 KB, **3.28 MB**) |
| Largest entry chunk (raw) | `index-*.js` — 977.87 KB minified |
| Entry chunk gzip (Vite) | **266.21 KB** (−54.7%) |
| Entry chunk gzip (budget script) | **259.97 KB** (−55.8%) |
| Emitted JS files | 308 (+45 new lazy chunks) |
| Dominant chunk share | ~80% (`index-*.js`) |

### After — Top Dependencies (Post-Optimization Location)

| Rank | Dependency | Gzip Size | Location After |
|------|------------|----------:|----------------|
| 1 | `emoji-picker-react` | 109.27 KB | Lazy chunk `index-Bj3ev3tE.js` — not in entry |
| 2 | `highlight.js` | 139.83 KB | Lazy chunk `Editor-*.js` — not in entry |
| 3 | `yjs` | part of `Editor-*.js` | Lazy chunk `Editor-*.js` — not in entry |

### After — Changes Applied

| Change | Impact |
|--------|--------|
| Lazy-load `emoji-picker-react` in `EmojiPicker.tsx` | Moved 109.27 KB gzip out of entry chunk |
| Lazy-load `Editor.tsx` at call sites | Moved yjs, lowlight, y-websocket, TipTap extensions (139.83 KB gzip) into `Editor-*.js` lazy chunk |
| Added `EditorSkeleton.tsx` loading state | UX continuity during lazy load |
| Added `LazyErrorBoundary.tsx` error boundary | Handles lazy chunk 404s with "Reload" button |
| Removed `@tanstack/query-sync-storage-persister` | Unused dependency eliminated |
| Added `web/scripts/check-bundle-budget.mjs` | CI budget enforcement at 275 KB gzip |

---

## Summary

The initial page-load entry chunk gzip dropped from 587.59 KB to 259.97 KB (−55.8%), exceeding the ≥20% target. The total `dist/` size increased from 2.21 MB to 3.28 MB because the three previously-inlined heavy dependencies are now emitted as separate lazy chunks. Users only download these chunks when navigating to a document or opening the emoji picker. The target was met via code splitting, not total-size reduction.

| Target | Threshold | Actual | Status |
|--------|-----------|--------|--------|
| ≥20% initial page load reduction (entry chunk gzip) | ≤470.07 KB | 259.97 KB | PASS (−55.8%) |

## Test Status

All unit tests pass: **547 tests across 36 test files**, 0 failures (vitest, 2026-03-15).
