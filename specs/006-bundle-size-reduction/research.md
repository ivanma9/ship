# Research: Web Bundle Size Reduction

**Branch**: `006-bundle-size-reduction` | **Date**: 2026-03-13

## Findings

---

### Decision 1: Lazy-loading strategy for emoji-picker-react

**Decision**: Wrap `EmojiPicker.tsx`'s inner `<EmojiPicker>` import with `React.lazy()` + `Suspense`. The outer `EmojiPickerPopover` component renders the picker only when `isOpen=true`, making it a natural lazy boundary.

**Rationale**: `emoji-picker-react` is only needed after user interaction (clicking the emoji button). Conditional rendering already exists — lazy-loading is a minimal diff. Type imports (`Theme`, `EmojiClickData`) can be kept as `import type` at the top level since they are erased at runtime.

**Alternatives considered**:
- Route-level lazy load of the whole page containing the picker — rejected; picker is used across multiple pages, so per-component splitting is more targeted.
- Inline dynamic `import()` in the click handler — valid but requires manual state management; React.lazy+Suspense is cleaner and idiomatic.

**Implementation note**: `EmojiPickerPopover` already conditionally renders `<EmojiPicker>` inside `{isOpen && ...}`. Split into two files: keep `EmojiPickerPopover` as the static export, move the dynamic picker load into a new `LazyEmojiPicker` internal component using `React.lazy(() => import('emoji-picker-react'))`.

---

### Decision 2: Lazy-loading strategy for yjs + lowlight

**Decision**: Lazy-load `Editor.tsx` itself at every call site via `React.lazy()`. This defers yjs, y-websocket, y-indexeddb, lowlight, and all TipTap collaboration extensions out of the entry chunk in a single move.

**Rationale**: `Editor.tsx` is a large component that requires yjs synchronously during useRef/useEditor initialization — there is no clean way to defer the Y.Doc creation separately. However, editor content is never needed before the shell UI renders, so lazy-loading the whole Editor is safe and correct. `lowlight` is co-located in `Editor.tsx` and will automatically follow.

**Alternatives considered**:
- Lazy-load yjs separately from Editor — rejected; the Collaboration TipTap extension calls `new Y.Doc()` during extension setup, which runs synchronously at editor construction time. You'd have to restructure the entire editor init flow.
- Dynamic `import('yjs')` inside useEffect — rejected; would require converting synchronous Y.Doc refs to async state, breaking the existing collaboration sync model.
- Vite `build.rollupOptions.output.manualChunks` override — valid complement, but lazy-loading Editor is the primary lever; manualChunks is secondary tuning.

**Implementation note**: Find all locations that `import { Editor }` or `import Editor` from the editor component file and replace with `const Editor = React.lazy(() => import('@/components/Editor'))`. Each call site already renders Editor inside a routed page — wrap with `<Suspense fallback={<EditorSkeleton />}`.

---

### Decision 3: Resolve Vite static/dynamic import conflict warnings (upload.ts / FileAttachment.tsx)

**Decision**: Audit the build output for the exact warning text, then convert whichever import is the "dynamic" side to be consistently static, or vice versa.

**Rationale**: Vite warns when the same module is imported both statically (top-level `import`) and dynamically (`import()`) within the same chunk graph. This usually happens when a module is eagerly imported in one file and lazily imported in another, causing Vite to hoist it back into the entry chunk and emit a warning.

**Finding from code review**: `upload.ts` uses only `import.meta.env` (a static Vite pattern, not a dynamic import). `FileAttachment.tsx` imports `upload.ts` statically. The likely conflict arises if some lazy chunk (e.g., a lazy-loaded editor extension) also tries to dynamically `import('@/services/upload')`. After lazy-loading Editor.tsx (Decision 2), FileAttachment.tsx will move into the lazy Editor chunk, resolving the conflict naturally. If warnings persist post-lazy-load, the fix is to ensure no inline `import('@/services/upload')` calls exist alongside the static import.

**Verification step (mandatory)**: Run `pnpm --filter web run build 2>&1 | grep -i "static.*dynamic\|dynamic.*static\|mixed import"` before and after each change to capture actual warning text.

---

### Decision 4: Remove @tanstack/query-sync-storage-persister

**Decision**: Remove the package from `web/package.json` and `pnpm-lock.yaml`.

**Rationale**: Code search across the entire `web/src/` tree found zero import statements referencing `@tanstack/query-sync-storage-persister`. It is a listed production dependency with no runtime consumers. Removal is safe.

**Alternatives considered**: Keep as a dev dependency in case future offline-persistence work uses it — rejected per YAGNI; it can be re-added when needed.

**Implementation note**: Run `pnpm --filter web remove @tanstack/query-sync-storage-persister` and confirm build passes.

---

### Decision 5: Bundle budget thresholds and CI enforcement

**Decision**:
1. Run `pnpm --filter web run build:analyze` on the current `master` branch to capture the before baseline (gzipped entry chunk size from Vite's stdout).
2. Set the budget at `baseline_gzip_kb + 5% headroom`, rounded up to the nearest 5 KB.
3. Add `scripts/check-bundle-budget.mjs` that reads Vite's JSON stats (via `vite build --reporter json` or by parsing the dist directory) and compares entry chunk gzip size to the configured budget.
4. Add a CI step `Check bundle budget` in `.github/workflows/ci.yml` after the build step.

**Rationale**: Constitution §II mandates that "the initial route bundle for the changed experience MUST NOT grow by more than 20 KB gzip without an approved exception." The existing `record-bundle-size.mjs` records total dist size but does not enforce a per-chunk budget or fail CI. A new lightweight script enforces the ceiling automatically.

**Budget script approach**: Use Vite's build output (dist/assets/*.js) + `import { statSync } from 'fs'` + `zlib.gzipSync` to measure the largest JS entry chunk without a separate tool dependency. Write budget config as a JSON constant at the top of the script. Exit code 1 on budget breach.

**Alternatives considered**:
- bundlesize / size-limit npm packages — rejected; adds a new dependency for something achievable in 40 lines of Node.js using zlib (already in stdlib).
- GitHub Actions `actions/upload-artifact` only — rejected; uploading without enforcement doesn't block regressions.

---

### Decision 6: Before/after analysis method

**Decision**:
1. On current `master` (before changes): run `pnpm --filter web run analyze` → saves `dist/bundle-size.json` and `dist/bundle-report.html`.
2. Rename/copy these as `before-bundle-size.json` and `before-bundle-report.html` in a CI artifact upload.
3. After changes: run the same command → saves the "after" versions.
4. PR description includes both artifact links and a summary table of delta per chunk.

**Rationale**: The `analyze` script already produces both a visual HTML report and a machine-readable JSON total. For chunk-level deltas, Vite's build stdout includes per-chunk gzip sizes — these can be captured by redirecting build output to a file and diffing before/after.

**Implementation note**: Add `pnpm --filter web run analyze` as a CI step and upload `dist/bundle-report.html` + `dist/bundle-size.json` as an Actions artifact named `bundle-analysis`.
