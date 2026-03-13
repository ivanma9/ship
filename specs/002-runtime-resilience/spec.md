# Feature Specification: Runtime Resilience for Concurrency, Reconnect, and Autosave

**Feature Branch**: `002-runtime-resilience`  
**Created**: 2026-03-11  
**Status**: Draft  
**Input**: User description: "Feature: Runtime Resilience for Concurrency, Reconnect, and Autosave Problem: High-risk edge-case gaps can cause divergent data, redirect storms, and silent save failures. Users: Active collaborators and authenticated users. Goal: Eliminate top runtime failure modes with explicit conflict/retry handling and visible failure states. In scope: - Title write conflict protection with expectedUpdatedAt CAS and 409 handling - 401 reconnect circuit-breaker/deferred redirect logic - Autosave terminal-failure visibility with backoff and sticky error state Out of scope: - Full offline architecture redesign Functional requirements: 1. Implement server/client conflict handling for concurrent title edits. 2. Add reconnect grace/retry gate before forced session-expired redirect. 3. Add autosave failure callback, backoff, and persistent user-visible error state. Non-functional requirements: - No regression to normal save/collaboration flows. Acceptance criteria: - Edge-case tests pass for all three top gaps with clear user-visible behavior. - No unresolved P0/P1 regression in audited runtime paths."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Preserve Correct Titles During Concurrent Edits (Priority: P1)

As a collaborator editing a shared document title, I need the system to detect when someone else has already changed the title so that my edit does not silently overwrite newer work.

**Why this priority**: Incorrect title overwrites create immediate data divergence between collaborators and can destroy recent work without warning.

**Independent Test**: Can be fully tested by having two active sessions edit the same title from different starting states and confirming the later stale save is rejected with a visible conflict outcome.

**Acceptance Scenarios**:

1. **Given** two collaborators load the same document title at the same time, **When** collaborator A saves a new title and collaborator B later submits a title based on stale document state, **Then** collaborator B's stale title update is rejected, the newer saved title remains authoritative, and collaborator B sees a visible conflict message.
2. **Given** a collaborator edits a title from the latest known document state, **When** the title save completes without a competing update, **Then** the title change is saved normally with no extra conflict messaging.

---

### User Story 2 - Avoid Premature Session-Expired Redirects During Reconnect (Priority: P2)

As an authenticated user experiencing a temporary reconnect failure, I need the application to retry and wait briefly before redirecting me so that short-lived authorization or network interruptions do not throw me out of my current work.

**Why this priority**: Forced redirects during transient failures interrupt active work, can create redirect loops, and make the product feel unstable even when the session is still valid.

**Independent Test**: Can be fully tested by simulating transient authorization failures during reconnect and confirming the application delays redirect until retry attempts are exhausted or the session is confirmed invalid.

**Acceptance Scenarios**:

1. **Given** an authenticated user loses a live connection during editing, **When** the reconnect attempt receives a temporary authorization failure and later recovers within the grace window, **Then** the user stays on the current document and collaboration resumes without a login redirect.
2. **Given** an authenticated user loses a live connection and reconnect attempts continue to fail through the full grace window, **When** the system determines the session can no longer be restored, **Then** the user is redirected once to re-authenticate and sees a clear session-expired explanation.

---

### User Story 3 - Surface Terminal Autosave Failures (Priority: P3)

As a user relying on autosave, I need a persistent failure state after repeated save failures so that I know my latest edits are not protected and can take corrective action.

**Why this priority**: Silent autosave failure creates hidden data-loss risk and leaves users with false confidence that their work is safe.

**Independent Test**: Can be fully tested by forcing repeated save failures, verifying retries back off, and confirming the user sees a sticky visible failure state until a later successful save clears it.

**Acceptance Scenarios**:

1. **Given** autosave encounters a temporary failure, **When** a later retry succeeds within the retry budget, **Then** the changes are saved and no persistent failure state remains visible.
2. **Given** autosave repeatedly fails until the retry budget is exhausted, **When** the system stops automatic retries for that save cycle, **Then** the user sees a persistent visible save-failed state that remains until a successful save occurs.

### Edge Cases

- A title conflict occurs after the user has typed additional unsaved edits: the user must keep local text visible while also seeing that the server rejected the stale write.
- Multiple reconnect failures happen in rapid succession: the user must not be sent through repeated redirects or duplicate session-expired prompts.
- A reconnect failure happens while autosave is already retrying: the user must receive one coherent failure state rather than overlapping or contradictory messages.
- Autosave fails after a document has been left idle in a background tab: the next visible state presented to the user must still indicate that the latest changes were not safely saved.
- Keyboard-only users and screen-reader users must be able to perceive conflict and save-failure states without losing focus from the editor unexpectedly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST reject a title update when the request is based on an outdated last-known document update time.
- **FR-002**: The system MUST preserve the most recently accepted title as the authoritative title after a stale title update is rejected.
- **FR-003**: The system MUST return a distinct conflict outcome for rejected stale title updates so the client can differentiate conflicts from generic save failures.
- **FR-004**: The user MUST receive a visible conflict state when their title update is rejected because a newer title already exists.
- **FR-005**: The client MUST refresh its displayed authoritative title state after receiving a title conflict outcome.
- **FR-006**: The system MUST treat reconnect authorization failures as recoverable for a defined grace period before forcing re-authentication.
- **FR-007**: During the reconnect grace period, the user MUST remain on the current page unless the session is explicitly determined to be invalid or the retry budget is exhausted.
- **FR-008**: The system MUST prevent repeated redirects caused by multiple reconnect failures from the same interrupted session.
- **FR-009**: If reconnect recovery fails through the full retry window, the user MUST see a clear session-expired message and be redirected once to re-authenticate.
- **FR-010**: Autosave MUST retry failed save attempts using increasing wait intervals up to a finite retry limit.
- **FR-011**: Autosave MUST expose a terminal failure outcome when retries are exhausted without a successful save.
- **FR-012**: The user MUST see a persistent visible save-failed state after autosave reaches terminal failure.
- **FR-013**: The persistent save-failed state MUST remain visible until a later successful save clears it.
- **FR-014**: Normal title editing, reconnect recovery, and autosave behavior MUST remain unchanged when no conflict, authorization interruption, or save failure occurs.
- **FR-015**: Automated coverage MUST include primary-flow and edge-case scenarios for title conflict handling, reconnect retry gating, and terminal autosave failure visibility.

### Key Entities *(include if feature involves data)*

- **Document Title State**: The current saved title and its last accepted update timestamp used to determine whether an incoming title change is current or stale.
- **Reconnect Session State**: The active user session's reconnect lifecycle, including whether the session is retrying, recovered, expired, or already redirected.
- **Autosave Status State**: The current save health for the user's document changes, including retry progress, terminal failure, and recovery after a later success.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In conflict test scenarios, 100% of stale title submissions are rejected without overwriting the most recently accepted title.
- **SC-002**: In transient reconnect scenarios that recover within the grace window, users remain in their active document without an unnecessary login redirect in 100% of tested cases.
- **SC-003**: In unrecoverable reconnect scenarios, users experience no more than one forced session-expired redirect per interrupted session.
- **SC-004**: In repeated autosave failure scenarios, users see a visible persistent save-failed state within 5 seconds of the final retry attempt ending.
- **SC-005**: In recovery scenarios where a later save succeeds after a terminal failure, the persistent save-failed state clears on the next successful save in 100% of tested cases.
- **SC-006**: Existing normal-flow save and collaboration regression tests continue to pass with no newly introduced P0 or P1 runtime failures in the audited paths.

## Assumptions

- The current user experience already includes a visible area where save or session status can be communicated without redesigning the full editor layout.
- A short reconnect grace window and finite retry budget are acceptable as long as they prevent premature redirect loops and clearly surface unrecoverable session loss.
- Title conflicts are resolved by preserving the server's latest accepted title rather than attempting to merge competing title values automatically.
- This feature improves online resilience only and does not introduce a broader offline-first or queued-sync model.

## Dependencies

- Reliable document timestamps or equivalent last-known update markers must be available to both the title update request and the stored document record.
- Session state and reconnect outcomes must be observable in a way that allows transient failures to be distinguished from confirmed session expiry.
- The product must have a user-visible status channel capable of showing persistent conflict, session, and save-failure messaging.

## Engineering Quality Gates *(mandatory)*

### Required Evidence

- **QG-001 Type Safety**: Title update outcomes, reconnect outcomes, and autosave terminal-failure states must use explicit contracts shared across the affected runtime paths so conflict, retry, and terminal states cannot be mistaken for generic success.
- **QG-002 Bundle Size**: Any user-visible resilience messaging should reuse existing status surfaces and state management so the feature adds negligible client payload growth and no large new runtime dependency.
- **QG-003 API Response Time**: Title conflict detection must preserve the current interactive feel for title saves, with no noticeable delay added to successful title updates under normal editing conditions.
- **QG-004 Database Query Efficiency**: Conflict detection must rely on the existing single-document title lookup and write path so title protection does not add an extra round-trip per successful save in normal use.
- **QG-005 Test Coverage and Quality**: Automated tests must cover successful title save, stale title conflict, transient reconnect recovery, unrecoverable reconnect redirect, autosave retry recovery, and autosave terminal failure visibility.
- **QG-006 Runtime Errors and Edge Cases**: The system must handle concurrent title edits, repeated reconnect authorization failures, and exhausted autosave retries with explicit recovery or persistent user-visible messaging instead of silent failure.
- **QG-007 Accessibility Compliance**: Conflict, session-expired, and save-failed states must be perceivable to keyboard-only and assistive-technology users without unexpectedly moving focus away from the active editor.
