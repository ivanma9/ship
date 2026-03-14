# Quickstart: Runtime Resilience Implementation

## Execution Order

1. Update the document patch contract in [api/src/openapi/schemas/documents.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/openapi/schemas/documents.ts) and web request-error parsing in [web/src/lib/http-error.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/http-error.ts).
2. Implement title CAS in [api/src/routes/documents.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents.ts) and extend [api/src/routes/documents.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents.test.ts).
3. Wire title conflict state through [web/src/pages/UnifiedDocumentPage.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/UnifiedDocumentPage.tsx), [web/src/components/UnifiedEditor.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.tsx), and [web/src/pages/PersonEditor.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/PersonEditor.tsx).
4. Refactor reconnect turbulence handling in [web/src/lib/api.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/api.ts) with targeted unit coverage.
5. Extend [web/src/hooks/useAutoSave.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/hooks/useAutoSave.ts) for exponential backoff and terminal failure, then connect sticky UI state in the editor callers.
6. Add E2E coverage with fixture updates in [e2e/fixtures/isolated-env.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/fixtures/isolated-env.ts).

## Verification Commands

```bash
pnpm type-check
pnpm test
pnpm --filter @ship/web test
```

For E2E, use the repo’s required runner workflow rather than invoking the suite directly.

## Manual Verification Focus

- Two browser sessions editing the same title show conflict instead of silent overwrite.
- Temporary reconnect/auth turbulence does not immediately redirect to login.
- Repeated autosave failure produces a persistent visible error that clears only after a later successful save.

## Validation Results

- 2026-03-11: `pnpm type-check` passed.
- 2026-03-11: `pnpm --filter @ship/api exec vitest run src/routes/documents.test.ts` passed.
- 2026-03-11: `pnpm --filter @ship/web exec vitest run src/lib/http-error.test.ts src/lib/api.test.ts src/hooks/useAutoSave.test.ts` passed.
- 2026-03-11: `pnpm exec playwright test e2e/runtime-resilience-title-conflict.spec.ts --grep "propagates title updates between two authenticated users on the same document" --workers=1` passed.
- 2026-03-11: E2E specs were added for title conflict, reconnect turbulence, and autosave terminal failure, but the required repo-specific E2E runner was not invoked in this session.
- 2026-03-14: `pnpm type-check` passed (all 3 packages: shared, api, web).
- 2026-03-14: `pnpm --filter web exec vitest run` on http-error.test.ts, api.test.ts, useAutoSave.test.ts, UnifiedEditor.conflict.test.tsx, UnifiedEditor.autosave.test.tsx — 5 test files, 20 tests passed.
- 2026-03-14: Confirmed all 002 implementation tasks complete (T005–T029). Only T031 (E2E runner) remains.
- 2026-03-14 T031: All 4 E2E resilience tests passed (34.5s, 2 workers):
  - `runtime-resilience-autosave.spec.ts` → shows sticky autosave failure and clears after later success
  - `runtime-resilience-reconnect.spec.ts` → stays on active document during transient reconnect turbulence
  - `runtime-resilience-title-conflict.spec.ts` (×2) → preserves local title through transient conflict; propagates titles between two authenticated users
