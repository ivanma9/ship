# 02 — Bundle Size

**Audit Date:** 2026-03-10 · **Remediation Completed:** 2026-03-13

## Before

| Metric | Value |
|--------|-------|
| Total production payload | 2,321,505 bytes (2,267.09 KB, **2.21 MB**) |
| Largest entry chunk (raw) | `index-C2vAyoQ1.js` — 2,073.70 KB minified |
| Entry chunk gzip | **587.59 KB** |
| Emitted JS files | 263 |
| Dominant chunk share | 94.90% (`index-C2vAyoQ1.js`) |

## Fixes Applied

| Change | Files Touched |
|--------|---------------|
| Lazy-load `emoji-picker-react` | `web/src/components/EmojiPicker.tsx` |
| Lazy-load `Editor.tsx` at all call sites (moves yjs, lowlight, y-websocket, TipTap extensions out of entry chunk) | `web/src/components/Editor.tsx` + call sites |
| Added `EditorSkeleton.tsx` loading state | `web/src/components/EditorSkeleton.tsx` |
| Added `LazyErrorBoundary.tsx` error boundary | `web/src/components/LazyErrorBoundary.tsx` |
| Removed unused `@tanstack/query-sync-storage-persister` | `web/package.json` |
| Added CI budget gate script at 275 KB gzip | `web/scripts/check-bundle-budget.mjs` |

## After

| Metric | Before | After | Measurement Method | Status |
|--------|--------|-------|--------------------|--------|
| Entry chunk gzip | 587.59 KB | **259.97 KB** | `check-bundle-budget.mjs` (`zlib.gzipSync`) | PASS (−55.8%) |
| Entry chunk gzip (Vite report) | 587.59 KB | 266.21 KB | Vite build output | PASS (−54.7%) |
| Entry chunk raw | 2,073.70 KB | 977.87 KB | `web/dist/assets/` | — |
| Total production payload | 2.21 MB | 3.28 MB | Sum of `dist/` bytes | Expected increase |
| Emitted JS files | 263 | 308 | `dist/assets/` count | +45 lazy chunks |
| ≥20% entry chunk reduction target | — | −55.8% | Budget script | PASS |

## Measurement

```bash
pnpm build
node web/scripts/check-bundle-budget.mjs
# Output: PASS/FAIL with gzip size vs 275 KB budget
```

## Key Decisions

- Total bundle size went up (more lazy chunks) while entry chunk went down — intentional: lazy chunks load on demand, reducing initial parse cost. Users only download `emoji-picker-react` (109.27 KB gzip) when opening the emoji picker, and the `Editor-*.js` chunk (139.83 KB gzip, includes yjs/lowlight/TipTap) when navigating to a document.
- The CI budget gate enforces 275 KB gzip on the entry chunk; it does not gate total `dist/` size, which will grow as features are added via code splitting.
