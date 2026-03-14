# DISCOVERY.md

Three things discovered in this codebase that were non-obvious or architecturally noteworthy.

---

## Discovery 1: Yjs ↔ TipTap Bidirectional Format Conversion with Three-Source Fallback Chain

**Where:** `api/src/utils/yjsConverter.ts` (lines 1–245) and `api/src/collaboration/index.ts` (lines 196–284)

### What it does and why it matters

The codebase maintains two representations of every document simultaneously: a binary Yjs CRDT (for real-time collaboration) and TipTap JSON (for REST API reads). Rather than treating these as separate stores that need manual sync, Ship derives the JSON from Yjs on every save and loads whichever format is available via a three-source fallback chain:

1. Binary `yjs_state` — preferred, authoritative for collaborative sessions
2. JSON `content` — fallback for API-created documents that have no Yjs state yet
3. Empty document — for brand-new documents

The `jsonToYjs` function wraps each conversion in a Yjs transaction (lines 164–198), so partial conversions can't corrupt document state. The converter also handles nested marks (bold + italic combos) and recursive block structures that TipTap's schema allows.

This matters because most naive collaborative editors maintain the two formats loosely in sync and accumulate divergence bugs over time. Using Yjs as the single source of truth and treating JSON as a derived projection eliminates that class of bug entirely.

### How I'd apply this in a future project

In any project that combines a CRDT-based collaborative editor with a REST API: store only the binary CRDT format in the database. Derive the API-friendly JSON format on reads (or on write, as a materialized projection). Never let the two formats be updated independently. Write explicit conversion helpers with error handling rather than ad-hoc serialization at call sites.

---

## Discovery 2: WebSocket Rate Limiting with Sliding Windows and Progressive Penalties

**Where:** `api/src/collaboration/index.ts` (lines 19–86, 649–796)

### What it does and why it matters

The WebSocket collaboration server implements multi-layered rate limiting that goes beyond simple "reject when over limit" enforcement:

- **Connection-level:** 30 connections per IP per 60 seconds (sliding window)
- **Message-level:** 50 messages per connection per second (sliding window)
- **Progressive penalties:** After 50 rate-limit violations on a single connection, force-close it
- **Memory management:** Automatic cleanup of old timestamps to prevent unbounded growth

Critically, when a client exceeds the *message* rate limit, the server silently drops the message rather than disconnecting (line 788). This is intentional: Yjs has a built-in sync protocol that retries lost messages, so silent drops align with CRDT semantics and avoid unnecessary reconnect storms.

Sliding windows prevent the "thundering herd" problem where all clients reset their counters simultaneously and produce a burst. Fixed-bucket rate limits are vulnerable to this; Ship's implementation is not.

### How I'd apply this in a future project

For any stateful WebSocket or long-lived connection system: use sliding windows, not fixed buckets. Track violations separately from rejections, and use a threshold to escalate to disconnection only for persistent bad actors. Match the drop/reject/disconnect decision to the protocol's recovery mechanism — if the protocol retries, drop silently; if it doesn't, close explicitly.

---

## Discovery 3: Intentional, Documented `any` Escape Hatch for pg Overload Satisfaction

**Where:** `api/src/test-utils/mock-query-result.ts` (lines 1–32)

### What it does and why it matters

The `pg` package exposes multiple overloaded signatures for `pool.query()`. Mocking all of them in TypeScript strict mode is painful — each overload expects a different return shape, and no single generic type satisfies them all cleanly.

Rather than fighting this with increasingly contorted type gymnastics or silently casting with `as any` throughout the test suite, Ship isolates the escape hatch to a single utility function:

```typescript
export function mockQueryResult<T extends Record<string, unknown>>(
  rows: T[],
  overrides: Partial<{ rowCount: number; command: string }> = {}
): any {  // Returns `any` so it satisfies all pg.QueryResult overloads
```

The `any` return type is:
- **Explicit** at the function boundary, not hidden in a variable
- **Documented** with a JSDoc comment explaining the technical reason
- **Scoped** to test utilities only — never used in production paths
- **Justified** with an `eslint-disable` comment (line 10)

This is a better pattern than scattered `as any` casts. It centralizes the tradeoff, makes it visible in code review, and ensures the rest of the test suite stays strongly typed.

### How I'd apply this in a future project

When strict TypeScript creates friction against an external library's overloaded API: don't fight the overloads in every call site. Isolate the escape hatch to one utility function, document *why* `any` is the right choice at that boundary, and keep all other code strongly typed. Treat it as a deliberate, acknowledged tradeoff rather than a shortcut — and mention it explicitly during code review so the team understands the reasoning.
