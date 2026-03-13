# Data Model: Runtime Resilience for Concurrency, Reconnect, and Autosave

## Entities

### 1. Document Title Write Attempt

**Purpose**: Represents a client request to change a document title against the current authoritative document record.

**Fields**

- `document_id`: Target document identifier
- `workspace_id`: Workspace scope for authorization and query filtering
- `title`: Proposed new title
- `expected_updated_at`: Client's last-known authoritative update timestamp
- `current_title`: Server-authoritative title returned on conflict
- `current_updated_at`: Server-authoritative timestamp returned on conflict
- `attempted_title`: Client-submitted title echoed on conflict for safe retry UX

**Validation rules**

- `title` must satisfy existing document title validation
- `expected_updated_at` is required for title writes from the editor flow
- A write succeeds only when stored `updated_at` matches `expected_updated_at` at the accepted precision

**State transitions**

- `pending` -> `saved`
- `pending` -> `conflicted`
- `conflicted` -> `retried`
- `retried` -> `saved` or `conflicted`

### 2. Reconnect Turbulence State

**Purpose**: Represents whether the client is in a bounded grace period after transient authorization or reconnect failures.

**Fields**

- `turbulence_started_at`: Timestamp of the first recoverable auth failure
- `retry_count`: Number of retries attempted inside the grace window
- `redirect_scheduled`: Whether a forced session-expired redirect has already been armed
- `last_failure_status`: Most recent failure status observed during turbulence
- `resolved_at`: Timestamp when a later successful authenticated response clears turbulence

**Validation rules**

- State begins only for recoverable authenticated-route failures
- State clears immediately on a successful authenticated response
- Redirect may be emitted at most once per turbulence cycle

**State transitions**

- `idle` -> `turbulent`
- `turbulent` -> `recovered`
- `turbulent` -> `expired_redirected`
- `recovered` -> `idle`

### 3. Autosave Operation State

**Purpose**: Represents the save lifecycle for a throttled autosave cycle.

**Fields**

- `value`: Pending content/title payload being saved
- `attempt_count`: Current retry number
- `max_retries`: Maximum attempts before terminal failure
- `next_retry_delay_ms`: Backoff delay before the next retry
- `terminal_error`: Final error captured after retry exhaustion
- `sticky_error_visible`: Whether the user-facing failure state is active
- `last_success_at`: Timestamp of the most recent successful save

**Validation rules**

- Backoff grows exponentially until `max_retries` is reached
- `sticky_error_visible` becomes `true` only after terminal failure
- `sticky_error_visible` returns to `false` only after a later successful save

**State transitions**

- `idle` -> `saving`
- `saving` -> `retrying`
- `retrying` -> `saved`
- `retrying` -> `terminal_failure`
- `terminal_failure` -> `saved`

## Relationships

- A `Document Title Write Attempt` reads and conditionally mutates one authoritative document record.
- `Reconnect Turbulence State` is client-session scoped and may affect multiple API requests during one interruption.
- `Autosave Operation State` is local to an editor instance but its successful completion updates the authoritative document record.

## Non-Goals

- No new persistent database table or migration is introduced.
- No offline queue, conflict-free title merge system, or cross-device retry ledger is added.
