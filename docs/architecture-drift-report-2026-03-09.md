# Architecture Drift Report (2026-03-09)

This document captures architecture documentation drift identified by comparing current docs against current code/schema.

Scope reviewed:
- `docs/unified-document-model.md`
- `docs/document-model-conventions.md`
- `docs/application-architecture.md`
- `api/src/db/schema.sql`
- `shared/src/types/document.ts`
- `api/src/routes/*` (focused on `issues.ts`, `weekly-plans.ts`, `documents.ts`)
- `api/src/collaboration/index.ts`

## Summary

Current architecture is materially ahead of docs in several areas (visibility model, relationship model, week data model, and state model).  
The most important drift is around **permissions** and **associations**, because those shape correctness/security decisions during implementation.

## Drift Findings

| Severity | Area | Docs Say | Code Says | Why It Matters |
| --- | --- | --- | --- | --- |
| High | Permissions model | Workspace-level visibility only; no per-document access controls (`docs/unified-document-model.md`) | Documents have `visibility` (`private`/`workspace`) and visibility checks in routes/collab (`api/src/db/schema.sql`, `api/src/middleware/visibility.ts`, `api/src/collaboration/index.ts`) | Engineers following docs can implement unsafe assumptions about document access. |
| High | Relationship storage | `program_id`/`project_id` represented as location columns (`docs/unified-document-model.md`) | Legacy columns removed; relationships use `document_associations` (`api/src/db/schema.sql`) | Data model decisions and query patterns are wrong if docs are followed literally. |
| High | Week plan/retro model | Weekly plan/retro described as week-document children (`docs/unified-document-model.md`, `docs/document-model-conventions.md`) | Model changed to per-person-per-week uniqueness (migration 037 + `weekly-plans` routes) | New feature work on planning/retro flows may use obsolete parent/child assumptions. |
| Medium | `week` vs `sprint` association type | Examples use `relationship_type='week'` and `updateWeekAssociation` (`docs/document-model-conventions.md`) | Runtime uses `sprint` association type + `updateSprintAssociation` (`shared/src/types/document.ts`, `api/src/db/schema.sql`, `api/src/utils/document-crud.ts`) | Causes implementation confusion and incorrect helper/type usage. |
| Medium | Association extensibility | Adding association types requires no schema change (`docs/document-model-conventions.md`) | `relationship_type` is Postgres enum, so new values require migration (`api/src/db/schema.sql`) | Underestimates change cost/risk for new association types. |
| Medium | Issue state model | 4 required states + custom workspace states (`docs/unified-document-model.md`) | Fixed enum enforced in API/types (`triage`, `backlog`, `todo`, `in_progress`, `in_review`, `done`, `cancelled`) (`api/src/routes/issues.ts`, `shared/src/types/document.ts`) | Product/UX planning for custom states diverges from backend constraints. |
| Low | Document type list | `view` document type listed as part of model (`docs/unified-document-model.md`) | `view` not in DB enum/shared type union (`api/src/db/schema.sql`, `shared/src/types/document.ts`) | Minor confusion about supported entities and roadmap status. |
| Low | Repo structure/examples | Examples reference paths like `web/src/stores`, `web/src/db`, `tsconfig.base.json`, and `api/src/db/pool.ts` (`docs/application-architecture.md`) | Current repo uses different structure (`api/src/db/client.ts`, root `tsconfig.json`; no `web/src/stores` or `web/src/db`) | Onboarding friction and reduced trust in architecture docs. |

## Evidence Pointers

- Visibility model in schema: `api/src/db/schema.sql` (`documents.visibility`).
- Visibility enforcement helper: `api/src/middleware/visibility.ts`.
- Collaboration access checks: `api/src/collaboration/index.ts` (`canAccessDocumentForCollab`).
- Relationship enum/table: `api/src/db/schema.sql` (`relationship_type` enum + `document_associations`).
- Shared association type: `shared/src/types/document.ts` (`BelongsToType` includes `sprint`, not `week`).
- Issue state validation: `api/src/routes/issues.ts` (`z.enum([...])` for state).
- Week dashboard model migration: `api/src/db/migrations/037_week_dashboard_model.sql`.
- Per-person-per-week uniqueness logic: `api/src/routes/weekly-plans.ts`.

## Recommended Doc Updates (Priority Order)

1. Update permissions sections in `docs/unified-document-model.md` to document `private`/`workspace` visibility and admin override behavior.
2. Remove stale `program_id`/`project_id` location-column language and standardize on `document_associations`.
3. Normalize terminology in docs to match runtime (`relationship_type='sprint'`, `updateSprintAssociation`) while preserving “week” as UI language.
4. Update week plan/retro architecture sections to reflect per-person-per-week model (and legacy `project_id` caveat).
5. Fix issue state docs to match enforced enum, or explicitly mark custom states as planned/not implemented.
6. Remove/mark `document_type='view'` as future roadmap rather than current model.
7. Refresh repository structure/examples in `docs/application-architecture.md` to current paths.

## Proposed Tracking

Create one cleanup PR titled: `docs: align architecture docs with runtime model (2026-03-09 drift report)` with checkboxes for each item above.
