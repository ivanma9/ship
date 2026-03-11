# Runtime Resilience Contracts

## 1. Document Title Update Contract

### Request

`PATCH /api/documents/:id`

```json
{
  "title": "Proposed title",
  "expected_updated_at": "2026-03-11T19:14:22.123Z"
}
```

### Success response

Returns the existing updated document representation, including the new authoritative `updated_at` value that becomes the client's next concurrency token.

### Conflict response

HTTP `409`

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

### Client handling contract

- Preserve the user's typed title locally.
- Update the local authoritative title/timestamp from `current_title` and `current_updated_at`.
- Show a visible conflict state with a safe retry path.
- Retry only with a fresh `expected_updated_at`.

## 2. Reconnect Turbulence Contract

### Trigger

An authenticated request receives a transient `401` or equivalent auth-intercept failure during reconnect turbulence.

### Required behavior

- Start or continue a bounded deferral window.
- Retry the request within the configured retry gate.
- Suppress duplicate `login?expired=true` redirects while turbulence is active.
- Clear turbulence state on the first successful authenticated response.
- Outside the deferral window, preserve existing session-expired redirect behavior.

## 3. Autosave Terminal Failure Contract

### Hook callback contract

`useAutoSave` must expose terminal failure details after the final retry attempt fails.

**Failure metadata**

- `error`
- `value`
- `attempt_count`
- `max_retries`
- `terminal: true`

### UI handling contract

- Show a sticky visible save-failed state after terminal failure.
- Do not clear the state on focus changes, navigation within the same editor surface, or intermediate retries.
- Clear the state only after a later successful save for the same editor session.
