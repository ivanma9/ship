# 07 — Accessibility Compliance

**Audit Date:** 2026-03-10 · **Remediation Completed:** 2026-03-13

## Before

| Page | Lighthouse Score | Serious Violations |
|------|----------------:|-------------------:|
| `/login` | 100 | 0 |
| `/dashboard` | 95 | 10 |
| `/my-week` | 95 | 20 |
| `/docs` | 100 | 0 |
| `/issues` | 96 | 1 |
| `/projects` | 96 | 1 |
| `/programs` | 95 | 1 |
| `/team/allocation` | 96 | 1 |
| `/settings` | 100 | 0 |
| **Total** | — | **34** |

| Metric | Baseline |
|--------|----------|
| Color contrast failures | 34 (all Serious violations were contrast failures) |
| Missing ARIA labels / roles | None detected by axe |
| Keyboard navigation | Partial — global nav works; table content traversal incomplete |
| Manual VoiceOver | `/issues` table rows/cells silent (context not announced) |

## Fixes Applied

| Component / File | Element | Old Value | Old Ratio | New Value | New Ratio | WCAG |
|------------------|---------|-----------|----------:|-----------|----------:|:----:|
| Global CSS — focus | Focus ring (`:focus-visible`) | `#005ea2` | 2.89:1 | `#1a85d9` | 5.00:1 | PASS |
| Editor — placeholder | Editor placeholder text | `#525252` | 2.49:1 | `#808080` | 4.92:1 | PASS |
| Editor — drag handle | Drag handle (default) | `#525252` | 2.49:1 | `#808080` | 4.92:1 | PASS |
| Editor — mentions | `.mention` / `.mention-document` | `#5e6ad2` | 4.14:1 | `#6b7ae0` | 5.08:1 | PASS |
| `Programs.tsx` | Unassigned dash | `text-muted/50` | 2.50:1 | `text-muted` | 5.63:1 | PASS |
| `TeamMode.tsx` | Archived avatars | `bg-gray-400` | 2.30:1 | `bg-gray-500` | 4.60:1 | PASS |
| 40+ components | `text-accent` as text color | `#005ea2` | 2.89:1 | `#1a85d9` (via `text-accent-text`) | 5.00:1 | PASS |
| All files | `text-muted/<opacity>` variants | `#8a8a8a` at 30–60% | 1.41–2.57:1 | `text-muted` (100%) | 5.63:1 | PASS |
| `KanbanBoard` | Archived assignee avatar | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |
| `AccountabilityGrid` | Empty-state badge | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |
| `TeamDirectory` | Archived avatar | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |
| `IssuesList.tsx` | Row keyboard handler | — | — | `role=status` + keyboard row handler | — | PASS |

**Files touched:** `web/src/components/dashboard/DashboardVariantC.tsx`, `web/src/pages/MyWeekPage.tsx`, `web/src/components/IssuesList.tsx`, `web/src/components/DashboardSidebar.tsx`, 40+ components via `text-accent-text` token.

## After

| Metric | Before | After | Measurement Method | Status |
|--------|-------:|------:|-------------------|--------|
| Total Serious violations | 34 | 0 | axe automated scan | PASS |
| Total Critical violations | 0 | 0 | axe automated scan | PASS |
| Pages with Serious violations | 6 | 0 | axe automated scan | PASS |
| Lighthouse score `/dashboard` | 95 | 100 | Lighthouse | PASS |
| Lighthouse score `/my-week` | 95 | 100 | Lighthouse | PASS |
| Lighthouse score `/issues` | 96 | 100 | Lighthouse | PASS |
| CI regression gate | none | blocking | GitHub Actions `007-a11y-completion-gates` | PASS |

## Measurement

```bash
# Pre-requisites: pnpm dev running on :5173, DB seeded
SHIP_BASE_URL=http://localhost:5173 node audits/artifacts/accessibility/run-a11y-audit.mjs
```

Evidence bundles: `audits/artifacts/accessibility/results/`

## Key Decisions

- Selected "fix all Critical/Serious on 3 priority pages" over "+10 Lighthouse" because the lowest baseline score was 95 — a +10 improvement to 105 is impossible.
- App-wide `text-accent-text` token introduced to fix 40+ components without per-component edits; avoids future regressions when the accent color changes.
- Full manual VoiceOver/NVDA pass and table keyboard traversal remain pending (medium confidence gap).
