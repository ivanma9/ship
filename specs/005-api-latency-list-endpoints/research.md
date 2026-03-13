# Research: API Latency Improvement for List Endpoints

## Decision 1: Use the March 10, 2026 API latency audit as the canonical benchmark baseline

**Decision**: Reuse `audits/api-response-time.md` and the corresponding section of `audits/consolidated-audit-report-2026-03-10.md` as the baseline for this feature.

**Rationale**:

- The approved targets already come from that audit.
- It records the seeded data volume, authenticated local environment, `E2E_TEST=1` requirement, and the `c10/c25/c50` matrix.
- Reusing it preserves the constitution requirement for paired before/after evidence under the same measurement method.

**Alternatives considered**:

- Create a new benchmark method for this feature: rejected because it would break comparability with the approved audit baseline.
- Benchmark only `c50`: rejected because the approved baseline and report format include `c10`, `c25`, and `c50`.

## Decision 2: Treat DB query-plan and index review as a hard prerequisite, not a parallel afterthought

**Decision**: Start with `EXPLAIN ANALYZE` and index review for the wiki and issue list queries before final route-level latency tuning.

**Rationale**:

- The remediation-order roadmap explicitly requires Database Query Efficiency before API Response Time can close.
- Current indexes are broad but not obviously aligned to the active sort patterns for these two list paths.
- Latency benchmarking is unreliable if planner behavior is still changing underneath the routes.

**Alternatives considered**:

- Optimize route code first and review indexes later: rejected because it violates the roadmap dependency and risks redoing benchmark work after planner changes.
- Add indexes immediately without explain evidence: rejected because it would widen schema scope without proof they are needed.

## Decision 3: Keep default response contracts stable and prefer additive optimization controls

**Decision**: Preserve current default response shapes for `/api/documents?type=wiki` and `/api/issues`, and use additive query parameters only if payload reduction or request bounding is required.

**Rationale**:

- The user explicitly required no response-contract regressions.
- Current web consumers depend on array responses and issue associations.
- Additive controls let Ship web clients opt into reduced payload or explicit page size while leaving default callers compatible.

**Alternatives considered**:

- Change the default list response shape to a paginated envelope: rejected because it is a contract regression.
- Remove currently returned fields from the default response: rejected because current consumers may depend on them and the feature scope is latency, not contract redesign.

## Decision 4: Use route-local query tightening plus narrow indexes before fallback default limits

**Decision**: Prioritize query projection, sort-supporting indexes, and removal of unnecessary work on the current routes before introducing default limits or pagination fallback.

**Rationale**:

- `/api/documents?type=wiki` already avoids loading `content`, so its gains should come mostly from planner and sort improvements.
- `/api/issues` has more room for route-side tightening, especially around selected columns and high-cost joins.
- Default limits are risky for current Ship list views and should be held back until clearly necessary.

**Alternatives considered**:

- Lead with default limits for both endpoints: rejected because it risks silent truncation and does not satisfy the “no contract regressions” constraint cleanly.
- Ignore fallback limits entirely: rejected because the approved improvement plan explicitly calls for them if the target is otherwise missed.

## Decision 5: Publish machine-readable before/after artifacts in addition to markdown audit updates

**Decision**: Add JSON evidence files for this feature under `audits/artifacts/` while keeping the canonical markdown summary in `audits/api-response-time.md`.

**Rationale**:

- JSON artifacts make the before/after comparison durable and reviewable without scraping markdown tables.
- Markdown remains consistent with the repo’s existing audit reporting style.
- The paired artifact set satisfies the constitution’s requirement for before/after evidence on measurable quality improvements.

**Alternatives considered**:

- Keep only markdown tables: rejected because it makes exact comparison and reuse harder.
- Build a new benchmark harness or dashboard: rejected because it introduces unnecessary tooling outside the established Ship patterns.
