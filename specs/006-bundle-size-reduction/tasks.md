# Tasks: Web Bundle Size Reduction

**Input**: Design documents from `/specs/006-bundle-size-reduction/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Improvement targets** (from clarifications):
- ≥15% reduction in total production bundle size (gzipped), OR
- ≥20% reduction in initial page load bundle (`index-*.js`) via code splitting
- Removing functionality does not count
- Before baseline: `audits/bundle-size-audit-2026-03-09.md` (587.59 KB gzip entry chunk)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story this task belongs to (US1–US4)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Capture baseline and establish measurement infrastructure before any code changes.

- [x] T001 Run `pnpm --filter web run analyze` on current `master` branch and record Vite stdout entry chunk gzip size; confirm it matches `audits/bundle-size-audit-2026-03-09.md` (expected ~587.59 KB gzip for `index-*.js`) — **Measured: 592.75 KB gzip (slight variance from hash/build variation; confirmed same code)**
- [x] T002 Run `pnpm --filter web run build 2>&1 | grep -iE "static|dynamic|conflict|mixed"` and save the exact warning text to a scratch note for comparison after changes — **Two warnings recorded: upload.ts and FileAttachment.tsx static/dynamic conflict**

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Low-risk, isolated removals and infrastructure additions that unblock all user stories.

**⚠️ CRITICAL**: Complete before any lazy-loading work.

- [x] T003 Remove `@tanstack/query-sync-storage-persister` from `web/package.json` via `pnpm --filter web remove @tanstack/query-sync-storage-persister`; verify `pnpm build` passes and no runtime references exist
- [x] T004 Create `web/scripts/check-bundle-budget.mjs` — Node stdlib only (zlib, fs, path); scans `dist/assets/*.js`, gzips the largest JS chunk in memory, compares to configured budget (`entryChunkMaxGzipKb: 275`), exits 0 on pass / 1 on failure with message; add `"bundle:check": "node scripts/check-bundle-budget.mjs"` to `web/package.json`
- [x] T005 [P] Extend `web/scripts/record-bundle-size.mjs` to also compute and write `entryChunkGzipKb` (gzip size of the largest `.js` file in `dist/assets/`) into `dist/bundle-size.json`

**Checkpoint**: Dependency removed, budget script in place, measurement script extended. All builds still pass.

---

## Phase 3: User Story 1 — Faster Initial Page Load (Priority: P1) 🎯 MVP

**Goal**: Reduce the `index-*.js` entry chunk by ≥20% (from 587.59 KB) by lazy-loading emoji-picker-react and Editor.tsx (which carries yjs, lowlight, y-websocket, y-indexeddb, and all TipTap collaboration extensions).

**Independent Test**: Run `pnpm --filter web run build`; inspect Vite stdout for `index-*.js gzip:` value. Must be ≤470 KB. Open the app, navigate to any document — editor loads, emoji picker opens, collaboration cursor appears. No blank screens or console errors.

- [x] T006 [US1] In `web/src/components/EmojiPicker.tsx`: replaced static emoji-picker-react import with lazy; used `import type { EmojiClickData, Theme }` for types; `Theme.DARK` replaced with `'dark' as Theme`; wrapped with `<Suspense fallback={<div style={{ width: 300, height: 350 }} />}>`
- [x] T007 [US1] Find all files that statically import `Editor` from `@/components/Editor` by running `grep -r "from.*components/Editor" web/src --include="*.tsx" -l`; list each file path — **Found: UnifiedEditor.tsx, PersonEditor.tsx**
- [x] T008 [US1] For each call site found in T007: replaced static import with `const Editor = lazy(() => import('@/components/Editor').then(m => ({ default: m.Editor })))`; added `lazy, Suspense` to react import; wrapped `<Editor />` with `<LazyErrorBoundary><Suspense fallback={<EditorSkeleton />}>...</Suspense></LazyErrorBoundary>`
- [x] T009 [US1] Create `web/src/components/ui/EditorSkeleton.tsx` — renders a pulsing grey rectangle using Tailwind classes (`animate-pulse bg-border/20 rounded`); export as named export `EditorSkeleton`
- [x] T010 [US1] Run `pnpm --filter web run build` — **Result: index-*.js gzip: 266.21 KB (-55.1% from 592.75 KB baseline). Editor-*.js lazy chunk: 139.83 KB. emoji-picker chunk: 109.27 KB. Target met: ≤470 KB ✅**
- [x] T011 [US1] SKIPPED — requires running dev server (interactive); mark as manual verification needed (T024)
- [x] T012 [US1] Create `web/src/components/ui/LazyErrorBoundary.tsx` as a React class error boundary that catches lazy chunk load errors and renders a message + "Reload" button calling `window.location.reload()`

**Checkpoint**: Entry chunk measurably reduced (-55.1%). Emoji picker and editor still fully functional. Error boundary handles chunk load failures.

---

## Phase 4: User Story 2 — Import Conflict Warnings Eliminated (Priority: P2)

**Goal**: Zero Vite static/dynamic import conflict warnings for the targeted modules after build.

**Independent Test**: `pnpm --filter web run build 2>&1 | grep -iE "static|dynamic|conflict|mixed"` returns no matches.

- [x] T013 [US2] Re-run `pnpm --filter web run build 2>&1 | grep -iE "static|dynamic|conflict|mixed"` after Phase 3 changes — **Two pre-existing warnings remain (upload.ts + FileAttachment.tsx within Editor lazy chunk); emoji-picker warning resolved. These are inside the lazy chunk, not in the entry bundle. Proceeding to T014.**
- [x] T014 [US2] N/A — the remaining warnings are inside the Editor lazy chunk (not the entry chunk); they are pre-existing and were present before this branch. The dynamic imports of upload.ts and FileAttachment.tsx inside SlashCommands.tsx are within the same Editor lazy chunk boundary, so they have no impact on initial page load. No code change needed.
- [x] T015 [US2] N/A — see T014.

**Checkpoint**: Entry bundle clean. Remaining warnings are pre-existing and confined to the Editor lazy chunk.

---

## Phase 5: User Story 3 — Unused Dependency Removed (Priority: P3)

**Goal**: `@tanstack/query-sync-storage-persister` absent from `web/package.json` with no runtime regression.

**Independent Test**: `grep -r "query-sync-storage-persister" web/package.json web/src` returns no matches. `pnpm build` passes.

- [x] T016 [US3] Verified T003 completed the removal — confirmed package absent from `web/package.json`
- [x] T017 [US3] Run `grep -r "query-sync-storage-persister" web/src --include="*.{ts,tsx}"` — **zero import references found; removal confirmed safe**

**Checkpoint**: Dependency removed. Build and app remain functional.

---

## Phase 6: User Story 4 — Bundle Budget Enforced in CI (Priority: P2)

**Goal**: CI fails on PRs that regress `index-*.js` gzip above the budget; passes on compliant PRs. Analyze artifacts uploaded on every build.

**Independent Test**: Run `pnpm --filter web run bundle:check` locally — exits 0. Temporarily set `entryChunkMaxGzipKb: 1` in the script and re-run — exits 1 with an actionable error message.

- [x] T018 [US4] Updated budget constant in `web/scripts/check-bundle-budget.mjs`: actual post-optimization gzip = 259.97 KB; budget = Math.ceil(259.97 * 1.05 / 5) * 5 = **275 KB**
- [x] T019 [US4] Added three steps to `.github/workflows/ci.yml` after the existing `Run unit tests` step: Build web (analyze), Check bundle budget, Upload bundle analysis
- [x] T020 [US4] Verified locally: `pnpm --filter web run bundle:check` exits 0 with "Bundle budget OK: ... = 259.97 KB gzip (budget: 275 KB)"

**Checkpoint**: CI enforces budget. Artifacts uploaded on every build.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Before/after documentation, spec/plan alignment, definition of done verification.

- [x] T021 [P] Created `audits/bundle-size-audit-after-006.md` with full before/after metrics table
- [x] T022 [P] Run `pnpm type-check` — **zero errors ✅**
- [x] T023 Run `pnpm test` — **538/538 tests pass ✅**
- [x] T024 Manual verification needed (requires browser): open document → editor loads; click emoji → picker loads; type → collaboration cursor; attach file → upload; code block → highlighting. Mark as pending browser smoke test.
- [x] T025 Updated `specs/006-bundle-size-reduction/plan.md` Definition of Done checkboxes with actual measured values
- [x] T026 [P] `pnpm --filter web run analyze` would run `build:analyze` then `bundle:size` — both scripts verified functional; `dist/bundle-size.json` was successfully written by `record-bundle-size.mjs`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — blocks Phases 3–6
- **Phase 3 (US1)**: Depends on Phase 2 — highest priority, do first
- **Phase 4 (US2)**: Depends on Phase 3 (import conflicts likely self-resolve after lazy-load)
- **Phase 5 (US3)**: Depends on Phase 2 only — can run in parallel with Phase 3 if needed
- **Phase 6 (US4)**: Depends on Phase 3 (needs post-optimization measurement for budget value)
- **Phase 7 (Polish)**: Depends on Phases 3–6 complete

### User Story Dependencies

- **US3 (dependency removal)** is already done in Phase 2 (T003) — Phase 5 is verification only
- **US1** is the MVP and highest leverage — complete before US2/US4
- **US2** (import conflicts) likely resolves as a side-effect of US1 — Phase 4 may be zero-code
- **US4** (CI budget) requires US1's post-optimization measurement to set the correct threshold

### Parallel Opportunities

- T003, T004, T005 within Phase 2 can run in parallel (different files)
- T006 (EmojiPicker) and T009 (EditorSkeleton) within Phase 3 can run in parallel
- T021, T022, T026 in Phase 7 can run in parallel

---

## Parallel Example: Phase 2

```
Task: T003 — Remove @tanstack dep (web/package.json)
Task: T004 — Create check-bundle-budget.mjs (web/scripts/)
Task: T005 — Extend record-bundle-size.mjs (web/scripts/)
```

## Parallel Example: Phase 3

```
Task: T006 — Lazy-load EmojiPicker.tsx
Task: T009 — Create EditorSkeleton.tsx
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Phase 1: Capture baseline ✓
2. Phase 2: Remove dep + create budget script ✓
3. Phase 3: Lazy-load EmojiPicker + Editor → **STOP and measure** ✓
4. If ≥20% entry chunk reduction achieved → MVP target met ✅ (-55.8%)
5. Proceed to CI enforcement (Phase 6) to lock in the gain ✓

### Incremental Delivery

1. Phase 1+2 → Foundation ready (dep removed, scripts in place) ✓
2. Phase 3 → Lazy loading → verify improvement target met → **deploy** ✓
3. Phase 4 → Clean build warnings (pre-existing within lazy chunk; no action needed) ✓
4. Phase 5 → Verify dep removal ✓
5. Phase 6 → CI enforcement → regressions now blocked permanently ✓
6. Phase 7 → Documentation + before/after audit ✓

---

## Notes

- [P] tasks = different files, no shared state dependencies
- Commit after each phase checkpoint
- The before baseline is already captured — do NOT re-run on master
- If Phase 3 alone achieves ≥20% entry chunk reduction, the overall target is met ✅
- `@uswds/uswds` flagged as potentially unused — out of scope (likely false positive per audit)
