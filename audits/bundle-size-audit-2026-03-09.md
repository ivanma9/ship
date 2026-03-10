# Bundle Size Audit Report (2026-03-09)

## 1. Scope

- Category: Frontend production bundle size.
- Repo: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`.
- In scope: `web/dist/index.html` and `web/dist/assets/*`.
- Out of scope: Analyzer artifacts (for example `bundle-report.html`).
- Clarification: "2.21 KB" was interpreted as `2.21 MB`.

## 2. Measurement Method


| Metric                       | Tool + command                                                             | How measured                                         | Limits                                           |
| ---------------------------- | -------------------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------------ |
| Total shipped payload        | Node script over `web/dist/index.html` + `web/dist/assets/*`               | Exact byte sum of shipped files                      | Excludes non-shipped analyzer files              |
| Chunk sizes + count          | `pnpm --filter @ship/web run build:analyze`                                | Parsed Vite `dist/*` output (minified + gzip)        | Hash/chunk names vary by build                   |
| Dependency size attribution  | Parsed `const data = ...` from `web/dist/bundle-report.html`               | Aggregated `nodeParts.renderedLength` by npm package | Can slightly overcount some wrapped CJS paths    |
| Unused dependency candidates | Static import scan of `web/src/**/*.{ts,tsx,js,jsx}` vs `web/package.json` | Flags deps with no direct import match               | False positives possible for indirect/glob usage |


## 3. Audit Deliverable


| Metric                          | Value                                                         | Notes                                      |
| ------------------------------- | ------------------------------------------------------------- | ------------------------------------------ |
| Total production payload        | 2,321,505 bytes (2,267.09 KB, 2.21 MB)                        | Deployment baseline: shipped HTML + assets |
| Largest emitted chunk           | `dist/assets/index-C2vAyoQ1.js` = 2073.70 KB (gzip 587.59 KB) | From Vite output                           |
| Emitted files                   | 263                                                           | Count of Vite `dist/*` entries             |
| Dominant visualizer chunk share | 94.90% (`assets/index-C2vAyoQ1.js`)                           | Concentration signal, not deployment bytes |
| Visualizer center metrics       | Rendered 4.34 MB, gzip 1.06 MB, brotli 927.27 KB              | Used for diagnosis only                    |


## 4. Dependency Concentration


| Rank | Dependency           | Visualizer rendered size |
| ---- | -------------------- | ------------------------ |
| 1    | `emoji-picker-react` | 399.60 KB                |
| 2    | `highlight.js`       | 377.94 KB                |
| 3    | `yjs`                | 264.93 KB                |


Unused dependency candidates from static scan:

- `@tanstack/query-sync-storage-persister`
- `@uswds/uswds` (likely false positive due to glob-based usage)

## 5. Findings (Ranked)

1. **P1 - Oversized entry chunk.**
  Evidence: `index-C2vAyoQ1.js` is 2073.70 KB and holds 94.90% of visualizer share.  
   Impact: Slower first load and worse TTI on constrained devices/networks.
2. **P1 - A few packages account for a large share.**
  Evidence: `emoji-picker-react`, `highlight.js`, and `yjs` are top contributors.  
   Impact: High-leverage targets for lazy loading or footprint reduction.
3. **P2 - Code splitting is partially negated.**
  Evidence: Vite warns `upload.ts` and `FileAttachment.tsx` are both statically and dynamically imported.  
   Impact: Larger initial chunk than expected.
4. **P3 - Dependency hygiene opportunity.**
  Evidence: Static scan flagged at least one likely unused package.  
   Impact: Ongoing maintenance and bundle creep risk if left unchecked.

## 6. What Is Already Working

- The build emits many route/feature chunks (263 files), so the app is not fully monolithic.
- Improvement work can focus on the oversized entry chunk rather than rebuilding the bundling approach.

## 7. Risks and Unknowns

- No runtime RUM data yet (for example LCP/TTI by network/device class).
- Visualizer package aggregation can overcount some wrapper paths.
- Static unused-dependency scans can miss non-standard resolution patterns.

## 8. Boundary Reminder

- This audit is diagnostic only.
- No code or dependency fixes were applied in this pass.

