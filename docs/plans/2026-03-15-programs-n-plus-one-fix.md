# Programs N+1 Query Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace correlated subqueries in `programs.ts` list and detail routes with lateral joins so all counts are computed in a single query pass.

**Architecture:** Both the list (`GET /`) and detail (`GET /:id`) routes use identical correlated `SELECT COUNT(*)` subqueries for `issue_count` and `sprint_count`. These run once per row. Replace both with `LEFT JOIN ... GROUP BY` derived tables that aggregate across all relevant rows in a single pass.

**Tech Stack:** PostgreSQL, TypeScript, Express, `pg` pool, `vitest` for unit tests.

---

### Task 1: Understand the current query shape

**Files:**
- Read: `api/src/routes/programs.ts:72-101` (list route)
- Read: `api/src/routes/programs.ts:113-141` (detail route)

**Step 1: Read and understand the current queries**

The two correlated subqueries that need replacing (same pattern in both routes):

```sql
-- BEFORE (runs once per program row — N+1)
(SELECT COUNT(*) FROM documents i
 JOIN document_associations da ON da.document_id = i.id AND da.related_id = d.id AND da.relationship_type = 'program'
 WHERE i.document_type = 'issue') as issue_count,

(SELECT COUNT(*) FROM documents s
 JOIN document_associations da ON da.document_id = s.id AND da.related_id = d.id AND da.relationship_type = 'program'
 WHERE s.document_type = 'sprint') as sprint_count
```

**Step 2: Confirm what the replacement looks like**

```sql
-- AFTER (derived tables, joined once)
LEFT JOIN (
  SELECT da.related_id, COUNT(*) as cnt
  FROM documents i
  JOIN document_associations da ON da.document_id = i.id AND da.relationship_type = 'program'
  WHERE i.document_type = 'issue'
  GROUP BY da.related_id
) ic ON ic.related_id = d.id
LEFT JOIN (
  SELECT da.related_id, COUNT(*) as cnt
  FROM documents s
  JOIN document_associations da ON da.document_id = s.id AND da.relationship_type = 'program'
  WHERE s.document_type = 'sprint'
  GROUP BY da.related_id
) sc ON sc.related_id = d.id
```

And in the SELECT clause, replace the subquery expressions with:
```sql
COALESCE(ic.cnt, 0) as issue_count,
COALESCE(sc.cnt, 0) as sprint_count
```

No changes to `extractProgramFromRow` — it already reads `row.issue_count` and `row.sprint_count`.

---

### Task 2: Update the list route query

**Files:**
- Modify: `api/src/routes/programs.ts:72-93`

**Step 1: Replace the SELECT clause and add the LEFT JOINs**

The full updated query string (replace lines 72-93):

```typescript
let query = `
  SELECT d.id, d.title, d.properties, d.archived_at, d.created_at, d.updated_at,
         COALESCE((d.properties->>'owner_id')::uuid, d.created_by) as owner_id,
         u.name as owner_name, u.email as owner_email,
         COALESCE(ic.cnt, 0) as issue_count,
         COALESCE(sc.cnt, 0) as sprint_count
  FROM documents d
  LEFT JOIN users u ON u.id = COALESCE((d.properties->>'owner_id')::uuid, d.created_by)
  LEFT JOIN (
    SELECT da.related_id, COUNT(*) as cnt
    FROM documents i
    JOIN document_associations da ON da.document_id = i.id AND da.relationship_type = 'program'
    WHERE i.document_type = 'issue'
    GROUP BY da.related_id
  ) ic ON ic.related_id = d.id
  LEFT JOIN (
    SELECT da.related_id, COUNT(*) as cnt
    FROM documents s
    JOIN document_associations da ON da.document_id = s.id AND da.relationship_type = 'program'
    WHERE s.document_type = 'sprint'
    GROUP BY da.related_id
  ) sc ON sc.related_id = d.id
  WHERE d.workspace_id = $1 AND d.document_type = 'program'
    AND ${VISIBILITY_FILTER_SQL('d', '$2', '$3')}
`;
```

**Step 2: Verify the rest of the list handler is unchanged**

Lines after the query (params, `includeArchived` filter, `ORDER BY`, `pool.query`, response) are untouched.

---

### Task 3: Update the detail route query

**Files:**
- Modify: `api/src/routes/programs.ts:114-129`

**Step 1: Replace the inline query in `pool.query`**

```typescript
const result = await pool.query(
  `SELECT d.id, d.title, d.properties, d.archived_at, d.created_at, d.updated_at,
          COALESCE((d.properties->>'owner_id')::uuid, d.created_by) as owner_id,
          u.name as owner_name, u.email as owner_email,
          COALESCE(ic.cnt, 0) as issue_count,
          COALESCE(sc.cnt, 0) as sprint_count
   FROM documents d
   LEFT JOIN users u ON u.id = COALESCE((d.properties->>'owner_id')::uuid, d.created_by)
   LEFT JOIN (
     SELECT da.related_id, COUNT(*) as cnt
     FROM documents i
     JOIN document_associations da ON da.document_id = i.id AND da.relationship_type = 'program'
     WHERE i.document_type = 'issue'
     GROUP BY da.related_id
   ) ic ON ic.related_id = d.id
   LEFT JOIN (
     SELECT da.related_id, COUNT(*) as cnt
     FROM documents s
     JOIN document_associations da ON da.document_id = s.id AND da.relationship_type = 'program'
     WHERE s.document_type = 'sprint'
     GROUP BY da.related_id
   ) sc ON sc.related_id = d.id
   WHERE d.id = $1 AND d.workspace_id = $2 AND d.document_type = 'program'
     AND ${VISIBILITY_FILTER_SQL('d', '$3', '$4')}`,
  [id, workspaceId, userId, isAdmin]
);
```

---

### Task 4: Manual smoke test

**Step 1: Start the API**

```bash
cd /Users/ivanma/Desktop/gauntlet/ShipShape/ship
pnpm dev:api
```

**Step 2: Hit the list endpoint**

```bash
# Replace TOKEN and WORKSPACE as appropriate
curl -s http://localhost:3000/api/programs \
  -H "Cookie: <your-session-cookie>" | jq '.[0] | {id, name, issue_count, sprint_count}'
```

Expected: `issue_count` and `sprint_count` are numbers (≥ 0), not null.

**Step 3: Hit the detail endpoint**

```bash
curl -s http://localhost:3000/api/programs/<some-id> \
  -H "Cookie: <your-session-cookie>" | jq '{id, name, issue_count, sprint_count}'
```

Expected: same shape, correct counts.

---

### Task 5: Run existing tests

**Step 1:**

```bash
cd /Users/ivanma/Desktop/gauntlet/ShipShape/ship
pnpm test
```

Expected: all tests pass. If any programs-related test fails, the failure message will indicate whether counts changed unexpectedly.

---

### Task 6: Commit

```bash
git add api/src/routes/programs.ts
git commit -m "$(cat <<'EOF'
perf(programs): replace correlated subqueries with derived-table joins

Why: The list and detail routes ran two correlated SELECT COUNT(*) subqueries
per program row, causing N+1 query load on the programs list. Replacing them
with LEFT JOIN derived tables computes all counts in a single query pass.
EOF
)"
```

---

## Notes

- The `documents.ts:268-292` sequential owner lookups are a separate, lower-priority issue (detail route only, 1-2 extra queries per request). Plan a follow-up if needed.
- No schema migrations required — this is a query-only change.
- `extractProgramFromRow` reads `row.issue_count` / `row.sprint_count` unchanged; the column aliases in the new query match exactly.
