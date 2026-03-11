# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Architectural Documentation

**Read `docs/*` before making architectural decisions.** These documents capture the design philosophy and key decisions:

- `docs/unified-document-model.md` - Core data model, sync architecture, document types
- `docs/application-architecture.md` - Tech stack decisions, deployment, testing strategy
- `docs/document-model-conventions.md` - Terminology, what becomes a document vs config
- `docs/sprint-documentation-philosophy.md` - Sprint workflow and required documentation

When in doubt about implementation approach, check these docs first.

## Commands

**PostgreSQL must be running locally before dev or tests.** The user has local PostgreSQL installed (not Docker).

```bash
# Development (runs api + web in parallel)
pnpm dev              # Auto-creates database, finds available ports, starts both servers

# Run individual packages
pnpm dev:api          # Express server on :3000
pnpm dev:web          # Vite dev server on :5173

# Build
pnpm build            # Build all packages
pnpm build:shared     # Build shared types first (required before api/web)

# Type checking
pnpm type-check       # Check all packages

# Database
pnpm db:seed          # Seed database with test data
pnpm db:migrate       # Run database migrations

# Unit tests (requires PostgreSQL running)
pnpm test             # Runs api unit tests via vitest
```

**What `pnpm dev` does** (via `scripts/dev.sh`):
1. Creates `api/.env.local` with DATABASE_URL if missing
2. Creates database (e.g., `ship_auth_jan_6`) if it doesn't exist
3. Runs migrations and seeds on fresh databases
4. Finds available ports (API: 3000+, Web: 5173+) for multi-worktree dev
5. Starts both servers in parallel

## Worktree Preflight Checklist

**Run this at the start of EVERY session on a worktree.** See `/ship-worktree-preflight` skill for full checklist and common issue fixes.

## E2E Testing

**ALWAYS use `/e2e-test-runner` when running E2E tests.** Never run `pnpm test:e2e` directly - it causes output explosion (600+ tests crash Codex). The skill handles background execution, progress polling via `test-results/summary.json`, and `--last-failed` for iterative fixing.

**Empty test footgun:** Tests with only TODO comments pass silently. Use `test.fixme()` for unimplemented tests. Pre-commit hook (`scripts/check-empty-tests.sh`) catches these.

**Seed data requirements:** When writing E2E tests that require specific data:
1. ALWAYS update `e2e/fixtures/isolated-env.ts` to create required data
2. NEVER use conditional `test.skip()` for missing data - use assertions with clear messages instead:
   ```typescript
   // BAD: skips silently
   if (rowCount < 4) { test.skip(true, 'Not enough rows'); return; }
   // GOOD: fails with actionable message
   expect(rowCount, 'Seed data should provide at least 4 issues. Run: pnpm db:seed').toBeGreaterThanOrEqual(4);
   ```
3. If a test needs N rows, ensure fixtures create at least N+2 rows

## Architecture

**Monorepo Structure** (pnpm workspaces):
- `api/` - Express backend with WebSocket collaboration
- `web/` - React + Vite frontend with TipTap editor
- `shared/` - TypeScript types shared between packages

**Unified Document Model**: Everything is stored in a single `documents` table with a `document_type` field (wiki, issue, program, project, sprint, person). This follows Notion's paradigm where the difference between content types is properties, not structure.

**Real-time Collaboration**: TipTap editor uses Yjs CRDTs synced via WebSocket at `/collaboration/{docType}:{docId}`. The collaboration server (`api/src/collaboration/index.ts`) handles sync protocol and persists Yjs state to PostgreSQL.

## Key Patterns

**4-Panel Editor Layout**: Every document editor uses the same layout: Icon Rail (48px) → Contextual Sidebar (224px, shows mode's item list) → Main Content (flex-1, editor) → Properties Sidebar (256px, doc-type-specific props). All four panels are always visible. See `docs/document-model-conventions.md` for the diagram.

**New document titles**: All document types use `"Untitled"` as the default title. No variations like "Untitled Issue" or "Untitled Project". The shared Editor component expects this exact string to show placeholder styling. See `docs/document-model-conventions.md` for details.

**Document associations**: Documents reference other documents via the `document_associations` junction table (relationship types: `parent`, `project`, `sprint`, `program`). Legacy columns `program_id` and `project_id` still exist; `sprint_id` was dropped by migration 027.

**Editor content**: All document types use the same TipTap JSON content structure stored in `content` column, with Yjs binary state in `yjs_state` for conflict-free collaboration.

**API routes**: REST endpoints at `/api/{resource}` (documents, issues, projects, weeks). Auth uses session cookies with 15-minute timeout.

## Adding API Endpoints

**All API routes must be registered with OpenAPI.** See `/ship-openapi-endpoints` skill for the full pattern (schema → register path → implement route). Result: Swagger + MCP tools auto-generated.

## Database

PostgreSQL with direct SQL queries via `pg` (no ORM). Schema defined in `api/src/db/schema.sql`.

**Migrations:** Schema changes MUST be in numbered migration files:

```
api/src/db/migrations/
├── 001_properties_jsonb.sql
├── 002_person_membership_decoupling.sql
└── ...
```

- Name files: `NNN_description.sql` (e.g., `003_add_tags.sql`)
- Migrations run automatically on deploy via `api/src/db/migrate.ts`
- The `schema_migrations` table tracks which migrations have been applied
- Each migration runs in a transaction with automatic rollback on failure

**Never modify schema.sql directly for existing tables.** Schema.sql is for initial setup only. All changes to existing tables go in migration files.

Local dev uses `.env.local` for DB connection.

## Deployment

**Just run the scripts.** Use `/workflows:deploy` for the full workflow, or run manually:

```bash
./scripts/deploy.sh prod           # Backend → Elastic Beanstalk
./scripts/deploy-frontend.sh prod  # Frontend → S3/CloudFront
```

**After deploy, verify with browser** (curl can't catch JS errors). Health checks:
- Prod API: `http://ship-api-prod.eba-xsaqsg9h.us-east-1.elasticbeanstalk.com/health`
- Prod Web: `https://ship.awsdev.treasury.gov`

**Shadow (UAT):** Deploy to shadow from `feat/unified-document-model-v2` before merging to master.

## Philosophy Enforcement

Use `/ship-philosophy-reviewer` to audit changes against Ship's core philosophy. Auto-triggers on schema changes, new components, or route additions. In autonomous contexts (ralph-loop), violations are fixed automatically.

**Core principles enforced:**
- Everything is a document (no new content tables)
- Reuse `Editor` component (no type-specific editors)
- "Untitled" for all new docs (not "Untitled Issue")
- YAGNI, boring technology, 4-panel layout

## Security Compliance

**NEVER use `git commit --no-verify`.** See `/ship-security-compliance` skill for pre-commit hooks (`comply opensource`), CI enforcement, and compliance check failure handling.

## Skills
A skill is a set of local instructions to follow that is stored in a `SKILL.md` file. Below is the list of skills that can be used. Each entry includes a name, description, and file path so you can open the source for full instructions when using a specific skill.
### Available skills
- category-audit: Audits and categorizes installed skills to keep skill inventories organized and discoverable. Use when users ask to group skills by domain, generate skill catalogs, identify coverage gaps, or maintain a skills taxonomy across local skill directories. (file: /Users/ivanma/.codex/skills/category-audit/SKILL.md)
### How to use skills
- Discovery: The list above is the skills available in this session (name + description + file path). Skill bodies live on disk at the listed paths.
- Trigger rules: If the user names a skill (with `$SkillName` or plain text) OR the task clearly matches a skill's description shown above, you must use that skill for that turn. Multiple mentions mean use them all. Do not carry skills across turns unless re-mentioned.
- Missing/blocked: If a named skill isn't in the list or the path can't be read, say so briefly and continue with the best fallback.
- How to use a skill (progressive disclosure):
  1) After deciding to use a skill, open its `SKILL.md`. Read only enough to follow the workflow.
  2) When `SKILL.md` references relative paths (e.g., `scripts/foo.py`), resolve them relative to the skill directory listed above first, and only consider other paths if needed.
  3) If `SKILL.md` points to extra folders such as `references/`, load only the specific files needed for the request; don't bulk-load everything.
  4) If `scripts/` exist, prefer running or patching them instead of retyping large code blocks.
  5) If `assets/` or templates exist, reuse them instead of recreating from scratch.
- Coordination and sequencing:
  - If multiple skills apply, choose the minimal set that covers the request and state the order you'll use them.
  - Announce which skill(s) you're using and why (one short line). If you skip an obvious skill, say why.
- Context hygiene:
  - Keep context small: summarize long sections instead of pasting them; only load extra files when needed.
  - Avoid deep reference-chasing: prefer opening only files directly linked from `SKILL.md` unless you're blocked.
  - When variants exist (frameworks, providers, domains), pick only the relevant reference file(s) and note that choice.
- Safety and fallback: If a skill can't be applied cleanly (missing files, unclear instructions), state the issue, pick the next-best approach, and continue.

## Active Technologies
- TypeScript across `api/`, `web/`, and `shared/` + Express, `pg`, React, Vite, TanStack Query, TipTap, Yjs, Zod (002-runtime-resilience)
- PostgreSQL for authoritative document state; IndexedDB/Yjs cache for editor state (002-runtime-resilience)

## Recent Changes
- 002-runtime-resilience: Added TypeScript across `api/`, `web/`, and `shared/` + Express, `pg`, React, Vite, TanStack Query, TipTap, Yjs, Zod
