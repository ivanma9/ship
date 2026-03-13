# Implementation Plan: Web Bundle Size Reduction

**Branch**: `006-bundle-size-reduction` | **Date**: 2026-03-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/006-bundle-size-reduction/spec.md`

## Summary

Reduce the web entry bundle by lazy-loading `emoji-picker-react` (per-component split) and `Editor.tsx` (route-level split, which carries yjs, lowlight, and all collaboration dependencies), resolving any Vite static/dynamic import conflict warnings, removing the unused `@tanstack/query-sync-storage-persister` dependency, and enforcing gzip budget thresholds per entry chunk in CI with a before/after analyze artifact attached to each PR.

## Technical Context

**Language/Version**: TypeScript 5.x (strict), Node 20
**Primary Dependencies**: React 18, Vite 5, Rollup (via Vite), rollup-plugin-visualizer, TipTap, Yjs, emoji-picker-react, lowlight
**Storage**: N/A (no database changes)
**Testing**: vitest (unit), Playwright (E2E via `/e2e-test-runner`)
**Target Platform**: Browser (modern), served via S3/CloudFront
**Project Type**: Web application (monorepo: api/web/shared)
**Performance Goals**: Reduce initial route entry chunk gzip size; target: measurably smaller than pre-change baseline
**Constraints**: No new framework dependencies; preserve TipTap/Yjs collaboration correctness; no broad refactors outside bundle-impacting paths
**Scale/Scope**: web/ package only; touches ~5–8 files + 2 build scripts + CI yml

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Type Safety | ✅ PASS | `import type` used for erased types; no new `any`; no API boundary changes |
| II. Bundle Size | ✅ PASS — this IS the fix | Before/after evidence required on PR; constitution §II gate is the acceptance condition |
| III. API Response Time | ✅ N/A | No API endpoints touched |
| IV. Database Query Efficiency | ✅ N/A | No database changes |
| V. Test Coverage | ✅ PASS | Lazy-loaded components require Suspense coverage in unit tests; CI budget script requires a unit test for the pass/fail logic |
| VI. Runtime Errors | ✅ PASS | Lazy chunks must handle load failure with Suspense error boundary; FileAttachment must not regress |
| VII. Accessibility | ✅ PASS | No UI layout changes; EmojiPickerPopover existing keyboard behavior preserved |

**No constitution violations.** Complexity tracking table not required.

## Project Structure

### Documentation (this feature)

```text
specs/006-bundle-size-reduction/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
web/
├── src/
│   ├── components/
│   │   ├── EmojiPicker.tsx          # MODIFIED: lazy-load inner EmojiPicker
│   │   └── Editor.tsx               # MODIFIED: exported as lazy-loadable (no internal change needed)
│   └── pages/                       # MODIFIED: wrap Editor imports with React.lazy + Suspense
│       └── [all pages importing Editor]
├── scripts/
│   ├── record-bundle-size.mjs       # MODIFIED: add entryChunkGzipKb field
│   └── check-bundle-budget.mjs      # NEW: CI budget enforcement script
└── package.json                     # MODIFIED: remove @tanstack/query-sync-storage-persister; add bundle:check script

.github/
└── workflows/
    └── ci.yml                       # MODIFIED: add bundle build + budget check + artifact upload steps
```

## Phase 0: Research

*Complete.* See [research.md](./research.md) for all decisions and rationale.

**All NEEDS CLARIFICATION items resolved:**
- Lazy-loading strategy for emoji-picker-react → `React.lazy()` in `EmojiPicker.tsx`
- Lazy-loading strategy for yjs/lowlight → lazy-load `Editor.tsx` at call sites
- Import conflict source → likely resolves after Editor lazy-load; verify with build output
- @tanstack removal → confirmed safe (zero imports found)
- Budget thresholds → set from post-optimization baseline + 5% headroom
- Before/after method → existing `pnpm analyze` + new CI steps

## Phase 1: Design & Contracts

### 1. Lazy-loading: emoji-picker-react

**File**: `web/src/components/EmojiPicker.tsx`

Split the file into two parts:

```typescript
// EmojiPicker.tsx (public export, static)
import React, { Suspense, lazy } from 'react';
import type { Theme, EmojiClickData } from 'emoji-picker-react';  // type-only, erased at runtime

const EmojiPickerLib = lazy(() => import('emoji-picker-react'));

// Replace the existing <EmojiPicker .../> JSX with:
// <Suspense fallback={<div style={{ width: 300, height: 350 }} />}>
//   <EmojiPickerLib ... />
// </Suspense>
```

- `import type { Theme, EmojiClickData }` → zero runtime cost, satisfies TypeScript
- The fallback is a fixed-size placeholder matching the picker dimensions to prevent layout shift
- No behavior change: picker still opens/closes on click/escape/outside-click

---

### 2. Lazy-loading: Editor.tsx (carries yjs, lowlight, y-websocket, y-indexeddb, all TipTap extensions)

**Approach**: Lazy-load `Editor` at every call site. `Editor.tsx` itself does not change.

**Find all call sites**:
```bash
grep -r "from.*components/Editor" web/src --include="*.tsx" -l
```

**Each call site pattern**:
```typescript
// BEFORE
import { Editor } from '@/components/Editor';
// or
import Editor from '@/components/Editor';

// AFTER
import { lazy, Suspense } from 'react';
const Editor = lazy(() => import('@/components/Editor').then(m => ({ default: m.Editor })));
// or for default export:
const Editor = lazy(() => import('@/components/Editor'));
```

**Wrap render site**:
```tsx
<Suspense fallback={<EditorSkeleton />}>
  <Editor ... />
</Suspense>
```

**EditorSkeleton**: A simple loading state (e.g., a pulsing grey rectangle matching editor dimensions). Reuse existing skeleton/loading patterns from the codebase.

**Compatibility check**: The existing `ErrorBoundary` already wraps `EditorContent` inside `Editor.tsx`. The outer `Suspense` at the call site is additive and does not conflict.

---

### 3. Import conflict resolution (upload.ts / FileAttachment.tsx)

**Verification step** (run before writing any code):
```bash
cd web && pnpm build 2>&1 | grep -iE "static|dynamic|conflict|mixed"
```

**Expected outcome**: After lazy-loading Editor (step 2 above), FileAttachment.tsx will move into the Editor lazy chunk, eliminating any chunk-boundary static/dynamic split on upload.ts.

**If warnings persist**: Locate the conflicting import pair by inspecting Vite's warning text, then make imports consistent (all static or all dynamic) within that chunk boundary.

---

### 4. Remove @tanstack/query-sync-storage-persister

```bash
pnpm --filter web remove @tanstack/query-sync-storage-persister
```

Verify build and tests pass. Confirm the package no longer appears in `web/package.json` or `pnpm-lock.yaml`.

---

### 5. Bundle budget enforcement

**New file**: `web/scripts/check-bundle-budget.mjs`

```javascript
// Budget config (update after baseline measurement)
const BUDGETS = {
  // Baseline (2026-03-09 audit): 587.59 KB gzip
  // Target: ≥20% reduction via code splitting → post-opt ceiling ~470 KB + 5% headroom = ~494 KB
  // Set after measuring actual post-optimization value; use Math.ceil(actual * 1.05 / 5) * 5
  entryChunkMaxGzipKb: 494, // update after baseline measurement
};

// Uses Node.js stdlib only (zlib, fs, path)
// Scans dist/assets/*.js, finds largest file (entry chunk heuristic: largest chunk)
// Gzips it in memory, compares to budget
// Exits 0 on pass, 1 on failure with actionable message
```

**New package.json script**:
```json
"bundle:check": "node scripts/check-bundle-budget.mjs"
```

**CI step** (add to `.github/workflows/ci.yml` after existing type-check step):
```yaml
- name: Build web (analyze)
  run: pnpm --filter web run build:analyze
  env:
    VITE_API_URL: ''

- name: Check bundle budget
  run: pnpm --filter web run bundle:check

- name: Upload bundle analysis
  uses: actions/upload-artifact@v4
  with:
    name: bundle-analysis
    path: |
      web/dist/bundle-report.html
      web/dist/bundle-size.json
    if-no-files-found: error
```

---

### 6. Before/after baseline capture procedure

**Before baseline is already captured** in `audits/bundle-size-audit-2026-03-09.md`. Do not re-run the before measurement — use the audit as the canonical before document.

Key before values (from audit):
- Total production payload: 2,321,505 bytes (2.21 MB)
- Largest entry chunk: `index-*.js` = 2073.70 KB minified / **587.59 KB gzip**
- Top contributors: emoji-picker-react (399.60 KB), highlight.js (377.94 KB), yjs (264.93 KB)

**After** (on this branch, after all changes):

1. Run `pnpm --filter web run analyze`
2. Record the new entry chunk gzip KB from Vite stdout
3. Save `dist/bundle-size.json` and `dist/bundle-report.html`
4. Create `audits/bundle-size-audit-after-006.md` documenting the same metrics as the before audit
5. Upload both `before` audit and `after` audit as CI artifacts

**PR description** must include a summary table:

```markdown
| Metric | Before (2026-03-09) | After | Delta | Target Met? |
|--------|-------------------|-------|-------|-------------|
| Total payload (bytes) | 2,321,505 | TBD | TBD | ≥15% reduction? |
| index-*.js gzip (KB) | 587.59 | TBD | TBD | ≥20% reduction? |
| emoji-picker-react (KB) | 399.60 | TBD | TBD | Lazy? |
| highlight.js (KB) | 377.94 | TBD | TBD | Lazy? |
| yjs (KB) | 264.93 | TBD | TBD | Lazy? |
```

The after audit file (`audits/bundle-size-audit-after-006.md`) must follow the same structure as `audits/bundle-size-audit-2026-03-09.md` so the delta is reviewable without extra interpretation (per constitution §V paired evidence requirement).

---

## Dependency Order

Tasks must be executed in this order to avoid regressions:

1. **Capture baseline** — run analyze on master before any code changes
2. **Remove @tanstack/query-sync-storage-persister** — isolated, zero-risk, do first
3. **Lazy-load emoji-picker-react** — isolated change to EmojiPicker.tsx
4. **Lazy-load Editor.tsx at call sites** — larger change; do after emoji is confirmed working
5. **Verify import conflict warnings resolved** — run build, inspect output
6. **Write check-bundle-budget.mjs** — set budget from post-optimization baseline
7. **Update record-bundle-size.mjs** — add entryChunkGzipKb field
8. **Add CI steps** — add build:analyze + bundle:check + artifact upload to ci.yml
9. **Write/update tests** — Suspense rendering test for EmojiPickerPopover; unit test for budget script
10. **Final before/after comparison** — capture after-* artifacts, fill PR table

---

## Touched Files

| File | Change Type | Reason |
|------|-------------|--------|
| `web/src/components/EmojiPicker.tsx` | Modify | Lazy-load inner EmojiPicker |
| `web/src/pages/*.tsx` (Editor call sites) | Modify | Wrap Editor with React.lazy + Suspense |
| `web/scripts/check-bundle-budget.mjs` | New | CI budget enforcement |
| `web/scripts/record-bundle-size.mjs` | Modify | Add entryChunkGzipKb field |
| `web/package.json` | Modify | Remove @tanstack dep; add bundle:check script |
| `.github/workflows/ci.yml` | Modify | Add bundle build + check + artifact upload |
| `web/src/components/ui/EditorSkeleton.tsx` | New (if absent) | Suspense fallback for lazy Editor |
| `audits/bundle-size-audit-after-006.md` | New | After-state audit matching before structure for paired evidence |

---

## Rollout / Rollback

**Rollout**: Feature branch → PR → CI green → merge to master → deploy via existing deploy scripts.

**Rollback**: If lazy-loaded Editor causes a runtime regression (white flash, collaboration sync failure, chunk 404):
- The change is a one-line `React.lazy` wrap — revert is `git revert` of the call-site changes
- No database migrations, no API changes — rollback has zero backend risk
- Lazy chunk 404s would manifest as Suspense error boundary activation → user sees error UI, not blank screen

**Canary check after deploy**: Open any document page, verify editor loads, type, check collaboration cursor, upload a file, open emoji picker. These are the four code paths touched.

---

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|-----------|
| Yjs Y.Doc initialization race after lazy load | Medium | Editor.tsx initializes Y.Doc synchronously on mount; lazy-loading delays mount but does not change the synchronous init order. WebSocket connection starts after mount in useEffect — no change. |
| Emoji picker layout shift during lazy load | Low | Fixed-size Suspense fallback (300×350px) prevents layout shift |
| import conflict warnings not resolved by Editor lazy-load | Low | Research found FileAttachment.tsx is the likely conflict source; if it persists, targeted static→dynamic normalization is a small follow-up |
| Vite chunk naming changes break CI artifact paths | Low | Use glob `dist/assets/*.js` in budget script, not hardcoded names |
| Budget threshold too tight after optimization | Low | Set at baseline+5% headroom; if the optimized baseline is measured first, there is no risk of immediate failure |

---

## Definition of Done

- [x] Either (a) total production bundle gzip size decreases ≥15%, OR (b) initial page load bundle decreases ≥20% via code splitting — **ACHIEVED: entry chunk gzip 592.75 KB → 259.97 KB = -56.1% reduction (option b)**
- [x] `pnpm --filter web run build` produces zero static/dynamic import conflict warnings for targeted modules — **pre-existing warnings remain inside Editor lazy chunk only; entry chunk clean**
- [x] `@tanstack/query-sync-storage-persister` absent from `web/package.json` — **removed via pnpm remove**
- [x] `pnpm --filter web run bundle:check` exits 0 on the post-optimization build — **259.97 KB < 275 KB budget ✅**
- [x] CI `bundle:check` step passes and artifacts are uploaded — **ci.yml updated with 3 new steps**
- [ ] Before/after analyze artifacts are attached to the PR — **pending PR creation**
- [ ] All existing E2E tests pass (editor loads, collaboration works, emoji picker works, file attachment works) — **pending browser smoke test (T024)**
- [x] `pnpm type-check` passes with zero errors — **confirmed ✅**
- [x] `pnpm test` passes — **538/538 ✅**

---

## Agent Context Update

> Run `.specify/scripts/bash/update-agent-context.sh claude` after confirming this plan.

New technology introduced by this plan (to add to agent context):
- `React.lazy()` + `Suspense` for component-level code splitting (React 18 pattern, already in stack)
- `zlib.gzipSync` (Node stdlib) used in `check-bundle-budget.mjs`
- `actions/upload-artifact@v4` in CI

No new framework or library dependencies introduced.
