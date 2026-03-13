# Type Safety Remediation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reduce core type-safety violations by ≥25% (from 554 baseline to ≤416) without any behavior changes.

**Architecture:** Three categories of violations exist: `any` annotations/assertions (277), non-null assertions `!` (276), and `@ts-ignore` (1). The dominant fixable patterns are: (1) `req.workspaceId!/req.userId!` in route handlers—fixable by introducing an `AuthenticatedRequest` type since auth middleware guarantees these; (2) `{ rows: [] } as any` in tests—fixable by a typed mock helper for `pg.QueryResult`; (3) `any[]` SQL param arrays—fixable by a `QueryParam` union type.

**Tech Stack:** TypeScript 5.x, Express.js, Vitest, pg (node-postgres), pnpm workspaces

---

## Baseline & Measurement

**Counting method** (run from repo root):
```bash
# Count all three violation types
echo "any violations:" && grep -rn ": any\b\|as any\b\|any\[\]\|<any>" --include="*.ts" --include="*.tsx" api/src web/src shared/src 2>/dev/null | grep -v "\.d\.ts" | wc -l
echo "non-null assertions (!):" && grep -En "[a-zA-Z0-9_)]+![^=]" api/src web/src --include="*.ts" --include="*.tsx" -r | grep -v "\.d\.ts\|//\|!==\|!=" | wc -l
echo "ts-ignore/expect-error:" && grep -rn "@ts-ignore\|@ts-expect-error\|@ts-nocheck" --include="*.ts" --include="*.tsx" api/src web/src | wc -l
```

**Current baseline:** 554 (277 `any` + 276 `!` + 1 `@ts-ignore`)
**Target:** ≤416 (remove ≥138)
**Estimated removals by phase:**
- Phase 1 (API routes): ~82 non-null assertions (weeks.ts:48, issues.ts:34)
- Phase 2 (Web components): ~25 `any` violations
- Phase 3 (Test mock cleanup): ~100 `as any` in tests
- Phase 4 (CI guardrail): 0 removals, prevents regression

---

## Phase 1: API Hotspots — `AuthenticatedRequest` type

**Problem:** Every route handler repeats `const workspaceId = req.workspaceId!; const userId = req.userId!;` because Express `Request` declares them optional (`string | undefined`), but auth middleware guarantees they are set before any authenticated route runs.

**Files touched:**
- Create: `api/src/types/express.ts`
- Modify: `api/src/routes/weeks.ts`
- Modify: `api/src/routes/issues.ts`
- Modify: `api/src/routes/projects.ts` (26 assertions)
- Modify: `api/src/routes/team.ts` (28 assertions)
- Modify: `api/src/routes/programs.ts` (18 assertions)

**Estimated removals:** 154 non-null assertions → net reduction ~154

---

### Task 1.1: Create `AuthenticatedRequest` type

**Files:**
- Create: `api/src/types/express.ts`

**Step 1: Write the file**

```typescript
// api/src/types/express.ts
import { Request } from 'express';

/**
 * Request type for routes that are behind authMiddleware.
 * Auth middleware guarantees workspaceId and userId are set;
 * this type makes that explicit so routes don't need `!` assertions.
 */
export interface AuthenticatedRequest extends Request {
  workspaceId: string;
  userId: string;
}
```

**Step 2: Verify TypeScript accepts it**

Run: `pnpm --filter api type-check`
Expected: no new errors (this is an additive type only)

**Step 3: Commit**

```bash
git add api/src/types/express.ts
git commit -m "feat(types): add AuthenticatedRequest to eliminate non-null assertions"
```

---

### Task 1.2: Apply `AuthenticatedRequest` to `weeks.ts`

**Files:**
- Modify: `api/src/routes/weeks.ts`

**Step 1: Add import at top of file**

Find the existing Express import line (near line 1):
```typescript
import { Request, Response, NextFunction, Router } from 'express';
```
Add after it:
```typescript
import { AuthenticatedRequest } from '../types/express.js';
```

**Step 2: Replace `req: Request` with `AuthenticatedRequest` in all route handlers**

Pattern to find across the file:
```typescript
// BEFORE (48 instances):
const workspaceId = req.workspaceId!;
const userId = req.userId!;

// AFTER:
// Just remove the ! — workspaceId and userId are string in AuthenticatedRequest
const workspaceId = req.workspaceId;
const userId = req.userId;
```

For each handler function signature, change parameter type. Look for:
```typescript
router.get('/...', async (req: Request, res: Response) => {
```
Change to:
```typescript
router.get('/...', async (req: AuthenticatedRequest, res: Response) => {
```

Also replace `any[]` params array at line 609:
```typescript
// BEFORE:
const params: any[] = [workspaceId, targetSprintNumber, userId, isAdmin];
// AFTER:
const params: (string | number | boolean | null)[] = [workspaceId, targetSprintNumber, userId, isAdmin];
```

And `any[]` at lines 1053 and 2429:
```typescript
// BEFORE:
const values: any[] = [];
// AFTER:
const values: (string | number | boolean | null | string[])[] = [];
```

**Step 3: Run type-check**

Run: `pnpm --filter api type-check`
Expected: PASS — no errors

**Step 4: Run tests**

Run: `pnpm test`
Expected: all tests PASS

**Step 5: Commit**

```bash
git add api/src/routes/weeks.ts
git commit -m "fix(types): replace non-null assertions and any[] in weeks.ts with AuthenticatedRequest"
```

---

### Task 1.3: Apply `AuthenticatedRequest` to `issues.ts`

**Files:**
- Modify: `api/src/routes/issues.ts`

**Step 1: Add import** (same pattern as Task 1.2 Step 1)

**Step 2: Fix `extractIssueFromRow` function (line 82)**

The `row` parameter comes from a pg query result. Create a minimal interface:
```typescript
// Add near top of file (after imports):
interface IssueRow {
  id: string;
  title: string;
  properties: Record<string, unknown>;
  ticket_number: number | null;
  content: unknown;
  created_at: string;
  updated_at: string;
  workspace_id: string;
  archived_at: string | null;
  deleted_at: string | null;
}

// Then change signature:
function extractIssueFromRow(row: IssueRow) {
  const props = row.properties;
  // ... rest unchanged, but change || {} to direct access since we typed it
```

**Step 3: Fix `states as any` at line 154**

```typescript
// BEFORE:
params.push(states as any);
// AFTER (params is already typed as (string | boolean | null)[]):
// Change params declaration to accept string[]:
const params: (string | boolean | null | string[])[] = [workspaceId, userId, isAdmin];
// Then:
params.push(states); // string[] accepted
```

**Step 4: Fix route handler `!` assertions and `any[]` values arrays**

Same pattern as Task 1.2 — apply `AuthenticatedRequest`, remove `!`, type values arrays.

**Step 5: Run type-check and tests**

```bash
pnpm --filter api type-check && pnpm test
```
Expected: both PASS

**Step 6: Commit**

```bash
git add api/src/routes/issues.ts
git commit -m "fix(types): replace any and non-null assertions in issues.ts"
```

---

### Task 1.4: Apply `AuthenticatedRequest` to `projects.ts`, `team.ts`, `programs.ts`

**Files:**
- Modify: `api/src/routes/projects.ts`
- Modify: `api/src/routes/team.ts`
- Modify: `api/src/routes/programs.ts`

**Step 1: Apply same pattern as 1.2/1.3 to each file**

For each file:
1. Add `import { AuthenticatedRequest } from '../types/express.js';`
2. Change `(req: Request` → `(req: AuthenticatedRequest` in route handlers
3. Remove `!` from `req.workspaceId!` and `req.userId!`
4. Change `any[]` values arrays to typed union: `(string | number | boolean | null | string[])[]`

**Step 2: Type-check and test**

```bash
pnpm --filter api type-check && pnpm test
```
Expected: PASS

**Step 3: Commit**

```bash
git add api/src/routes/projects.ts api/src/routes/team.ts api/src/routes/programs.ts
git commit -m "fix(types): apply AuthenticatedRequest across projects, team, programs routes"
```

---

## Phase 2: Web Component `any` Violations

**Files touched:**
- Modify: `web/src/components/editor/FileAttachment.tsx` (7 violations)
- Modify: `web/src/components/editor/SlashCommands.tsx` (6 violations)
- Modify: `web/src/components/editor/AIScoringDisplay.tsx` (6 violations)
- Modify: `web/src/components/editor/CommentDisplay.tsx` (4 violations)

**Estimated removals:** ~23 `any` violations

---

### Task 2.1: Fix `FileAttachment.tsx`

**Files:**
- Modify: `web/src/components/editor/FileAttachment.tsx`

**Step 1: Read the file**

```bash
cat web/src/components/editor/FileAttachment.tsx
```

Identify each `any` and whether it represents an event, a TipTap node attribute, or a DOM element.

**Step 2: Replace event `any` types**

Common patterns in TipTap extensions:
```typescript
// BEFORE:
(event: any) => { ... }
// AFTER (DOM events):
(event: Event) => { ... }
// or for input:
(event: React.ChangeEvent<HTMLInputElement>) => { ... }
```

For TipTap node attributes:
```typescript
// BEFORE:
node: any
// AFTER:
node: { attrs: Record<string, unknown> }
```

**Step 3: Type-check**

```bash
pnpm --filter web type-check
```
Expected: PASS

**Step 4: Commit**

```bash
git add web/src/components/editor/FileAttachment.tsx
git commit -m "fix(types): eliminate any in FileAttachment.tsx"
```

---

### Task 2.2: Fix `SlashCommands.tsx`, `AIScoringDisplay.tsx`, `CommentDisplay.tsx`

**Files:**
- Modify: `web/src/components/editor/SlashCommands.tsx`
- Modify: `web/src/components/editor/AIScoringDisplay.tsx`
- Modify: `web/src/components/editor/CommentDisplay.tsx`

**Step 1: Read each file, identify patterns**

For each file, check what `any` represents:
- TipTap editor/command types → look up TipTap's `Editor`, `Commands` types
- API response data → use `unknown` with type guard or inline interface
- Event handlers → use proper DOM/React event types

**Step 2: Apply targeted fixes**

For `unknown` swaps, add proper narrowing. Example:
```typescript
// BEFORE:
function handleScore(data: any) {
  const score = data.score;
}
// AFTER:
interface ScoreData { score: number; label: string }
function handleScore(data: ScoreData) {
  const score = data.score;
}
```

**Step 3: Type-check after all three files**

```bash
pnpm --filter web type-check
```
Expected: PASS

**Step 4: Commit**

```bash
git add web/src/components/editor/SlashCommands.tsx web/src/components/editor/AIScoringDisplay.tsx web/src/components/editor/CommentDisplay.tsx
git commit -m "fix(types): eliminate any in editor SlashCommands, AIScoringDisplay, CommentDisplay"
```

---

## Phase 3: Test Mock Typing Cleanup

**Problem:** 100+ instances of `{ rows: [...] } as any` in test files because `pool.query` returns `pg.QueryResult<T>` which requires many fields (`oid`, `command`, `fields`, etc.). Developers use `as any` to provide only `rows`.

**Solution:** Create a typed mock helper that fills in required QueryResult fields with safe defaults, so tests provide only `rows` without suppressing types.

**Files touched:**
- Create: `api/src/test-utils/mock-query-result.ts`
- Modify: `api/src/__tests__/activity.test.ts` (21 violations)
- Modify: `api/src/__tests__/auth.test.ts` (24 violations)
- Modify: `api/src/services/accountability.test.ts` (43 violations)
- Modify: `api/src/__tests__/transformIssueLinks.test.ts` (37 violations)
- Modify: `api/src/routes/issues-history.test.ts` (20 violations)

**Estimated removals:** ~100+ `as any` violations

---

### Task 3.1: Create typed mock helper

**Files:**
- Create: `api/src/test-utils/mock-query-result.ts`

**Step 1: Write the helper**

```typescript
// api/src/test-utils/mock-query-result.ts
import type { QueryResult, FieldDef } from 'pg';

/**
 * Creates a properly-typed QueryResult for use in Vitest mocks.
 * Avoids `as any` casts in test files.
 *
 * Usage:
 *   vi.mocked(pool.query).mockResolvedValueOnce(mockQueryResult([{ id: '1' }]));
 */
export function mockQueryResult<T extends Record<string, unknown>>(
  rows: T[],
  overrides: Partial<QueryResult<T>> = {}
): QueryResult<T> {
  return {
    rows,
    rowCount: rows.length,
    command: 'SELECT',
    oid: 0,
    fields: [] as FieldDef[],
    ...overrides,
  };
}

/**
 * Shorthand for an empty result set.
 */
export function mockEmptyResult(): QueryResult<Record<string, unknown>> {
  return mockQueryResult([]);
}
```

**Step 2: Verify it compiles**

```bash
pnpm --filter api type-check
```
Expected: PASS

**Step 3: Commit**

```bash
git add api/src/test-utils/mock-query-result.ts
git commit -m "feat(test-utils): add mockQueryResult helper to eliminate as-any in pg mocks"
```

---

### Task 3.2: Update `accountability.test.ts` (43 violations — biggest win)

**Files:**
- Modify: `api/src/services/accountability.test.ts`

**Step 1: Add import at top of test file**

```typescript
import { mockQueryResult, mockEmptyResult } from '../test-utils/mock-query-result.js';
```

**Step 2: Replace all `{ rows: [] } as any` with `mockEmptyResult()`**

Find pattern:
```typescript
.mockResolvedValueOnce({ rows: [] } as any)
```
Replace with:
```typescript
.mockResolvedValueOnce(mockEmptyResult())
```

Find pattern with data:
```typescript
.mockResolvedValueOnce({ rows: [{ id: 'person-1', name: 'Test' }] } as any)
```
Replace with:
```typescript
.mockResolvedValueOnce(mockQueryResult([{ id: 'person-1', name: 'Test' }]))
```

**Step 3: Run tests**

```bash
pnpm test -- accountability
```
Expected: all tests PASS (behavior unchanged, only types changed)

**Step 4: Commit**

```bash
git add api/src/services/accountability.test.ts
git commit -m "fix(types): replace as-any mock casts in accountability.test.ts"
```

---

### Task 3.3: Update `auth.test.ts` and `activity.test.ts`

**Files:**
- Modify: `api/src/__tests__/auth.test.ts`
- Modify: `api/src/__tests__/activity.test.ts`

**Step 1: Fix auth middleware type in mocks**

In both files, the pattern:
```typescript
authMiddleware: (req: any, res: any, next: any) => {
```
Should become:
```typescript
authMiddleware: (req: Request, res: Response, next: NextFunction) => {
```
Add import: `import { Request, Response, NextFunction } from 'express';`

**Step 2: Replace all `as any` mock results** using `mockQueryResult`/`mockEmptyResult` (same as Task 3.2)

**Step 3: Run tests**

```bash
pnpm test -- auth activity
```
Expected: PASS

**Step 4: Commit**

```bash
git add api/src/__tests__/auth.test.ts api/src/__tests__/activity.test.ts
git commit -m "fix(types): replace as-any mock casts in auth and activity tests"
```

---

### Task 3.4: Update `transformIssueLinks.test.ts` and `issues-history.test.ts`

**Files:**
- Modify: `api/src/__tests__/transformIssueLinks.test.ts`
- Modify: `api/src/routes/issues-history.test.ts`

**Step 1: For `transformIssueLinks.test.ts`**

Replace `{ ... } as any` pool mock results with `mockQueryResult(...)`.

For the result cast pattern:
```typescript
const result = await transformIssueLinks(content, workspaceId) as any;
```
Replace with the actual return type of `transformIssueLinks` (check its signature), or use `unknown` with proper narrowing:
```typescript
const result = await transformIssueLinks(content, workspaceId);
```
Then access properties via the actual type — if TypeScript errors, add `as` with the correct type instead of `any`.

For node assertions:
```typescript
// BEFORE:
expect(nodes.some((n: any) => n.text === '#10' && n.marks)).toBe(true);
// AFTER (TipTap JSON nodes):
interface TipTapNode { text?: string; marks?: unknown[] }
expect(nodes.some((n: TipTapNode) => n.text === '#10' && n.marks)).toBe(true);
```

**Step 2: Run tests**

```bash
pnpm test -- transformIssueLinks issues-history
```
Expected: PASS

**Step 3: Commit**

```bash
git add api/src/__tests__/transformIssueLinks.test.ts api/src/routes/issues-history.test.ts
git commit -m "fix(types): replace as-any casts in transformIssueLinks and issues-history tests"
```

---

## Phase 4: CI Regression Guardrail

**Goal:** After reducing violations, add a script + CI check so any PR that increases the count fails automatically.

**Files touched:**
- Create: `scripts/count-type-violations.sh`
- Modify: `.github/workflows/ci.yml` (or equivalent CI config file — check `ls .github/workflows/`)

---

### Task 4.1: Create violation-counting script

**Files:**
- Create: `scripts/count-type-violations.sh`

**Step 1: Check CI config file location**

```bash
ls .github/workflows/
```

**Step 2: Write the script**

```bash
#!/usr/bin/env bash
# scripts/count-type-violations.sh
# Counts core type-safety violations across api/src and web/src.
# Exits with non-zero if count exceeds MAX_VIOLATIONS.
#
# Usage: ./scripts/count-type-violations.sh [max_violations]
# Default max: 416 (25% reduction from 554 baseline)

set -euo pipefail

MAX=${1:-416}

ANY_COUNT=$(grep -rn ": any\b\|as any\b\|any\[\]\|<any>" \
  --include="*.ts" --include="*.tsx" api/src web/src shared/src 2>/dev/null \
  | grep -v "\.d\.ts" | wc -l | tr -d ' ')

BANG_COUNT=$(grep -rEn "[a-zA-Z0-9_)]+![^=]" \
  --include="*.ts" --include="*.tsx" \
  api/src web/src 2>/dev/null \
  | grep -v "\.d\.ts\|//\|!==" | wc -l | tr -d ' ')

SUPPRESS_COUNT=$(grep -rn "@ts-ignore\|@ts-expect-error\|@ts-nocheck" \
  --include="*.ts" --include="*.tsx" api/src web/src 2>/dev/null | wc -l | tr -d ' ')

TOTAL=$((ANY_COUNT + BANG_COUNT + SUPPRESS_COUNT))

echo "Type violation counts:"
echo "  any annotations/assertions: ${ANY_COUNT}"
echo "  non-null assertions (!):    ${BANG_COUNT}"
echo "  ts-ignore/suppress:         ${SUPPRESS_COUNT}"
echo "  TOTAL:                      ${TOTAL}"
echo "  MAX ALLOWED:                ${MAX}"

if [ "$TOTAL" -gt "$MAX" ]; then
  echo ""
  echo "ERROR: Type violation count (${TOTAL}) exceeds maximum allowed (${MAX})."
  echo "Fix type violations before merging, or update MAX_VIOLATIONS in ci.yml"
  echo "if the increase is intentional and documented."
  exit 1
fi

echo ""
echo "OK: Type violation count (${TOTAL}) is within allowed maximum (${MAX})."
```

**Step 3: Make it executable**

```bash
chmod +x scripts/count-type-violations.sh
```

**Step 4: Test the script locally**

```bash
./scripts/count-type-violations.sh
```
Expected: outputs current counts, PASS or FAIL status

**Step 5: Commit**

```bash
git add scripts/count-type-violations.sh
git commit -m "feat(ci): add type violation counting script with configurable max"
```

---

### Task 4.2: Add CI step

**Files:**
- Modify: CI config file found in Task 4.1 Step 1

**Step 1: Read the CI config**

```bash
cat .github/workflows/<filename>.yml
```

**Step 2: Add a job step after the type-check step**

Find the existing `type-check` or `lint` step and add after it:

```yaml
- name: Check type violation count
  run: ./scripts/count-type-violations.sh 416
```

The `416` is the max allowed (baseline 554 × 0.75, rounded). **This number must be updated** whenever we do further remediation passes.

**Step 3: Commit**

```bash
git add .github/workflows/<filename>.yml
git commit -m "ci: enforce type violation ceiling at 416 (25% below baseline)"
```

---

## Verification & Definition of Done

### After each phase, verify:

```bash
# 1. Type-check passes
pnpm type-check

# 2. Unit tests pass
pnpm test

# 3. Count violations (should decrease)
./scripts/count-type-violations.sh 416
```

### Definition of Done

- [ ] `./scripts/count-type-violations.sh 416` exits 0 (total ≤ 416)
- [ ] `pnpm type-check` exits 0 (no new type errors introduced)
- [ ] `pnpm test` exits 0 (no behavior regressions)
- [ ] CI step added that blocks PRs if count exceeds 416
- [ ] No new `@ts-ignore` or `@ts-expect-error` suppressions without a comment explaining why

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `AuthenticatedRequest` breaks a test that mocks `req` without `workspaceId` | Medium | Tests mock `req.workspaceId` already (via auth middleware mock); if they fail, cast mock explicitly: `const req = { workspaceId: 'x', userId: 'y' } as AuthenticatedRequest` |
| `IssueRow` interface misses a field used at runtime | Low | `extractIssueFromRow` accesses many fields; scan all uses before submitting PR. Type-check will catch typos. |
| `mockQueryResult` helper doesn't satisfy a newer pg type | Low | Check pg version in package.json; `FieldDef[]` import may vary. If needed, widen to `Partial<QueryResult<T>>` with `as QueryResult<T>`. |
| Non-null assertion removal causes `undefined` runtime error | Very Low | Auth middleware runs before all routes; the only way `workspaceId` could be undefined is if a route is registered outside of auth middleware, which type-check would catch. |

---

## Rollout Order

```
Task 1.1 → Task 1.2 → Task 1.3 → Task 1.4
                                            ↓
                              Task 2.1 → Task 2.2
                                            ↓
                    Task 3.1 → Task 3.2 → Task 3.3 → Task 3.4
                                                            ↓
                                            Task 4.1 → Task 4.2
```

Tasks within a phase are independent and can be done in any order. Phases should run sequentially so violations are removed before CI guardrail is set.
