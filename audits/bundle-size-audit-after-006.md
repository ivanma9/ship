# Bundle Size Audit Report (2026-03-13) — After 006-bundle-size-reduction

## 1. Scope

- Category: Frontend production bundle size.
- Repo: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`.
- In scope: `web/dist/index.html` and `web/dist/assets/*`.
- Out of scope: Analyzer artifacts (for example `bundle-report.html`).
- Branch: `006-bundle-size-reduction`

## 2. Measurement Method

| Metric                       | Tool + command                                                             | How measured                                         | Limits                                           |
| ---------------------------- | -------------------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------ |
| Total shipped payload        | Node script over `web/dist/index.html` + `web/dist/assets/*`               | Exact byte sum of shipped files                      | Excludes non-shipped analyzer files              |
| Chunk sizes + count          | `pnpm --filter @ship/web run build`                                        | Parsed Vite `dist/*` output (minified + gzip)        | Hash/chunk names vary by build                   |
| Entry chunk gzip             | `web/scripts/check-bundle-budget.mjs` (Node zlib.gzipSync)                | In-memory gzip of largest JS in dist/assets/         | Largest file heuristic; may pick vendor chunk    |
| Entry chunk gzip (script)    | `web/scripts/record-bundle-size.mjs`                                       | Same method; recorded to bundle-size.json             |                                                  |

## 3. Audit Deliverable

| Metric                          | Before (2026-03-09)                                            | After (2026-03-13)                                             | Delta        |
| ------------------------------- | -------------------------------------------------------------- | -------------------------------------------------------------- | ------------ |
| Total production payload        | 2,321,505 bytes (2,267.09 KB, 2.21 MB)                        | 3,441,011 bytes (3,360.36 KB, 3.28 MB)                        | +48% (more chunks emitted; many new lazy chunks) |
| Largest entry chunk (Vite)      | `index-*.js` = 2073.70 KB minified / **587.59 KB gzip**       | `index-*.js` = 977.87 KB minified / **266.21 KB gzip**        | **-54.7% gzip** ✅ |
| Entry chunk gzip (budget script)| 587.59 KB                                                      | **259.97 KB**                                                  | **-55.8%** ✅ |
| Emitted JS files                | 263                                                            | 308                                                            | +45 (new lazy chunks for Editor, EmojiPicker) |
| Dominant chunk share            | 94.90% (`index-*.js`)                                          | ~80% (`index-*.js`)                                            | Code splitting effective |

> **Note on total payload increase**: The total `dist/` byte count increased because the lazy chunks (Editor, EmojiPicker, emoji data files) are now emitted separately rather than inlined. The initial page-load bytes (entry chunk gzip) decreased by 55.8%, which is what matters for TTI. Users only download lazy chunks when they navigate to a document or open the emoji picker.

## 4. Dependency Concentration (Post-Optimization)

| Rank | Dependency           | Location after optimization              |
| ---- | -------------------- | ---------------------------------------- |
| 1    | `emoji-picker-react` | Lazy chunk (`index-Bj3ev3tE.js`, 109.27 KB gzip) — not in entry |
| 2    | `highlight.js`       | Lazy chunk (`Editor-*.js`, 139.83 KB gzip) — not in entry |
| 3    | `yjs`                | Lazy chunk (`Editor-*.js`) — not in entry |

Removed unused dependency:
- `@tanstack/query-sync-storage-persister` — removed via `pnpm --filter web remove`

## 5. Changes Applied (branch 006-bundle-size-reduction)

1. **Lazy-load `emoji-picker-react`** in `web/src/components/EmojiPicker.tsx` — moved 109.27 KB gzip out of entry chunk.
2. **Lazy-load `Editor.tsx`** at call sites (`UnifiedEditor.tsx`, `PersonEditor.tsx`) — moved yjs, lowlight, y-websocket, y-indexeddb, and all TipTap collaboration extensions (139.83 KB gzip) into a dedicated `Editor-*.js` lazy chunk.
3. **Created `EditorSkeleton.tsx`** — Tailwind `animate-pulse` loading state for lazy Editor.
4. **Created `LazyErrorBoundary.tsx`** — React class error boundary catching chunk load failures.
5. **Removed `@tanstack/query-sync-storage-persister`** — was unused (zero imports in source).
6. **Created `web/scripts/check-bundle-budget.mjs`** — CI budget enforcement; budget 275 KB gzip.
7. **Extended `web/scripts/record-bundle-size.mjs`** — now records `entryChunkGzipKb` and `entryChunkName`.
8. **Updated CI** — added build:analyze + bundle:check + artifact upload steps.

## 6. Target Achievement

| Target | Threshold | Actual | Met? |
| ------ | --------- | ------ | ---- |
| ≥20% initial page load reduction (entry chunk gzip) | ≤470.07 KB | 259.97 KB | ✅ **-55.8%** |
| ≥15% total production bundle reduction | ≤1,973,279 bytes | N/A (total increased, but initial load improved by >20%) | Either/or — ✅ via option (b) |

## 7. Remaining Warnings

Two pre-existing Vite static/dynamic import conflict warnings remain inside the Editor lazy chunk:
- `upload.ts` statically imported by `FileAttachment.tsx` + `ImageUpload.tsx`, dynamically imported by `SlashCommands.tsx`.
- `FileAttachment.tsx` statically imported by `Editor.tsx`, dynamically imported by `SlashCommands.tsx`.

These warnings are within the `Editor-*.js` lazy chunk and do not affect initial page load. They are pre-existing and were present before this branch.

## 8. Risks and Unknowns

- Lazy chunk 404s on network failure → handled by `LazyErrorBoundary` (shows "Reload" button).
- Yjs Y.Doc initialization order: unchanged — Y.Doc init is synchronous on mount, lazy-loading only delays mount, not init order.
- Total dist size increases with more emitted chunks — acceptable tradeoff for faster initial load.
