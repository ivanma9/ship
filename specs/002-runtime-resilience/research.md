# Phase 0 Research: Runtime Resilience for Concurrency, Reconnect, and Autosave

## Decision 1: Use `expected_updated_at` compare-and-swap for title writes

**Decision**: Title updates will use the document's last-known `updated_at` timestamp as the optimistic concurrency token, enforced directly in the existing `UPDATE documents ... WHERE ...` clause.

**Rationale**: The repository already supports `expected_updated_at` on document patch requests and already truncates timestamp comparison to millisecond precision. Using the timestamp as the single CAS token avoids stale-write acceptance when unrelated state has changed, keeps the server as source of truth, and aligns the title flow with the broader document write contract.

**Alternatives considered**:

- Keep `expected_title` as the primary guard: rejected because string-only locking does not detect other intervening changes reliably and creates a second concurrency contract for one field.
- Add a version column or new lock table: rejected because the feature must minimize surface area and does not justify a schema change.

## Decision 2: Return a typed `409 WRITE_CONFLICT` payload with authoritative title metadata

**Decision**: The conflict response will include `error.code`, `error.message`, `current_title`, `current_updated_at`, and `attempted_title`.

**Rationale**: The current server already returns `current_title` and `current_updated_at` on conflict, and the web client already has a request-error helper that can be extended. Adding `attempted_title` makes the conflict UI deterministic and lets the client preserve the user's text while presenting a safe retry path.

**Alternatives considered**:

- Return only a generic 409 message: rejected because the client would need an additional fetch or would lose the submitted title context.
- Auto-merge the title on the server: rejected because title values are single-field, user-visible strings where explicit conflict handling is safer and clearer.

## Decision 3: Centralize reconnect turbulence deferral in `web/src/lib/api.ts`

**Decision**: A bounded reconnect turbulence window, retry gate, and redirect circuit-breaker will live in the shared API request helper rather than being implemented in page components or editor-only code.

**Rationale**: The current auth redirect logic is already centralized in `web/src/lib/api.ts`, including delayed redirects and CSRF retry behavior. Keeping turbulence handling there ensures uniform behavior for REST callers and avoids duplicating transient-auth logic in editor pages.

**Alternatives considered**:

- Handle turbulence only in collaboration/WebSocket code: rejected because the redirect storm manifests in REST helpers too, especially around CSRF and document patch calls.
- Add page-level guards in `App.tsx` or `ProtectedRoute`: rejected because the failure is request-driven and needs per-request retry suppression.

## Decision 4: Keep autosave retry and terminal-failure reporting inside `useAutoSave`

**Decision**: `useAutoSave` will own exponential backoff, retry exhaustion detection, and terminal-failure callbacks, while the editor surfaces own sticky user-visible state.

**Rationale**: The current hook already encapsulates retry behavior and exposes `onSuccess` and `onFailure`. Extending the hook keeps save resilience logic shared across the unified editor and person editor without pushing retry bookkeeping into each caller.

**Alternatives considered**:

- Move retry logic into every editor caller: rejected because that would duplicate timing logic and increase divergence between title-editing surfaces.
- Keep silent retries and only log failures: rejected because the spec requires persistent visible failure state.

## Decision 5: Reuse existing editor banners and status surfaces for resilience messaging

**Decision**: Conflict and autosave terminal-failure messaging will use the existing banner/status pattern already present in `UnifiedEditor`, and reconnect state will integrate with existing auth/session messaging without a layout redesign.

**Rationale**: The spec explicitly excludes a broader UX redesign. The current editor already renders a title save error alert and sync status indicator, making it the smallest safe surface for new user-visible runtime states.

**Alternatives considered**:

- Create a new global notification framework: rejected because it expands scope and bundle surface.
- Show only transient toasts: rejected because terminal autosave failure must remain sticky until recovery.
