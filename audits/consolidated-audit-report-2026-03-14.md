# Consolidated Audit Report

**Repository:** `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`
**Consolidation Date:** 2026-03-14

This document records audit findings updated or captured on 2026-03-14. For the full historical baseline see `audits/consolidated-audit-report-2026-03-10.md` (frozen).

---

## 4. Database Query Efficiency

_Source: `audits/deliverables/04-database-query-efficiency.md`, `audits/artifacts/db-query-efficiency-baseline.json` (re-captured 2026-03-14T16:33:08Z)_

### Measurement Method

Query counts measured by instrumenting `pool.query` at the API layer and replaying six authenticated user flows against a locally running API and PostgreSQL instance with freshly seeded data (`pnpm db:seed`). EXPLAIN ANALYZE run directly in psql against `ship_master`.

### 2026-03-14 Baseline — Query Counts per User Flow

| User Flow | Total Queries | Slowest Query (ms) | N+1 Detected? | Repeated Query Count |
|-----------|-------------:|-------------------:|:-------------:|---------------------:|
| Load main page | 52 | 4.12 | Yes | 9 |
| View a document | 16 | 2.49 | No | 4 |
| List issues | 17 | 4.11 | No | 4 |
| Load sprint board | 16 | 1.98 | No | 3 |
| Accountability action-items | 12 | 1.38 | No | 2 |
| Search content | **4** | 1.40 | No | 1 |

**Note:** Search content is at 4 queries, confirming the optimization from spec 004 (5 → 4, -20%) is stable. The main page N+1 (9 repeated queries) persists and is tracked separately.

### EXPLAIN ANALYZE — Hotspot Queries (2026-03-14)

#### Search Content — Merged CTE (people + documents UNION ALL)

| Metric | Value |
|--------|------:|
| Execution time | 0.229 ms |
| Planning time | 1.537 ms |
| Plan | Bitmap Index Scan (idx_documents_person_user_id) for people + Seq Scan (4 document types) |
| Latency target (< 5 ms) | **Met** |
| Plan stability | **Stable** (consistent with 2026-03-13 after runs) |

#### Accountability Sprint Hotspot — Batched Sprint Query

| Metric | Value |
|--------|------:|
| Execution time | 0.109 ms |
| Planning time | 2.086 ms |
| Plan | Hash Right Join (sprint documents and document_associations) |
| Latency target (< 5 ms) | **Met** |
| Plan stability | **Stable** |

### T012 Index Decision

**T012 SKIPPED — no migration created.**

Both hotspot queries are within latency targets and have stable plans. A `%ILIKE%` wildcard title search precludes B-tree index use; a GIN pg_trgm index would be required for any benefit but is not justified at current latency (0.229 ms). The conditional trigger for T012 is not met.

### Compared to 2026-03-10 Baseline

| Flow | 2026-03-10 | 2026-03-14 | Delta |
|------|----------:|----------:|------:|
| Load main page | 54 | 52 | -2 |
| View a document | 16 | 16 | 0 |
| List issues | 17 | 17 | 0 |
| Load sprint board | 14 | 16 | +2 (sprint board enhancements) |
| Search content | 5 | **4** | **-1 (-20%)** |
| Accountability action-items | — | 12 | new flow |

Search content -20% gain confirmed stable. Main page query reduction is net -2 vs 2026-03-10 baseline.

---

## 6. Runtime Errors and Edge Cases (Track D)

**Measurement date:** 2026-03-14
**Method:** Static analysis of `web/src/` source tree + full unit test suite run.
**Full browser-capture re-measurement:** Pending (requires live Playwright session).

### Prior State (2026-03-10 Baseline)

| Metric | Baseline |
|--------|---------|
| Console `error` entries | 24 |
| Unhandled promise rejections | 1 |
| Silent failures (no UI feedback) | 5 |

### 2026-03-14 Code-Level Findings

**Unhandled promise rejections — Target: 0 — Status: MET (code level)**

Both async functions in `Login.tsx` that previously generated unhandled rejections are now fully wrapped:
- `checkSetup()` (lines 79–93): `try/catch` wraps the `fetch`; errors logged, not re-thrown.
- `checkCaiaStatus()` (lines 96–108): same pattern; uses `console.debug` (not `console.error`) for the unavailable case.

No bare `.then()` chains without `.catch()` were found in auth-critical paths.

**Console error volume — Target: ≤ 5 — Status: UNCONFIRMED (browser capture pending)**

The source contains 47 `console.error` call sites across `web/src/`. Most are conditional — they fire only on network failures or user-triggered errors, not on normal page loads. The pre-auth 401 noise driving the 24-error baseline is structurally reduced by the `useAuth` session guard, but a live browser capture is required to confirm the runtime count is ≤5.

**Silent failures — Target: 0 — Status: PARTIALLY MET**

- `IssuesList.tsx`: error and empty states render with `role="status" aria-live="polite"` (lines 1063, 1083) — confirmed.
- `PlanQualityBanner.tsx`: 8 `.catch(() => {})` call sites (lines 155, 166, 198, 221, 401, 411, 442, 465) swallow AI plan-quality API errors silently. Primary remaining gap.

**Unit test suite:** 538 tests, 34 files — all passing.

### Assessment

| Metric | Before | Target | 2026-03-14 Code Analysis | Gap |
|--------|-------:|-------:|--------------------------|-----|
| Console `error` entries | 24 | ≤ 5 | Structurally reduced; runtime count unconfirmed | Pending live measurement |
| Unhandled promise rejections | 1 | 0 | 0 (code level confirmed) | None |
| Silent failures | 5 | 0 | 1 component remaining (`PlanQualityBanner.tsx`) | 8 swallowed catches |
