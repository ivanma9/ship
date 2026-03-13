<!--
Sync Impact Report
Version change: 1.0.0 -> 1.1.0
Modified principles:
- Template Principle 1 -> I. Type Safety Audit
- Template Principle 2 -> II. Bundle Size Audit
- Template Principle 3 -> III. API Response Time
- Template Principle 4 -> IV. Database Query Efficiency
- Template Principle 5 -> V. Test Coverage and Quality
- V. Test Coverage and Quality -> V. Test Coverage and Quality (paired before/after evidence requirement)
- Added VI. Runtime Errors and Edge Cases
- Added VII. Accessibility Compliance
Added sections:
- Engineering Standards
- Review Workflow
Removed sections:
- None
Templates requiring updates:
- ✅ reviewed /Users/ivanma/Desktop/gauntlet/ShipShape/ship/.specify/templates/constitution-template.md (no change required for this amendment)
- ✅ reviewed /Users/ivanma/Desktop/gauntlet/ShipShape/ship/.specify/templates/plan-template.md (constitution check already consumes constitution gates)
- ✅ reviewed /Users/ivanma/Desktop/gauntlet/ShipShape/ship/.specify/templates/spec-template.md (no change required for this amendment)
- ✅ reviewed /Users/ivanma/Desktop/gauntlet/ShipShape/ship/.specify/templates/tasks-template.md (no change required for this amendment)
- ⚠ pending /Users/ivanma/Desktop/gauntlet/ShipShape/ship/.specify/templates/commands/*.md (directory not present in this worktree)
Follow-up TODOs:
- None
-->
# Ship Engineering Constitution

## Core Principles

### I. Type Safety Audit
**Intent**: Ship MUST prevent type ambiguity from reaching production by enforcing
compile-time safety across shared, API, and web code.

- **Non-negotiable rules**
- All application code MUST be authored in TypeScript with strict compiler checks
  enabled.
- Shared domain types MUST live in `shared/` or in explicitly shared modules rather
  than being duplicated across packages.
- New or changed API contracts, document properties, and persisted data shapes MUST
  have explicit types or schemas at system boundaries.
- `any`, unchecked casts, and `@ts-ignore` SHOULD be avoided and MUST include an
  inline justification plus a dated removal follow-up when unavoidable.
- **Measurable quality gates**
- `pnpm type-check` MUST pass with zero errors.
- Modified files MUST introduce zero new implicit `any` usages and zero untyped
  exported functions.
- Boundary payloads touched by the change MUST have runtime validation or typed
  parsing coverage.
- **Review/PR acceptance criteria**
- PRs MUST identify every changed contract and show where the canonical type lives.
- Reviewers MUST reject changes that duplicate types, widen types without need, or
  bypass validation at API or persistence boundaries.
- **Exception policy**
- Approver: engineering lead for the touched area.
- Expiration: exception MUST expire within 14 calendar days and reference a tracked
  cleanup issue before merge.

### II. Bundle Size Audit
**Intent**: Ship MUST keep the web bundle intentionally small so core workflows load
quickly on constrained government networks and ordinary laptops.

- **Non-negotiable rules**
- New frontend dependencies MUST be justified against lighter existing options before
  adoption.
- Client code MUST prefer route-level or feature-level code splitting for
  non-critical experiences.
- Server-only code, debug helpers, and large data fixtures MUST NOT ship in browser
  bundles.
- Changes that increase JavaScript payload SHOULD remove equivalent dead code or
  provide a reason the increase is necessary.
- **Measurable quality gates**
- Production web build MUST complete successfully.
- The initial route bundle for the changed experience MUST NOT grow by more than
  20 KB gzip without an approved exception.
- Any single newly added dependency contributing more than 15 KB gzip to the client
  bundle MUST be called out in the PR.
- **Review/PR acceptance criteria**
- PRs affecting `web/` MUST include before/after bundle evidence from the build
  output or analyzer.
- Reviewers MUST reject unused dependencies, accidental eager imports, and bundle
  growth without user-facing justification.
- **Exception policy**
- Approver: frontend lead.
- Expiration: exception MUST expire within the next release cycle or 30 calendar
  days, whichever comes first.

### III. API Response Time
**Intent**: Ship APIs MUST remain predictably fast so document, planning, and issue
workflows feel immediate under normal load.

- **Non-negotiable rules**
- New or modified endpoints MUST define expected latency for the primary success
  path.
- API handlers MUST bound remote work, avoid unnecessary serialization, and paginate
  list responses where result sets can grow.
- Expensive synchronous work SHOULD be moved off the request path when the user does
  not need it to complete the action.
- **Measurable quality gates**
- Changed read endpoints MUST target p95 latency of 250 ms or less in local or CI
  verification with representative seeded data.
- Changed write endpoints MUST target p95 latency of 400 ms or less in local or CI
  verification with representative seeded data.
- PRs that materially affect endpoint behavior MUST include timing evidence from a
  test, benchmark, or documented manual measurement.
- **Review/PR acceptance criteria**
- PRs MUST state which endpoints changed and include latency evidence for each one.
- Reviewers MUST reject handlers that add avoidable round trips, unbounded payloads,
  or blocking work without measured justification.
- **Exception policy**
- Approver: backend lead.
- Expiration: exception MUST expire within 21 calendar days and include an owner for
  remediation.

### IV. Database Query Efficiency
**Intent**: Ship MUST keep PostgreSQL access explicit, bounded, and observable so
the unified document model stays simple without becoming slow.

- **Non-negotiable rules**
- Queries MUST select only required columns and MUST use filters, joins, and limits
  that match the access pattern.
- N+1 query patterns MUST be eliminated before merge.
- Schema changes affecting query performance MUST ship with an index plan, migration,
  or written rationale for why no index is needed.
- Raw SQL SHOULD remain readable and centralized in utilities or data access modules
  instead of being scattered through route handlers.
- **Measurable quality gates**
- Changed list or aggregation flows MUST document query count and show no avoidable
  N+1 behavior.
- New or modified queries on seeded datasets SHOULD complete in 100 ms or less per
  query for typical reads and 200 ms or less for typical writes.
- `EXPLAIN` or equivalent evidence MUST be included for any materially new complex
  query, join, or index-sensitive path.
- **Review/PR acceptance criteria**
- PRs MUST identify changed queries, expected cardinality, and any added indexes or
  batching strategy.
- Reviewers MUST reject `SELECT *`, hidden looped queries, and migrations that change
  access patterns without performance review.
- **Exception policy**
- Approver: backend lead plus database owner when a migration is involved.
- Expiration: exception MUST expire within 14 calendar days or before the next schema
  migration touching the same path, whichever is sooner.

### V. Test Coverage and Quality
**Intent**: Ship MUST verify behavior with tests that catch regressions in document
workflows, sync behavior, and API contracts before release.

- **Non-negotiable rules**
- Every behavior change MUST add or update the smallest meaningful automated test at
  the correct layer.
- Tests MUST make clear assertions; placeholder tests, silent skips for missing data,
  and TODO-only test bodies MUST NOT be merged.
- Changes to contracts, persistence rules, or collaboration behavior SHOULD include
  integration or end-to-end coverage in addition to unit coverage.
- Bug fixes MUST include a regression test unless the fix is provably untestable, in
  which case the PR MUST explain why.
- **Measurable quality gates**
- Relevant test suites MUST pass for the changed area.
- New or changed code paths MUST have direct test coverage for the primary path and
  at least one failure or edge path.
- Any change that claims measurable improvement to coverage, reliability, or another
  audited quality metric MUST publish paired before and after evidence using the
  same command or measurement method on both sides of the comparison.
- Flaky tests introduced by the change are unacceptable; reruns MUST not be the
  validation strategy.
- **Review/PR acceptance criteria**
- PRs MUST describe what was tested, at which layer, and what regression would fail
  if the change broke.
- PRs or linked durable artifacts MUST identify the canonical before snapshot
  document and the after snapshot document whenever a measurable quality metric is
  being improved.
- Reviewers MUST reject coverage that asserts implementation details without checking
  user-visible or contract-visible behavior.
- When an older failing test is changed instead of the product behavior, the change
  MUST be justified by completed failure analysis showing the test asserted the wrong
  contract. For pre-March 9, 2026 tests, that rationale MUST be recorded in
  `ERROR_ANALYSIS.md` before merge.
- **Exception policy**
- Approver: engineering lead for the touched area.
- Expiration: exception MUST expire within 7 calendar days and MUST be linked to a
  scheduled follow-up test task.

### VI. Runtime Errors and Edge Cases
**Intent**: Ship MUST handle invalid input, partial failure, and unusual states
deliberately so collaborative workflows degrade safely instead of breaking abruptly.

- **Non-negotiable rules**
- New code MUST define and handle its expected failure modes, empty states, and
  boundary conditions.
- User-facing failures MUST surface actionable messages or safe fallback behavior;
  silent failure is not acceptable.
- Server and client code MUST log unexpected errors with enough context to diagnose
  the failing operation without leaking secrets.
- Defensive checks SHOULD exist at trust boundaries, especially for optional data,
  async state, and document associations.
- **Measurable quality gates**
- Each changed feature MUST document at least one edge case and one failure path in
  the spec or PR.
- Tests or manual verification MUST cover invalid input, missing data, and one
  partial-failure scenario where relevant.
- No new uncaught runtime exceptions, unhandled promise rejections, or blank-screen
  failure states are permitted in verified flows.
- **Review/PR acceptance criteria**
- PRs MUST state how the change behaves when data is absent, malformed, stale, or
  concurrently modified.
- Reviewers MUST reject optimistic-path-only implementations that omit recovery,
  retries, guards, or error messaging where the user can get stuck.
- **Exception policy**
- Approver: engineering lead for the touched area.
- Expiration: exception MUST expire within 14 calendar days and MUST include
  mitigation steps for the affected user path.

### VII. Accessibility Compliance
**Intent**: Ship MUST meet baseline accessibility expectations so all users can
operate core workflows with keyboard, assistive technology, and readable visual
presentation.

- **Non-negotiable rules**
- Interactive UI MUST be keyboard operable, have visible focus, and expose accessible
  names, roles, and states.
- Semantic HTML MUST be preferred over custom interaction patterns; ARIA MUST NOT be
  used as a substitute for correct semantics.
- Color, motion, and layout choices MUST preserve readability and MUST NOT be the
  sole carrier of meaning.
- New forms, dialogs, editors, and navigation patterns SHOULD be checked with screen
  reader and keyboard flows before merge.
- **Measurable quality gates**
- Changed UI flows MUST pass automated accessibility checks used by the repo and show
  zero critical violations.
- Keyboard-only navigation MUST complete the primary changed workflow.
- Text contrast for changed UI MUST meet WCAG 2.1 AA thresholds for normal product
  text and controls.
- **Review/PR acceptance criteria**
- PRs affecting UI MUST describe keyboard behavior, focus management, and any
  accessibility test evidence.
- Reviewers MUST reject controls without labels, broken focus order, inaccessible
  custom widgets, or color-only status indicators.
- **Exception policy**
- Approver: frontend lead plus product/design owner for the affected surface.
- Expiration: exception MUST expire within 14 calendar days and before the next user
  release that includes the affected UI.

## Engineering Standards

- Plans, specs, and tasks MUST explicitly address all seven principles whenever a
  feature changes the relevant surface area.
- Architecture decisions MUST follow Ship's documented constraints: everything is a
  document, the shared `Editor` component is reused, new document titles default to
  `Untitled`, and schema changes use numbered migrations instead of editing existing
  table definitions in place.
- Evidence for type safety, bundle impact, latency, query efficiency, testing,
  runtime handling, and accessibility MUST be attached to the PR or linked from it in
  durable project artifacts.
- When work changes a measurable quality metric, the durable artifact set MUST
  include both a before snapshot and an after snapshot, and both snapshots MUST use
  the same measurement method so the delta is reviewable without extra
  interpretation.

## Review Workflow

- The author MUST complete a principle-by-principle self-review before requesting
  review.
- Reviewers MUST verify the quality gates that apply to the changed code paths rather
  than accepting a generic "looks good" review.
- A PR is not mergeable until all applicable gates pass or an active exception is
  recorded with approver, scope, reason, and expiration date.
- Follow-up work created by an exception MUST be linked in the PR description before
  merge.

## Governance

- This constitution supersedes conflicting local habits and template defaults for
  engineering work in this repository.
- Amendments require a PR that updates the constitution, explains the rationale, and
  synchronizes impacted templates or guidance files in the same change when possible.
- Versioning policy:
- MAJOR for removing a principle, materially weakening a gate, or redefining
  governance obligations.
- MINOR for adding a principle, adding a mandatory gate, or materially expanding
  review requirements.
- PATCH for clarifications, wording improvements, and non-semantic template syncing.
- Compliance review is mandatory for every PR; reviewers MUST check applicable
  principles and document approved exceptions explicitly.
- Runtime development guidance remains anchored in `AGENTS.md` and the architecture
  docs under `docs/`.

**Version**: 1.1.0 | **Ratified**: 2026-03-11 | **Last Amended**: 2026-03-12
