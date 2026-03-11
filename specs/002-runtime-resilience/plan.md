# Implementation Plan: Runtime Resilience for Concurrency, Reconnect, and Autosave

**Branch**: `002-runtime-resilience` | **Date**: 2026-03-11 | **Spec**: [spec.md](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/specs/002-runtime-resilience/spec.md)
**Input**: Feature specification from `/specs/002-runtime-resilience/spec.md`

## Summary

Implement three tightly scoped runtime resilience fixes without changing the broader collaboration model: add compare-and-swap protection for document title writes, defer session-expired redirects during reconnect turbulence, and surface terminal autosave failure with backoff and sticky user-visible status. The design keeps the server as source of truth, reuses existing document update and editor status flows, and minimizes change surface to the document patch route, shared request-error handling, `web/src/lib/api.ts`, `web/src/hooks/useAutoSave.ts`, and the unified editor/document page integration.

## Technical Context

**Language/Version**: TypeScript across `api/`, `web/`, and `shared/`  
**Primary Dependencies**: Express, `pg`, React, Vite, TanStack Query, TipTap, Yjs, Zod  
**Storage**: PostgreSQL for authoritative document state; IndexedDB/Yjs cache for editor state  
**Testing**: Vitest for API and web unit/integration tests; Playwright-based E2E suite in `e2e/`  
**Target Platform**: Browser-based web application with Node.js API server  
**Project Type**: Monorepo web application with shared types  
**Performance Goals**: Preserve existing normal title-save and document-update responsiveness; keep changed write paths within the constitution target of p95 <= 400 ms on seeded local data  
**Constraints**: No offline-architecture redesign; preserve existing normal collaboration/save behavior; minimize changes outside targeted modules; redirect behavior must remain unchanged outside reconnect turbulence  
**Scale/Scope**: Active multi-user document editing, authenticated sessions, and autosave flows on the unified document editor

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Type Safety Audit**: New contracts are limited to document update payload/response fields, a typed `WRITE_CONFLICT` error payload, reconnect turbulence state, and autosave terminal-failure callbacks. Canonical shared error code stays in [shared/src/constants.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/shared/src/constants.ts); web request-error parsing extends typed metadata instead of introducing duplicate ad hoc shapes. No temporary type escapes are planned.
- **Bundle Size Audit**: No new frontend dependency is planned. Client changes reuse existing editor banners/toasts, request helpers, and hooks. Expected bundle impact is negligible and below the constitution threshold because the change is limited to existing modules and state logic.
- **API Response Time**: Changed endpoint is `PATCH /api/documents/:id` for title updates. Target remains p95 <= 400 ms on representative seeded data. Measurement approach: existing API tests plus one targeted local timing sample around conflict and non-conflict title patches.
- **Database Query Efficiency**: Title protection changes one existing `UPDATE documents` statement by adding `updated_at` compare-and-swap in the `WHERE` clause and retaining a single fallback `SELECT title, updated_at` only on conflict. No migration or new index is required because the path already filters on primary key and workspace.
- **Test Coverage and Quality**: Add unit coverage for CAS branching, reconnect retry gating, and autosave backoff state; integration coverage for `409 WRITE_CONFLICT`; E2E coverage for concurrent title edits, reconnect turbulence, and sticky autosave failure UX. Existing regression suites remain required.
- **Runtime Errors and Edge Cases**: Explicit handling is planned for stale title writes, idempotent retry, offline save failure, transient 401 turbulence, retry exhaustion, and duplicate redirect suppression. Silent failure paths are being replaced with visible user state.
- **Accessibility Compliance**: Conflict and autosave terminal-failure states will be surfaced through existing alert/status regions with keyboard focus preserved in the editor. Verification includes keyboard-only navigation and screen-reader-visible messaging in changed UI flows.

**Gate Result**: Pass. No constitution violation requires an exception.

## Project Structure

### Documentation (this feature)

```text
specs/002-runtime-resilience/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── runtime-resilience.md
└── tasks.md
```

### Source Code (repository root)

```text
api/
└── src/
    ├── openapi/
    │   └── schemas/
    │       └── documents.ts
    └── routes/
        ├── documents.ts
        └── documents.test.ts

shared/
└── src/
    └── constants.ts

web/
└── src/
    ├── components/
    │   └── UnifiedEditor.tsx
    ├── hooks/
    │   └── useAutoSave.ts
    ├── lib/
    │   ├── api.ts
    │   └── http-error.ts
    └── pages/
        ├── PersonEditor.tsx
        └── UnifiedDocumentPage.tsx

e2e/
├── fixtures/
│   └── isolated-env.ts
└── [runtime resilience specs]
```

**Structure Decision**: Keep the implementation within the existing API route, shared constants, request helper, editor hook, and unified document page/editor surfaces. No new subsystem or storage layer is introduced.

## Phase 0 Research Summary

- CAS for titles should use `expected_updated_at` as the single concurrency token instead of the current `expected_title` fallback because timestamps protect against unrelated stale state and map cleanly to a `409 WRITE_CONFLICT` contract.
- The conflict response should include both server-authoritative title metadata and the client-submitted value so the UI can refresh, explain the conflict, and offer a safe retry path without guessing.
- Redirect deferral should be centralized in `web/src/lib/api.ts` so all REST callers share the same reconnect turbulence circuit-breaker instead of adding page-specific workarounds.
- Autosave retry/backoff should remain inside `useAutoSave` and expose terminal failure through callback/state rather than moving reliability logic into each editor caller.

## Architecture and Flow Changes

### 1. Concurrent title collision divergence

**Server flow**

1. `PATCH /api/documents/:id` receives a title update with `expected_updated_at`.
2. The SQL `UPDATE documents ... WHERE id = $id AND workspace_id = $workspace AND date_trunc('milliseconds', updated_at) = date_trunc('milliseconds', $expected_updated_at)` acts as compare-and-swap.
3. If zero rows update, the route performs one authoritative read of `title` and `updated_at` and returns `409 WRITE_CONFLICT`.
4. Successful title writes continue to return the updated document body.

**Client flow**

1. The title autosave request sends `title` plus the document's last authoritative `updated_at`.
2. On success, the client updates its local concurrency token from the returned `updated_at`.
3. On `409 WRITE_CONFLICT`, the document page/editor keeps the user's typed title locally, refreshes authoritative title metadata, and shows a merge prompt or banner explaining that the title changed elsewhere.
4. The safe retry path replays the user’s current local title against the newly refreshed `updated_at` after the user confirms retry or re-applies their title.

**Touched modules**

- [api/src/routes/documents.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents.ts)
- [api/src/openapi/schemas/documents.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/openapi/schemas/documents.ts)
- [api/src/routes/documents.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents.test.ts)
- [web/src/pages/UnifiedDocumentPage.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/UnifiedDocumentPage.tsx)
- [web/src/components/UnifiedEditor.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.tsx)
- [web/src/lib/http-error.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/http-error.ts)
- [web/src/pages/PersonEditor.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/PersonEditor.tsx)

### 2. Reconnect redirect storm after transient outage

**Client flow**

1. `web/src/lib/api.ts` tracks a reconnect turbulence window after the first transient `401`/CloudFront-auth failure on an already active authenticated session.
2. During that window, state-changing and read requests defer `login?expired=true` redirects, retry within a bounded gate, and clear the turbulence state on any successful authenticated response.
3. If retries exhaust while still inside turbulence and the session remains invalid, the helper emits a single session-expired redirect and suppresses duplicate redirects until navigation occurs.
4. Outside the turbulence window, existing auth-expiry behavior remains unchanged.

**Touched modules**

- [web/src/lib/api.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/api.ts)
- [web/src/components/Editor.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/Editor.tsx) for coordination with existing offline/sync status if reconnect state needs to influence editor messaging
- [web/src/pages/App.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/App.tsx) only if redirect-entry semantics need alignment with current `expired=true` routing

### 3. Autosave terminal failure visibility

**Client flow**

1. `useAutoSave` retries save failures with exponential backoff and a capped retry budget.
2. Each save cycle reports terminal failure through `onFailure` with retry metadata after the last retry fails.
3. The editor surface stores a sticky save error state and renders a visible banner/toast that remains until a later successful save clears it.
4. A successful retry or later manual/autosave clears the sticky error state and restores normal “Saved” behavior.

**Touched modules**

- [web/src/hooks/useAutoSave.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/hooks/useAutoSave.ts)
- [web/src/components/UnifiedEditor.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.tsx)
- [web/src/pages/PersonEditor.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/PersonEditor.tsx) if person titles should use the same sticky terminal-failure treatment

## Data and API Contract Changes

### `PATCH /api/documents/:id` request

- Continue to accept partial document updates.
- For title writes, require the client to send:
  - `title: string`
  - `expected_updated_at: string`
- Stop relying on title-specific `expected_title` as the primary conflict guard for editor title writes.

### `409 WRITE_CONFLICT` response shape

```json
{
  "error": {
    "code": "WRITE_CONFLICT",
    "message": "Document was updated by another user. Refresh to get the latest changes before retrying."
  },
  "current_title": "Server authoritative title",
  "current_updated_at": "2026-03-11T19:14:22.123Z",
  "attempted_title": "Client submitted title"
}
```

### Client error contract changes

- `createRequestError` should preserve:
  - `status`
  - `code`
  - `current_title`
  - `current_updated_at`
  - `attempted_title`
- `useAutoSave` failure callback should receive enough metadata to distinguish:
  - transient failure still retrying
  - terminal failure after retry exhaustion
  - eventual recovery after terminal failure

## Edge-Case Handling Matrix

| Scenario | Expected handling | User-visible behavior | Notes |
|----------|-------------------|-----------------------|-------|
| Concurrent title edit with stale token | Server rejects stale update with `409 WRITE_CONFLICT` | Conflict banner/prompt shows server title and safe retry path | Local typed title remains available for retry |
| Concurrent title retry after refresh | Client retries with fresh `expected_updated_at` | Save succeeds or returns a fresh conflict | Must be idempotent if title already matches |
| Browser offline during autosave | Autosave retries until retry budget exhausted | Sticky save-failed message remains until next successful save | No forced login redirect while offline |
| Autosave retry exhaustion | Hook stops retries and emits terminal failure | Persistent banner/toast with unsaved warning | Clear only on successful save |
| Transient 401 during reconnect turbulence | API helper defers redirect and retries within gate | User remains on page; no redirect storm | Success clears turbulence state |
| True auth expiry outside turbulence | Existing redirect behavior applies immediately | Single login redirect with `expired=true` | Preserve normal auth behavior |
| Multiple failing requests during auth churn | Shared circuit-breaker suppresses duplicate redirects | At most one expired redirect per session interruption | Requests may fail locally while redirect is deferred |
| CloudFront 403/HTML intercept during turbulence | Treat as candidate auth turbulence, not immediate hard redirect | Same deferred redirect behavior | Only for authenticated/private routes |
| Title conflict while autosave banner already visible | Keep both states coherent without overwriting | One combined status area with clear messages | Avoid duplicate stacked alerts |

## Implementation Sequence

1. **Stabilize contracts first**
   Update the document OpenAPI schema and shared/web error parsing so the planned `409 WRITE_CONFLICT` payload is typed end to end before UI handling is added.
2. **Complete server CAS enforcement**
   Change [api/src/routes/documents.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents.ts) to use `expected_updated_at` compare-and-swap for title writes, return `attempted_title` on conflict, and remove editor dependence on title-string locking.
3. **Add server regression coverage**
   Extend [api/src/routes/documents.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/api/src/routes/documents.test.ts) for successful title CAS, stale CAS conflict, idempotent retry, and non-title updates preserving current behavior.
4. **Wire client title tokens and conflict flow**
   Update [web/src/pages/UnifiedDocumentPage.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/UnifiedDocumentPage.tsx), [web/src/components/UnifiedEditor.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/UnifiedEditor.tsx), and [web/src/pages/PersonEditor.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/PersonEditor.tsx) so title saves send `expected_updated_at`, preserve local text on conflict, refresh authoritative state, and offer a safe retry path.
5. **Implement reconnect turbulence gate**
   Refactor [web/src/lib/api.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/api.ts) to centralize turbulence-window tracking, bounded retry, duplicate-redirect suppression, and success-path reset while preserving default auth-expiry outside turbulence.
6. **Implement autosave terminal-failure state**
   Update [web/src/hooks/useAutoSave.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/hooks/useAutoSave.ts) to expose exponential backoff and terminal-failure metadata, then connect sticky error rendering in editor callers.
7. **Add client unit/integration coverage**
   Add tests for reconnect gating logic, autosave backoff/terminal failure, and conflict error parsing/rendering.
8. **Add E2E coverage with seeded fixtures**
   Extend `e2e/fixtures/isolated-env.ts` and add scenarios for concurrent title edits, reconnect turbulence, and autosave terminal failure UX using the project’s required fixture-driven approach.
9. **Verify guarded rollout evidence**
   Run type-check, targeted API/web tests, and the E2E runner; capture latency/bundle observations and confirm no regression in ordinary save/collaboration flows.

## Test Plan

### Unit Tests

- API route helper behavior for title CAS success vs stale-token conflict
- `web/src/lib/api.ts` retry gating and turbulence-window redirect suppression
- `web/src/hooks/useAutoSave.ts` exponential backoff schedule, retry exhaustion, sticky failure callback, and success reset
- `web/src/lib/http-error.ts` parsing of `WRITE_CONFLICT` metadata

### Integration Tests

- `PATCH /api/documents/:id` returns `409 WRITE_CONFLICT` with `current_title`, `current_updated_at`, and `attempted_title`
- Title patch with fresh `expected_updated_at` succeeds and returns updated document
- Non-title document updates continue to behave normally
- Client mutation flow preserves local title text and refreshes authoritative state after conflict

### E2E Tests

- Two sessions edit the same document title; the stale writer sees conflict UI and can retry safely
- During transient reconnect turbulence, the user stays on the document and is not redirected until retries are exhausted
- Autosave terminal failure shows a sticky visible error and clears only after a later successful save

## Observability Plan

- **Logs**
  - Server warning log on `WRITE_CONFLICT` with document ID, workspace ID, and actor ID
  - Client-side debug/error logging for reconnect deferral start, retry exhaustion, and autosave terminal failure
- **Metrics / counters**
  - `documents.title_write_conflict.count`
  - `auth.reconnect_deferral.count`
  - `auth.reconnect_redirect_suppressed.count`
  - `autosave.terminal_failure.count`
  - `autosave.recovered_after_failure.count`
- **Events**
  - Analytics or audit event when a title conflict is surfaced to a user
  - Event when reconnect turbulence resolves without redirect
  - Event when autosave enters and exits terminal-failure state

## Rollout and Rollback Strategy

### Rollout

- Guard the three client-facing behaviors behind a single runtime-resilience feature flag or equivalent config guard if one already exists in the app.
- Enable in lower environments first with observability turned on.
- Verify conflict, reconnect deferral, and autosave-failure counters remain low and ordinary save success remains unchanged.
- Roll out gradually to production traffic after targeted manual verification.

### Rollback

- Client rollback path: disable the runtime-resilience flag to restore current title-save messaging, current auth redirect behavior, and current autosave behavior.
- Server rollback path: revert the title CAS requirement to the previous update path if conflict handling causes unexpected write rejection.
- Because no schema change is introduced, rollback is code-only and low-risk.

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Title CAS rejects legitimate retries due to timestamp precision mismatch | Medium | Normalize comparison precision exactly as current API tests do and keep idempotent retry coverage |
| Reconnect turbulence defers redirect too aggressively and masks real expiry | High | Bound the turbulence window, retry budget, and success reset; preserve existing behavior outside the window |
| Autosave sticky error becomes noisy during brief blips | Medium | Only show sticky failure after retry exhaustion, not on first transient error |
| Multiple status messages confuse users | Medium | Consolidate messaging into the existing editor banner/status area with priority ordering |
| Client conflict flow diverges between unified editor and person editor | Medium | Reuse shared error parsing and autosave behavior across both title-editing surfaces |

## Definition of Done

- Title updates use `expected_updated_at` compare-and-swap and return `409 WRITE_CONFLICT` with the documented payload for stale writes.
- Users encountering concurrent title edits see a clear conflict state, keep their local text, and have a safe retry path.
- `web/src/lib/api.ts` defers redirect during bounded reconnect turbulence and triggers at most one forced `login?expired=true` redirect per interrupted session.
- Autosave failures use exponential backoff, emit terminal failure after retry exhaustion, and show a sticky visible error until a later successful save clears it.
- Normal save, collaboration, and auth-expiry behavior outside the targeted edge cases remains unchanged.
- Required unit, integration, and E2E tests pass for the three scoped fixes.
- Observability hooks exist for conflict rate, reconnect deferrals, and autosave terminal failures.

## Post-Design Constitution Check

- **Type Safety Audit**: Pass. Contracts are explicit and remain centralized in shared/web parsing and document API schema.
- **Bundle Size Audit**: Pass. No new dependency or major client surface is introduced.
- **API Response Time**: Pass. Title CAS stays on the existing write path plus one fallback read only on conflict.
- **Database Query Efficiency**: Pass. No new index or extra normal-path query is required.
- **Test Coverage and Quality**: Pass. The plan adds unit, integration, and E2E coverage for the exact failure modes.
- **Runtime Errors and Edge Cases**: Pass. Each targeted failure path has explicit handling and user-visible behavior.
- **Accessibility Compliance**: Pass. Alerts remain in the existing editor surface with preserved focus and assistive-technology visibility.

## Complexity Tracking

No constitution exceptions or justified complexity violations are planned.
