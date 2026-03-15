# Improvement Plan — Feedback Response

**Context:** Submission received "fine and a pass" with three categories needing attention to strengthen the submission. This plan addresses each gap using the GFA Week 4 ShipShape spec as the requirements guide.

---

## Feedback Summary

| Category | Feedback | Spec Target |
|----------|----------|-------------|
| **Type Safety** | Missed target | Eliminate 25% of violations (1,283 → ≤962) |
| **Runtime Errors** | Fixes applied but core metric not re-measured | Fix 3 gaps; before/after proof mandatory |
| **Database Query Efficiency** | Only 1 of 5 flows improved (search); most query-heavy flow untouched | 20% reduction on ≥1 flow OR 50% on slowest query |

---

## Gap 1: Type Safety — Hit the 25% Target

### Current State
- **Baseline:** 1,283 core violations
- **Current:** 1,143 (−10.9%)
- **Target:** ≤962 (−25%)
- **Gap:** −181 violations needed

### Plan (from `docs/TODO.md`)

| Phase | Scope | Est. Reduction | Parallel? |
|-------|-------|----------------|-----------|
| **Phase 1** | `weeks.ts`, `issues.ts` — AuthenticatedRequest, typed params, remove `!` | −120 | weeks.ts ∥ issues.ts |
| **Phase 2** | `ReviewsPage.tsx`, `App.tsx`, `IssuesList.tsx` — explicit types | −110 | All 3 in parallel |
| **Phase 3** | `transformIssueLinks.test.ts` + remaining `as any` in tests | −70 | Sequential |
| **Phase 4** | Lower CI ceiling, add to `.github/workflows/`, update deliverable | lock-in | After 1–3 |

### Definition of Done
- [ ] `node scripts/type-violation-scan.cjs` shows ≤962 core violations
- [ ] `scripts/check-type-ceiling.mjs` updated to new ceiling
- [ ] CI step added (or ceiling updated) in `.github/workflows/ci.yml`
- [ ] `audits/deliverables/01-type-safety.md` updated with confirmed measurement
- [ ] All tests pass (`pnpm test`)

### Reference
- `docs/TODO.md` (phases 1–4)
- `docs/plans/2026-03-12-type-safety-remediation.md` (detailed task steps)

---

## Gap 2: Runtime Errors — Re-measure and Document

### Current State
- Fixes applied: empty-state error handling, keyboard row handler, Yjs collision tracking
- **Problem:** After-state console error counts were never re-captured under identical conditions
- Spec requires: "Every improvement must include a reproducible benchmark or measurement showing the before state and the after state"

### Plan

#### Step 1: Re-measure (Required)
1. Run app locally (`pnpm dev`)
2. Navigate all 5 major flows: main page, doc view, issues, sprint board, search
3. Capture browser console output (DevTools → Console → Save as)
4. Count: console `error` entries, unhandled promise rejections, silent failures
5. Record in `audits/deliverables/06-runtime-errors-edge-cases.md`

**Targets (from TODO):**
- Console errors: ≤5
- Unhandled promise rejections: 0
- Silent failures: 0

#### Step 2: If Targets Not Met — Apply Additional Fixes
Known sources from baseline:
- **Pre-auth 401 noise:** Multiple `401 Unauthorized` on initial load before auth resolves
- **`checkSetup` unhandled rejection:** `Login.tsx` line 78 — wrap in `.catch()` or try/catch
- **Silent fetch failures:** 5 locations with no user-visible error state

#### Step 3: Document
- Update `audits/deliverables/06-runtime-errors-edge-cases.md` with:
  - Before table (24 errors, 1 rejection, 5 silent)
  - After table (actual measured numbers)
  - Methodology (same flows, same capture method)
  - Screenshot or log excerpt as evidence

### Definition of Done
- [ ] Console log captured under identical conditions (same 5 flows)
- [ ] Before/after table in deliverable with concrete numbers
- [ ] If targets missed: at least one additional fix applied and re-measured
- [ ] Evidence artifact saved (e.g. `audits/artifacts/console-after-remix.log`)

### Reference
- `audits/deliverables/06-runtime-errors-edge-cases.md`
- `audits/artifacts/console-main.log` (baseline capture)
- `docs/TODO.md` (Runtime Errors section)

---

## Gap 3: Database Query Efficiency — Improve Most Query-Heavy Flow

### Current State
- **Search content:** 5 → 4 queries (−20%) ✅ **Met target**
- **Load main page:** 54 → 53 queries (−1.9%) ❌ **Most query-heavy, barely touched**
- **Other flows:** Unchanged (view document 16, list issues 17, sprint board 14)

### Problem
The main page (54 queries) is the heaviest flow. It has:
- N+1 detected: 9 repeated queries
- Source: `api/src/services/accountability.ts` — `checkMissingStandups`, `checkSprintAccountability`, `checkWeeklyPersonAccountability`

### Plan

#### Step 1: Trace the 9 Repeated Queries
1. Run the db-query-efficiency audit script with query logging
2. Identify which exact query pattern repeats 9 times
3. Map to the accountability service functions

#### Step 2: Batch the N+1 in Accountability
From `audits/database-query-efficiency-audit-2026-03-10.md`:
- Batch per-sprint standup checks into set-based queries
- Batch sprint issue counts instead of querying once per sprint
- `checkWeeklyPersonAccountability` runs twice (current + next sprint) — consider consolidating

#### Step 3: Target
- **20% reduction on Load main page:** 54 → ≤44 queries (need −11)
- **OR** 50% improvement on slowest query in that flow (currently 3.39 ms → target ≤1.7 ms)

#### Step 4: Re-run Audit and Document
1. Execute same 5 flows with instrumented `pool.query`
2. Save to `audits/artifacts/db-query-efficiency-after2.json` (or similar)
3. Update `audits/deliverables/04-database-query-efficiency.md` with:
   - Load main page: before 54, after X, delta %
   - EXPLAIN ANALYZE for any changed queries
   - Root cause and fix description

### Definition of Done
- [ ] Load main page: ≥20% query reduction (54 → ≤44) OR slowest query ≥50% faster
- [ ] Before/after artifact with identical flow execution
- [ ] `audits/deliverables/04-database-query-efficiency.md` updated with evidence
- [ ] All tests pass

### Reference
- `audits/deliverables/04-database-query-efficiency.md`
- `audits/artifacts/db-query-efficiency-baseline.json`
- `audits/database-query-efficiency-audit-2026-03-10.md`
- `api/src/services/accountability.ts`

---

## Execution Order

| Priority | Gap | Est. Effort | Dependencies |
|----------|-----|-------------|--------------|
| 1 | **Runtime re-measurement** | 1–2 hours | None — do first to establish baseline |
| 2 | **Database (main page)** | 4–8 hours | None |
| 3 | **Type safety** | 1–2 days | None |

**Recommendation:** Do runtime re-measurement first (quick win, proves methodology). Then tackle database (high impact, addresses "most query-heavy flow untouched"). Type safety last (largest effort, but well-specified in TODO).

---

## Spec Alignment Checklist (GFA Week 4)

From the PDF:

- [ ] **Before/After proof mandatory** — Every improvement has reproducible measurement
- [ ] **Tests must still pass** — `pnpm test` after each change
- [ ] **Document reasoning** — What changed, why, tradeoffs
- [ ] **No cosmetic changes** — Only changes that support measurable improvement
- [ ] **Commit discipline** — Separate commits, descriptive messages, "Why:" paragraphs

---

## Files to Update

| File | When |
|------|------|
| `audits/deliverables/01-type-safety.md` | After type safety phases complete |
| `audits/deliverables/06-runtime-errors-edge-cases.md` | After runtime re-measure + any fixes |
| `audits/deliverables/04-database-query-efficiency.md` | After main page query batching |
| `scripts/check-type-ceiling.mjs` | After each type safety phase |
| `.github/workflows/ci.yml` | After type safety Phase 4 |
