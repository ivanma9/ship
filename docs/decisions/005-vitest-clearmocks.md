# ADR-005: Enable clearMocks in Vitest Config

**Date:** 2026-03-14
**Status:** Accepted
**Deciders:** spec-003 test reliability sprint

## Context

During spec 003 (improve test reliability), all 13 previously-flaky web test files
were found to already pass deterministically. The shared test setup (`web/src/test/setup.ts`)
contained only a single import — `@testing-library/jest-dom` — with no mock reset logic.
Vitest's default behavior does not clear mocks between tests unless explicitly configured.

Without automatic mock clearing, a `vi.mock()` or `vi.fn()` call in one test can bleed
state into a later test in the same file, causing non-deterministic failures that only
appear when tests run in a specific order or after a specific prior test.

The test suite happened to be clean at the time of the sprint, but the structural risk
remained: any new test that sets mock return values without manually calling `vi.clearAllMocks()`
in `beforeEach` would be susceptible to cross-test contamination.

## Decision

Add `clearMocks: true` to `web/vitest.config.ts` under the `test` block.

```ts
test: {
  environment: 'jsdom',
  globals: true,
  clearMocks: true,   // ← added
  setupFiles: ['./src/test/setup.ts'],
  ...
}
```

## Why

`clearMocks: true` resets mock call counts, instances, and results before each test
without restoring the original implementation. This is the right level of reset for
a codebase where mocks are declared with `vi.mock()` at module scope (which persists
across tests by design) but individual call history should not.

The alternative — `restoreMocks: true` — would also undo `vi.mock()` module-level
replacements, breaking the many tests that rely on module mocks remaining active for
the full file. `clearMocks` is the minimal, safe choice.

Before: no automatic reset — tests were clean only because authors manually called
`vi.clearAllMocks()` or `vi.resetAllMocks()` in `beforeEach` where needed.

After: call history is always clean at the start of each test. Authors no longer need
to remember to add `beforeEach(() => vi.clearAllMocks())` defensively.

Verification: `pnpm --filter web exec vitest run` — 28 files, 198 tests, 0 failures
before and after the change.

## Consequences

**Good:**
- Mock call history cannot leak between tests; new tests are safe by default
- Removes boilerplate `beforeEach(() => vi.clearAllMocks())` from individual test files

**Bad:**
- Tests that deliberately assert mock call counts across multiple `it()` blocks in the
  same describe will break (they should use `beforeEach` to set up state anyway)

**Risks:**
- Low. The existing 198 tests all pass with this setting, confirming no test relied on
  accumulated call state across test boundaries.

## Alternatives Considered

| Option | Why rejected |
|--------|-------------|
| `resetMocks: true` | Resets mock implementations too, breaking `vi.fn().mockReturnValue()` set outside `beforeEach` |
| `restoreMocks: true` | Undoes `vi.mock()` module replacements, would break all module-level mocks |
| Manual `beforeEach` per file | Already the status quo; error-prone and easy to forget in new tests |
| Do nothing | Leaves structural fragility in place; next contributor may not notice the missing reset |
