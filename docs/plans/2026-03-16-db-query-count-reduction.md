# DB Query Count Reduction — Approach A Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce `pool.query()` call counts across 5 main user flows by eliminating redundant lookups and consolidating sequential queries that can be merged.

**Architecture:** Three targeted changes to backend route/service code — (1) hoist shared workspace + person data fetched redundantly across accountability sub-functions, (2) merge sequential plan+retro+prevRetro queries in `dashboard.ts` my-week handler into a single CTE query, (3) merge the two workspace membership queries in `auth.ts` `/me` handler into one. No API contract changes; no frontend changes; no new tables or migrations.

**Tech Stack:** Node 20, Express, `pg` pool, TypeScript 5.x strict, Vitest

---

## Expected Impact

| Flow | Before | After | Δ |
|------|-------:|------:|--:|
| Load main page | 54 | ~41 | −13 |
| View a document | 16 | ~13 | −3 |
| List issues | 17 | ~14 | −3 |
| Sprint board | 16 | ~14 | −2 |
| Search | 4 | 4 | 0 |

---

## Task 1: Hoist workspace + person lookups in `accountability.ts`

**Problem:** `checkMissingAccountability` fetches `sprint_start_date` and the user's `person` doc (2 queries). Then it calls `checkMissingStandups`, `checkSprintAccountability`, `checkWeeklyPersonAccountability` (×2), and `checkChangesRequested`. Several of these sub-functions re-query the same data independently. Hoisting the shared data and passing it as parameters eliminates ~5–6 redundant queries.

**Files:**
- Modify: `api/src/services/accountability.ts`
- Test: `api/src/__tests__/accountability.test.ts` (create if missing)

**Queries eliminated:** `sprint_start_date` re-fetches in sub-functions (~2), redundant person-doc lookups (~2–3).

---

### Step 1.1: Read current sub-function signatures

Read `api/src/services/accountability.ts` lines 192–300 (`checkMissingStandups`) and lines 289–400 (`checkSprintAccountability`) and lines 398–520 (`checkWeeklyPersonAccountability`) to confirm which ones independently query `sprint_start_date` or person docs.

---

### Step 1.2: Write a failing test that counts queries

**File:** `api/src/__tests__/accountability.query-count.test.ts`

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { pool } from '../db/client.js';
import { checkMissingAccountability } from '../services/accountability.js';

describe('checkMissingAccountability query count', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('fetches sprint_start_date exactly once', async () => {
    const querySpy = vi.spyOn(pool, 'query');
    // Mock all queries to return minimal valid data
    querySpy.mockImplementation(async (sql: any) => {
      const text = typeof sql === 'string' ? sql : sql?.text ?? '';
      if (text.includes('sprint_start_date')) {
        return { rows: [{ sprint_start_date: '2025-12-16' }], rowCount: 1 } as any;
      }
      if (text.includes("document_type = 'person'")) {
        return { rows: [{ id: 'person-1' }], rowCount: 1 } as any;
      }
      return { rows: [], rowCount: 0 } as any;
    });

    await checkMissingAccountability('user-1', 'ws-1');

    const sprintStartDateCalls = querySpy.mock.calls.filter(([sql]) => {
      const text = typeof sql === 'string' ? sql : (sql as any)?.text ?? '';
      return text.includes('sprint_start_date');
    });

    expect(sprintStartDateCalls.length).toBe(1);
  });
});
```

**Run:** `pnpm --filter @ship/api test api/src/__tests__/accountability.query-count.test.ts`
**Expected:** FAIL — `sprint_start_date` is fetched more than once

---

### Step 1.3: Refactor sub-functions to accept pre-fetched workspace metadata

In `api/src/services/accountability.ts`:

1. Define a shared context type near the top of the file:

```typescript
type WorkspaceContext = {
  workspaceStartDate: Date;
  sprintDuration: number;
  currentSprintNumber: number;
  todayStr: string;
  today: Date;
};
```

2. In `checkMissingAccountability` (line ~99): the two existing queries stay here. Extract the computed date values into a `WorkspaceContext` object and pass it to each sub-function instead of having sub-functions re-query.

3. Update `checkMissingStandups` signature from:
```typescript
async function checkMissingStandups(
  userId: string,
  workspaceId: string,
  currentSprintNumber: number,
  todayStr: string
)
```
to accept `ctx: WorkspaceContext` instead of `currentSprintNumber` + `todayStr` — it already receives these, so this is just cleanup.

4. Update `checkSprintAccountability` — remove its internal date-math that duplicates the parent's computation; receive `ctx` instead.

5. Update `checkWeeklyPersonAccountability` — same.

6. **Key query to eliminate:** If any sub-function independently calls `pool.query('SELECT sprint_start_date ...')`, remove that call and use `ctx.workspaceStartDate` instead.

---

### Step 1.4: Run the test to verify it passes

```bash
pnpm --filter @ship/api test api/src/__tests__/accountability.query-count.test.ts
```
Expected: PASS

---

### Step 1.5: Run full test suite to confirm no regressions

```bash
pnpm --filter @ship/api test
```
Expected: all tests pass

---

### Step 1.6: Commit

```bash
git add api/src/services/accountability.ts api/src/__tests__/accountability.query-count.test.ts
git commit -m "perf(accountability): hoist workspace+person lookups to eliminate redundant queries

Why: Each checkMissing* sub-function was independently fetching sprint_start_date
and computing date context that the parent already had, adding ~4-6 extra pool.query
calls per /api/accountability/action-items request."
```

---

## Task 2: Merge plan + retro + prevRetro queries in `dashboard.ts` my-week handler

**Problem:** `GET /api/dashboard/my-week` fires three sequential queries to fetch the weekly plan, weekly retro, and previous week retro for a user (lines ~578, ~601, ~626 in `dashboard.ts`). All three hit the `documents` table filtered by `workspace_id`, `document_type`, `person_id`, and `week_number`. They can be merged into a single query that fetches all three in one pass.

**Files:**
- Modify: `api/src/routes/dashboard.ts`
- Test: `api/src/routes/dashboard.coverage.test.ts`

**Queries eliminated:** 2 (plan+retro+prevRetro: 3 queries → 1 query)

---

### Step 2.1: Write a failing test verifying plan/retro fetched in one query

**File:** `api/src/routes/dashboard.coverage.test.ts` — add a new test:

```typescript
it('fetches plan, retro, and previous retro in a single query', async () => {
  const querySpy = vi.spyOn(pool, 'query');
  // ... set up authenticated request to GET /api/dashboard/my-week
  // ... mock pool.query responses as needed

  const weeklyDocQueries = querySpy.mock.calls.filter(([sql]) => {
    const text = typeof sql === 'string' ? sql : (sql as any)?.text ?? '';
    return text.includes('weekly_plan') || text.includes('weekly_retro');
  });

  expect(weeklyDocQueries.length).toBe(1);
});
```

**Run:** `pnpm --filter @ship/api test dashboard`
**Expected:** FAIL — currently 3 separate weekly_plan/weekly_retro queries

---

### Step 2.2: Replace the three queries with a single CTE query

In `api/src/routes/dashboard.ts`, replace the three sequential queries (plan ~line 578, retro ~line 601, prevRetro ~line 626) with:

```typescript
// Fetch plan, retro, and previous retro in one query
const weeklyDocsResult = await pool.query(
  `SELECT id, title, content, properties, created_at, updated_at,
          document_type,
          (properties->>'week_number')::int AS week_number
   FROM documents
   WHERE workspace_id = $1
     AND document_type IN ('weekly_plan', 'weekly_retro')
     AND (properties->>'person_id') = $2
     AND (properties->>'week_number')::int IN ($3, $4)
     AND archived_at IS NULL
     AND deleted_at IS NULL
   ORDER BY document_type, (properties->>'week_number')::int DESC`,
  [workspaceId, personId, targetWeekNumber, previousWeekNumber]
);

// Extract individual docs from the combined result
const planRow = weeklyDocsResult.rows.find(
  r => r.document_type === 'weekly_plan' && r.week_number === targetWeekNumber
) ?? null;
const retroRow = weeklyDocsResult.rows.find(
  r => r.document_type === 'weekly_retro' && r.week_number === targetWeekNumber
) ?? null;
const prevRetroRow = weeklyDocsResult.rows.find(
  r => r.document_type === 'weekly_retro' && r.week_number === previousWeekNumber
) ?? null;

// Build plan/retro/previousRetro objects same as before
const plan = planRow ? { id: planRow.id, title: planRow.title, ... } : null;
const retro = retroRow ? { ... } : null;
const previousRetro = prevRetroRow ? { ... } : { id: null, title: null, ... };
```

Delete the three old separate query blocks. Keep all downstream object-building logic unchanged.

---

### Step 2.3: Run the test to verify it passes

```bash
pnpm --filter @ship/api test dashboard
```
Expected: PASS

---

### Step 2.4: Run full test suite

```bash
pnpm --filter @ship/api test
```
Expected: all tests pass

---

### Step 2.5: Commit

```bash
git add api/src/routes/dashboard.ts api/src/routes/dashboard.coverage.test.ts
git commit -m "perf(dashboard): merge plan+retro+prevRetro into single query in my-week handler

Why: Three sequential queries to documents for weekly_plan, weekly_retro, and
previous weekly_retro were fetching from the same table with the same filters.
A single IN ('weekly_plan','weekly_retro') query with week_number IN (N, N-1)
returns all three rows in one round-trip."
```

---

## Task 3: Merge the two workspace queries in `auth.ts` `/me` handler

**Problem:** `GET /api/auth/me` fires two workspace queries back-to-back (lines ~276 and ~288). The first fetches all workspaces for the user; the second fetches the current workspace by ID. Since the first query already returns all workspaces including the current one, the second query is redundant — the current workspace can be found by filtering the first result.

**Files:**
- Modify: `api/src/routes/auth.ts`
- Test: `api/src/__tests__/auth.test.ts`

**Queries eliminated:** 1

---

### Step 3.1: Write a failing test

In `api/src/__tests__/auth.test.ts`, add:

```typescript
it('GET /me fires at most 2 pool.query calls (user + workspaces)', async () => {
  const querySpy = vi.spyOn(pool, 'query');
  // mock user and workspace responses...

  await agent.get('/api/auth/me');

  // Should be: 1 user query + 1 workspaces query = 2 total
  // (not 3 with the separate current-workspace query)
  expect(querySpy.mock.calls.length).toBeLessThanOrEqual(2);
});
```

**Run:** `pnpm --filter @ship/api test auth`
**Expected:** FAIL — currently fires 3 queries

---

### Step 3.2: Remove the redundant current-workspace query

In `api/src/routes/auth.ts`, the `/me` handler currently does:

```typescript
// Query 2 — all workspaces
const workspacesResult = await pool.query(
  `SELECT w.id, w.name, wm.role FROM workspaces w
   JOIN workspace_memberships wm ON w.id = wm.workspace_id
   WHERE wm.user_id = $1 AND w.archived_at IS NULL`,
  [req.userId]
);

// Query 3 — current workspace (REDUNDANT)
if (req.workspaceId) {
  const currentResult = await pool.query(
    `SELECT w.id, w.name, wm.role FROM workspaces w
     LEFT JOIN workspace_memberships wm ON w.id = wm.workspace_id AND wm.user_id = $2
     WHERE w.id = $1`,
    [req.workspaceId, req.userId]
  );
  ...
}
```

Replace query 3 with a simple find on the already-fetched `workspacesResult.rows`:

```typescript
let currentWorkspace = null;
if (req.workspaceId) {
  const found = workspacesResult.rows.find(w => w.id === req.workspaceId);
  if (found) {
    currentWorkspace = { id: found.id, name: found.name, role: found.role };
  } else if (user.is_super_admin) {
    // Super-admin may not be a member — do a targeted lookup only in this case
    const currentResult = await pool.query(
      `SELECT w.id, w.name FROM workspaces w WHERE w.id = $1`,
      [req.workspaceId]
    );
    if (currentResult.rows[0]) {
      currentWorkspace = { id: currentResult.rows[0].id, name: currentResult.rows[0].name, role: 'admin' };
    }
  }
}
```

This saves 1 query for all normal users; super-admins without membership still do a targeted single-column lookup (no join needed).

---

### Step 3.3: Run the test to verify it passes

```bash
pnpm --filter @ship/api test auth
```
Expected: PASS

---

### Step 3.4: Run full test suite

```bash
pnpm --filter @ship/api test
```
Expected: all tests pass

---

### Step 3.5: Commit

```bash
git add api/src/routes/auth.ts api/src/__tests__/auth.test.ts
git commit -m "perf(auth): eliminate redundant current-workspace query in /me handler

Why: The workspaces query already returns all workspaces for the user, including
the current one. The subsequent targeted query for req.workspaceId was redundant
— we can find it in the already-fetched rows with a simple .find()."
```

---

## Task 4: Remove redundant `sprint_start_date` fetch in `standups.ts` `/status` handler

**Problem:** `GET /api/standups/status` fetches `sprint_start_date` from workspaces (line ~228) and then fires 2 more queries. The `sprint_start_date` value could be derived from `req` if it were stored in the session, but more simply: the workspace query is cheap and necessary here — **however**, this same data is also fetched by `accountability/action-items` which fires in the same page load. This is a cross-request redundancy that can't be eliminated at the DB layer without caching. **Skip this task** — the savings are 1 query and the complexity of sharing cross-request data isn't worth it.

_Mark as deferred. Revisit if a request-scoped workspace context is introduced later._

---

## Task 5: Remove redundant `sprint_start_date` fetch in `team.ts` `/people` handler

**Problem:** `GET /api/team/people` fetches `sprint_start_date` at line ~49 and uses it to compute current sprint number for allocation display. This is a legitimate need for that endpoint. Like Task 4, this is cross-request redundancy — same fix required. **Skip this task** for the same reason.

_Mark as deferred._

---

## Task 6: Re-run the audit and update deliverables

### Step 6.1: Run the full audit

```bash
tsx audits/artifacts/db-query-efficiency-audit.ts 2>&1
```

Capture the JSON output.

---

### Step 6.2: Update the "Final After" table in both deliverables

Update the "Final After — All Optimizations Applied" section in:
- `audits/deliverables/04-database-query-efficiency.md`
- `audits/deliverables/00-consolidated.md`

Update the timestamp from `2026-03-16` to the new run date and replace query counts with fresh numbers.

---

### Step 6.3: Run the EXPLAIN ANALYZE recheck

```bash
node audits/scripts/db-query-recheck.mjs
```

Confirm both targets still pass (< 5 ms).

---

### Step 6.4: Commit audit update

```bash
git add audits/deliverables/
git commit -m "docs(audit): update db query efficiency final-after table post-optimization

Why: Re-ran db-query-efficiency-audit.ts after Tasks 1-3 to capture the
cumulative effect of accountability hoisting, dashboard query merge, and
auth/me deduplication."
```

---

## Verification

After all tasks, run the full suite and the audit:

```bash
pnpm --filter @ship/api test          # all unit tests pass
pnpm --filter @ship/web test          # no regressions
tsx audits/artifacts/db-query-efficiency-audit.ts   # fresh query counts
node audits/scripts/db-query-recheck.mjs             # EXPLAIN ANALYZE still PASS
```

Expected final counts:

| Flow | Before | Target |
|------|-------:|-------:|
| Load main page | 54 | ≤ 43 |
| View a document | 16 | ≤ 14 |
| List issues | 17 | ≤ 15 |
| Sprint board | 16 | ≤ 15 |
| Search | 4 | 4 |
