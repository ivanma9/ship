# Implementation Plan: Test Reliability and Critical-Flow Coverage

**Branch**: `003-improve-test-reliability` | **Date**: 2026-03-11 | **Spec**: [spec.md](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/specs/003-improve-test-reliability/spec.md)
**Input**: Feature specification from `/specs/003-improve-test-reliability/spec.md`

## Summary

Restore trustworthy test signal without changing the existing test frameworks by fixing the 13 deterministic web unit failures, removing fixed-delay synchronization from the highest-risk end-to-end paths, adding three missing collaboration critical-flow scenarios, and refreshing the published quality baselines. The implementation stays within the current Vitest, Playwright, isolated worker fixture, and coverage/reporting stack, with changes concentrated in the failing web test modules, reusable E2E helpers and fixtures, selected collaboration specs, and audit/reporting artifacts.

## Technical Context

**Language/Version**: TypeScript across `api/`, `web/`, and `shared/` on Node.js 20+  
**Primary Dependencies**: Express, `pg`, React, Vite, Vitest, Playwright, Testcontainers, TanStack Query, TipTap, Yjs  
**Storage**: PostgreSQL for API and collaboration state; generated coverage reports and `test-results/summary.json` for test evidence  
**Testing**: Vitest for API and web unit/integration tests; Playwright E2E with worker-isolated PostgreSQL/API/web servers and custom progress reporting  
**Target Platform**: Monorepo web application with browser frontend, Node.js API, and local/CI test runners  
**Project Type**: Monorepo web application  
**Performance Goals**: Preserve existing user-visible behavior while making the repaired suites deterministic across two consecutive reruns; keep changed API and E2E setup within current acceptable local execution times  
**Constraints**: Do not replace Vitest or Playwright; preserve feature behavior; E2E execution must use the approved runner workflow; fixture and seed data must remain explicit and deterministic; keep bundle impact negligible by avoiding new dependencies  
**Scale/Scope**: 13 known deterministic web unit failures, high-risk `waitForTimeout` usage in collaboration-sensitive E2E flows, 3 new critical-flow scenarios, and one refreshed baseline publication path

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Type Safety Audit**: Test helpers, fixtures, baseline summaries, and any new scenario utilities will remain typed in TypeScript and reuse existing canonical document/session shapes from shared and app modules. No `any`-based test shortcuts or untyped helper exports are planned.
- **Bundle Size Audit**: The feature changes tests, fixtures, and reporting surfaces only. No new runtime dependency is required, and no client bundle growth is expected because the plan avoids shipping test-only helpers into production code.
- **API Response Time**: No new user-facing endpoint is planned. Any route adjustments needed for deterministic RBAC or collaboration assertions must preserve current latency targets and be verified against existing seeded data.
- **Database Query Efficiency**: Seed-data work stays inside the isolated test environment and existing document creation paths. No schema change or new broad query is planned; any fixture additions will reuse current document insert and association patterns.
- **Test Coverage and Quality**: This feature directly advances the constitution by repairing deterministic failures, removing sleep-based synchronization from high-risk paths, and adding missing regression coverage for collaboration, offline replay, and revocation behavior.
- **Runtime Errors and Edge Cases**: The plan explicitly covers suite-order dependence, reconnect churn, duplicate offline replay, and revocation during active unsynced edits so tests assert safe failure behavior rather than only happy paths.
- **Accessibility Compliance**: The new E2E scenarios exercise existing editor and collaboration flows without introducing new UI. Any changed assertions in web tests continue to validate user-visible states and role-based selectors where possible.

**Gate Result**: Pass. No constitution violation requires an exception.

## Project Structure

### Documentation (this feature)

```text
specs/003-improve-test-reliability/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── test-reliability.md
└── tasks.md
```

### Source Code (repository root)

```text
web/
├── src/
│   ├── components/
│   │   ├── editor/
│   │   │   ├── DetailsExtension.test.ts
│   │   │   ├── DragHandle.test.ts
│   │   │   ├── FileAttachment.test.ts
│   │   │   ├── ImageUpload.test.ts
│   │   │   ├── MentionExtension.test.ts
│   │   │   └── TableOfContents.test.ts
│   ├── contexts/
│   │   └── SelectionPersistenceContext.test.tsx
│   ├── hooks/
│   │   ├── useAutoSave.test.ts
│   │   ├── useSelection.test.ts
│   │   └── useSessionTimeout.test.ts
│   ├── lib/
│   │   ├── accountability.test.ts
│   │   ├── api.test.ts
│   │   ├── document-tabs.test.ts
│   │   └── http-error.test.ts
│   ├── pages/
│   │   └── Dashboard.test.tsx
│   ├── styles/
│   │   └── drag-handle.test.ts
│   └── test/
│       └── setup.ts
└── vitest.config.ts

e2e/
├── fixtures/
│   ├── isolated-env.ts
│   └── test-helpers.ts
├── progress-reporter.ts
├── global-setup.ts
├── autosave-race-conditions.spec.ts
├── data-integrity.spec.ts
├── race-conditions.spec.ts
├── runtime-resilience-autosave.spec.ts
├── runtime-resilience-reconnect.spec.ts
├── security.spec.ts
└── [new collaboration critical-flow specs]

audits/
└── consolidated-audit-report-2026-03-10.md

scripts/
├── watch-tests.sh
├── check-empty-tests.sh
└── check-api-coverage.sh

.husky/
└── pre-commit
```

**Structure Decision**: Keep all work inside the current web unit suite, Playwright E2E suite, isolated worker fixture, and reporting artifacts. The implementation does not introduce a new framework, new storage layer, or a separate test harness.

## Phase 0 Research Summary

- The deterministic web failures should be fixed by removing shared-state leakage, timer/order dependence, and environment assumptions in existing tests rather than weakening assertions or adding retries.
- High-risk E2E synchronization should use observable readiness conditions, helper-backed retries, and explicit server/client state assertions instead of `waitForTimeout`.
- The three missing critical-flow scenarios should be seeded through `e2e/fixtures/isolated-env.ts` so each worker receives all prerequisite users, roles, documents, and associations deterministically.
- Baseline reporting should continue to use existing coverage outputs, `test-results/summary.json`, and the audit report as the publication surface, with deltas recorded against the March 10, 2026 baseline.
- CI gating should tighten around deterministic reruns and high-risk spec subsets using existing scripts and commands, not a framework change.

## Workstreams

### 1. Deterministic web unit failure remediation

**Objective**: Remove the 13 known deterministic failures while preserving behavior coverage.

**Planned actions**

1. Reproduce the failure set with the web Vitest coverage command and group failures by root cause.
2. Repair tests in place by stabilizing mock lifecycle, DOM cleanup, async assertions, and shared module state reset.
3. Update adjacent production modules only when the test exposes an actual deterministic defect rather than a brittle assertion.
4. Record one root-cause note per resolved failure group in the refreshed baseline artifact.

**Primary touched modules**

- [web/src/components/editor/DetailsExtension.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/editor/DetailsExtension.test.ts)
- [web/src/components/editor/DragHandle.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/editor/DragHandle.test.ts)
- [web/src/components/editor/FileAttachment.test.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/editor/FileAttachment.test.ts)
- [web/src/components/editor/ImageUpload.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/editor/ImageUpload.test.ts)
- [web/src/components/editor/MentionExtension.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/editor/MentionExtension.test.ts)
- [web/src/components/editor/TableOfContents.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/components/editor/TableOfContents.test.ts)
- [web/src/contexts/SelectionPersistenceContext.test.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/contexts/SelectionPersistenceContext.test.tsx)
- [web/src/hooks/useAutoSave.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/hooks/useAutoSave.test.ts)
- [web/src/hooks/useSelection.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/hooks/useSelection.test.ts)
- [web/src/hooks/useSessionTimeout.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/hooks/useSessionTimeout.test.ts)
- [web/src/lib/accountability.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/accountability.test.ts)
- [web/src/lib/api.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/api.test.ts)
- [web/src/lib/document-tabs.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/document-tabs.test.ts)
- [web/src/lib/http-error.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/lib/http-error.test.ts)
- [web/src/pages/Dashboard.test.tsx](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/pages/Dashboard.test.tsx)
- [web/src/styles/drag-handle.test.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/styles/drag-handle.test.ts)
- [web/src/test/setup.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/web/src/test/setup.ts)

### 2. High-risk E2E synchronization cleanup

**Objective**: Replace fixed sleeps in the highest-risk collaboration-sensitive specs with event/assertion-driven waits.

**Planned actions**

1. Prioritize specs already called out by the audit: autosave races, data integrity, drag/interaction stability, inline collaboration flows, and reconnect behavior.
2. Add or extend reusable helpers in `e2e/fixtures/test-helpers.ts` for editor readiness, sync completion, network-idle plus DOM-stability waits, and multi-page convergence checks.
3. Replace `waitForTimeout` calls only in the high-risk scope for this feature, leaving lower-risk cleanup for follow-on work if needed.
4. Keep assertions focused on observable outcomes: saved content, visible status, disabled editing, or persisted reload results.

**Primary touched modules**

- [e2e/fixtures/test-helpers.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/fixtures/test-helpers.ts)
- [e2e/autosave-race-conditions.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/autosave-race-conditions.spec.ts)
- [e2e/data-integrity.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/data-integrity.spec.ts)
- [e2e/race-conditions.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/race-conditions.spec.ts)
- [e2e/runtime-resilience-autosave.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-autosave.spec.ts)
- [e2e/runtime-resilience-reconnect.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-reconnect.spec.ts)
- [e2e/security.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/security.spec.ts)

### 3. New critical-flow E2E coverage

**Objective**: Add the three missing collaboration scenarios with deterministic fixture data and persisted-state assertions.

**Scenarios**

1. Concurrent overlap edit convergence with reload verification.
2. Offline edit replay exactly once after reconnect.
3. RBAC revocation during active collaboration, including blocked further write/sync attempts and persisted-state protection.

**Planned actions**

1. Extend `isolated-env.ts` to seed a deterministic workspace, two or more collaborating users, one revocable member/admin split, and at least one shared document configured for overlap and revocation tests.
2. Add explicit helper functions for seeding and logging in multiple users without test-local ad hoc inserts.
3. Place the new scenarios in focused spec files so the approved E2E runner can target them independently and rerun last failures cleanly.
4. Verify both live-session behavior and persisted reload state after each scenario.

**Primary touched modules**

- [e2e/fixtures/isolated-env.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/fixtures/isolated-env.ts)
- [e2e/fixtures/test-helpers.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/fixtures/test-helpers.ts)
- [e2e/race-conditions.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/race-conditions.spec.ts)
- [e2e/runtime-resilience-reconnect.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/runtime-resilience-reconnect.spec.ts)
- [e2e/security.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/security.spec.ts)
- [e2e/collaboration-convergence.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/collaboration-convergence.spec.ts)
- [e2e/offline-replay-exactly-once.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/offline-replay-exactly-once.spec.ts)
- [e2e/rbac-revocation-collaboration.spec.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/rbac-revocation-collaboration.spec.ts)

### 4. Baseline reporting and gating refresh

**Objective**: Publish updated pass/fail/flaky and coverage deltas and tighten the existing quality gates around the repaired paths.

**Planned actions**

1. Re-run the web unit coverage baseline after the deterministic failures are fixed.
2. Re-run the approved E2E subset through the runner workflow and capture pass/fail plus flaky evidence from `test-results/summary.json` and reporter output.
3. Update the consolidated audit report with current baseline values, the three new coverage entries, and root-cause summaries.
4. Tighten pre-merge expectations around the targeted web and E2E suites using current scripts and package commands rather than adding a new framework.

**Primary touched modules**

- [audits/consolidated-audit-report-2026-03-10.md](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/consolidated-audit-report-2026-03-10.md)
- [e2e/progress-reporter.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/e2e/progress-reporter.ts)
- [scripts/watch-tests.sh](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/scripts/watch-tests.sh)
- [playwright.config.ts](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/playwright.config.ts)
- [.husky/pre-commit](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/.husky/pre-commit)

## Dependency Order

1. Reproduce and classify the 13 web failures before editing tests or helpers so root-cause notes and fix scope are accurate.
2. Stabilize shared web test setup and any common helper resets before changing individual failing tests.
3. Add reusable E2E wait helpers before replacing fixed delays across high-risk specs.
4. Expand deterministic seed fixtures in `isolated-env.ts` before authoring the three new critical-flow scenarios.
5. Add the new E2E scenarios after the helpers and seed data exist so assertions stay concise and deterministic.
6. Refresh progress-reporting and baseline publication artifacts after the targeted suites pass twice.
7. Apply CI/pre-commit gate updates last, once the repaired command set and spec file locations are final.

## Test Strategy

### Unit

- Re-run the failing web Vitest suite with coverage enabled to confirm the original 13-failure set.
- Add or update direct regression assertions for each repaired failure group.
- Prefer deterministic fake-timer control, explicit cleanup, and isolated module resets over retries or looser expectations.

### Integration

- Add focused API or multi-layer assertions only where the new E2E scenarios require deterministic server responses for revocation or replay behavior.
- Validate persisted reload behavior after overlap convergence and offline replay by reopening the same document in a fresh page/context.

### E2E

- Use the project-approved runner workflow, not raw `pnpm test:e2e`.
- Run the high-risk updated specs and the three new scenarios in isolated worker environments with deterministic fixtures.
- Require two consecutive clean reruns of the targeted scenario subset before publishing the refreshed baseline.

## Flake-Reduction Strategy

- Replace `waitForTimeout` with `expect(...).toBe...`, `toPass`, explicit server readiness checks, and helper-backed DOM stabilization.
- Keep worker data isolated through `e2e/fixtures/isolated-env.ts`; do not rely on test-order side effects or shared mutable records.
- Use UTC-safe dates and explicit fixture IDs/names in seeds to avoid time-zone and naming collisions.
- Keep multi-test files serial only when scenarios mutate the same seeded records and isolation would otherwise be lost.
- Treat retries as diagnostic support only; they are not the success criterion for repaired tests.

## CI Gating Updates

- Keep the existing frameworks and strengthen the command contract:
  - `pnpm type-check`
  - `pnpm --filter @ship/web test:coverage -- --reporter=dot`
  - targeted approved E2E runner execution for the high-risk and new critical-flow subset
- Update `.husky/pre-commit` only if needed to add a lightweight guard that blocks new empty tests or stale targeted artifacts without expanding scope into full E2E execution.
- Use `test-results/summary.json` plus error logs as the machine-readable E2E gating evidence for the approved runner workflow.
- Publish coverage deltas and flaky counts in the audit artifact so release review can compare against the March 10, 2026 baseline.

## Observability and Reporting

- Extend the audit baseline section to include:
  - current web pass/fail counts after deterministic-failure repair
  - targeted E2E pass/fail/flaky counts for the high-risk subset
  - web and API coverage deltas versus the prior baseline
  - explicit status of the three critical-flow coverage gaps
- Keep Playwright progress reporting centered on `test-results/summary.json` and per-test error logs.
- Add a root-cause appendix or compact table that groups the 13 repaired failures by failure mode and fix pattern.

## Rollout and Rollback

### Rollout

1. Land web unit stabilization first so the suite becomes a trustworthy gate again.
2. Land helper and fixture improvements next, then add the three new E2E scenarios.
3. Refresh the audit baseline only after the targeted command set passes twice.
4. Turn on any stricter gating only after the repaired suites demonstrate determinism.

### Rollback

- Revert newly added E2E scenarios and helper changes independently if they introduce environmental instability while keeping the web unit fixes.
- Revert gating changes separately from test-content changes if the runner contract needs temporary relaxation.
- Preserve the last known good audit baseline until replacement evidence is complete.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Web failures hide real product defects instead of brittle tests | Fix scope expands beyond tests | Triage each failing case first; only change production code when the failure reflects a real deterministic defect |
| New E2E scenarios become flaky because collaboration timing is still implicit | False failures and weak signal | Centralize helper-based waits, assert persisted reload state, and run the targeted subset twice before baseline publication |
| Seed data for revocation or offline replay is under-specified | Silent skips or non-deterministic setup | Put all required users, roles, documents, and counts in `isolated-env.ts`; fail loudly on missing fixture expectations |
| Tightened gates slow delivery before stabilization is complete | CI churn | Sequence gating updates after proof of determinism and keep them scoped to targeted commands |
| Reporting deltas drift from actual runner outputs | Misleading release signal | Derive pass/fail/flaky numbers from `summary.json`, coverage commands, and dated audit updates only |

## Definition of Done

- The 13 known deterministic web unit failures are resolved and documented by root-cause category.
- High-risk E2E paths in scope no longer rely on `waitForTimeout` for synchronization.
- The three required E2E scenarios exist, use deterministic fixture data, and pass through the approved runner workflow.
- Updated pass/fail/flaky and coverage deltas are published against the prior baseline.
- Targeted quality gates are updated to use the repaired command set without changing the underlying test frameworks.

## Post-Design Constitution Check

- **Type Safety Audit**: Pass. Planned helper, fixture, and reporting updates remain typed and reuse existing project types.
- **Bundle Size Audit**: Pass. No production dependency or bundle-shipping code is added.
- **API Response Time**: Pass. No new endpoint contract is introduced; any supporting route assertions remain within existing paths.
- **Database Query Efficiency**: Pass. Fixture additions reuse current seeded document creation flows and require no schema or query expansion.
- **Test Coverage and Quality**: Pass. The design directly closes current gaps and removes sleep-based synchronization from the highest-risk area.
- **Runtime Errors and Edge Cases**: Pass. Overlap convergence, offline replay, active-session revocation, suite-order dependence, and persisted reload verification are all explicitly covered.
- **Accessibility Compliance**: Pass. No new UI is introduced, and changed tests continue to assert visible, role-based behavior.

**Post-Design Gate Result**: Pass.
