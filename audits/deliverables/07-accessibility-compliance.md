# 07 — Accessibility Compliance

**Category:** Accessibility Compliance (WCAG 2.1 AA / Section 508)
**Before Date:** 2026-03-10
**After Date:** 2026-03-13
**Sources:** `audits/accessibility-compliance-audit-2026-03-10.md`, `docs/a11y-manual-validation.md`

**How to Reproduce:**
```bash
# Pre-requisites: pnpm dev running on :5173, DB seeded
SHIP_BASE_URL=http://localhost:5173 node audits/artifacts/accessibility/run-a11y-audit.mjs
```

Accessibility was measured using Lighthouse (per-page accessibility score), axe (Critical/Serious/Moderate/Minor violations, contrast, ARIA/label checks), and Playwright Tab traversal. The automated audit was run as `SHIP_BASE_URL=http://localhost:5173 node audits/artifacts/accessibility/run-a11y-audit.mjs` against a locally seeded dev instance. Evidence bundles are in `audits/artifacts/accessibility/results/`.

---

## Before — Baseline Audit (2026-03-10)

_Source: `audits/accessibility-compliance-audit-2026-03-10.md`, Section 3_

| Page | Lighthouse Score | Critical Violations | Serious Violations |
|------|----------------:|-------------------:|-------------------:|
| `/login` | 100 | 0 | 0 |
| `/dashboard` | 95 | 0 | 10 |
| `/my-week` | 95 | 0 | 20 |
| `/docs` | 100 | 0 | 0 |
| `/issues` | 96 | 0 | 1 |
| `/projects` | 96 | 0 | 1 |
| `/programs` | 95 | 0 | 1 |
| `/team/allocation` | 96 | 0 | 1 |
| `/settings` | 100 | 0 | 0 |
| **Total** | — | **0** | **34** |

### Before — Additional Baseline Metrics

| Metric | Value |
|--------|-------|
| Color contrast failures | 34 (all Serious violations were contrast failures) |
| Missing ARIA labels / roles | None detected by axe |
| Keyboard navigation | Partial — global nav works; table content traversal incomplete |
| Manual VoiceOver | `/issues` table rows/cells silent (context not announced) |

---

## After — Final State (2026-03-13)

_Sources: `audits/accessibility-compliance-audit-2026-03-10.md` Section 5; `docs/a11y-manual-validation.md`_

### After — Priority Pages (Targeted Remediation)

| Page | Lighthouse Before | Lighthouse After | Critical+Serious Before | Critical+Serious After |
|------|------------------:|-----------------:|------------------------:|-----------------------:|
| `/dashboard` | 95 | **100** | 10 | **0** |
| `/my-week` | 95 | **100** | 20 | **0** |
| `/issues` | 96 | **100** | 1 | **0** |

### After — Full App Violation Summary

| Metric | Before | After | Delta |
|--------|-------:|------:|------:|
| Total Serious violations | 34 | **0** | −34 (−100%) |
| Total Critical violations | 0 | 0 | 0 |
| Pages with Serious violations | 6 | 0 | −6 |

**Note:** The March 10 audit reported 3 remaining Serious violations on `/projects`, `/programs`, and `/team/allocation` after the first remediation pass. These were resolved by the contrast sweep applied in the 007-a11y-completion-gates session (Session 2), confirmed by automated axe scan.

### After — Contrast Fixes Applied (Session 1 — 007-a11y-completion-gates)

_Source: `docs/a11y-manual-validation.md`_

| Element | Old Value | Old Ratio | New Value | New Ratio | WCAG Result |
|---------|-----------|----------:|-----------|----------:|:-----------:|
| Focus ring (`:focus-visible`) | `#005ea2` | 2.89:1 | `#1a85d9` | 5.00:1 | PASS |
| Editor placeholder text | `#525252` | 2.49:1 | `#808080` | 4.92:1 | PASS |
| Drag handle (default) | `#525252` | 2.49:1 | `#808080` | 4.92:1 | PASS |
| `.mention` / `.mention-document` text | `#5e6ad2` | 4.14:1 | `#6b7ae0` | 5.08:1 | PASS |
| Programs.tsx unassigned dash | `text-muted/50` | 2.50:1 | `text-muted` | 5.63:1 | PASS |
| TeamMode.tsx archived avatars | `bg-gray-400` | 2.30:1 | `bg-gray-500` | 4.60:1 | PASS |

### After — Contrast Fixes Applied (Session 2 — app-wide sweep)

| Element | Old Value | Old Ratio | New Value | New Ratio | WCAG Result |
|---------|-----------|----------:|-----------|----------:|:-----------:|
| `text-accent` as text color (40+ components) | `#005ea2` | 2.89:1 | `#1a85d9` (via `text-accent-text`) | 5.00:1 | PASS |
| `text-muted/<opacity>` variants (all files) | `#8a8a8a` at 30–60% | 1.41–2.57:1 | `text-muted` (100%) | 5.63:1 | PASS |
| KanbanBoard archived assignee avatar | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |
| AccountabilityGrid empty-state badge | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |
| TeamDirectory archived avatar | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | PASS |

### After — Remediation Files

| File | Change |
|------|--------|
| `web/src/components/dashboard/DashboardVariantC.tsx` | Contrast + ARIA fixes |
| `web/src/pages/MyWeekPage.tsx` | Contrast fixes |
| `web/src/components/IssuesList.tsx` | Contrast + `role=status` + keyboard row handler |
| `web/src/components/DashboardSidebar.tsx` | Contrast fixes |
| 40+ components (via `text-accent-text` token) | App-wide `text-accent` contrast sweep |

### Remaining Gaps

| Gap | Status |
|-----|--------|
| Full manual VoiceOver/NVDA pass on all pages | Pending — partial pass done on `/issues` |
| Keyboard traversal for table content (row/cell focus) | Partially addressed; re-test needed |
| CI regression gate (Lighthouse + axe on merge) | Configured in `007-a11y-completion-gates` CI job |

---

## Summary

All 34 Serious accessibility violations (100% contrast failures) were resolved. The three priority pages (`/dashboard`, `/my-week`, `/issues`) went from Lighthouse 95–96 to 100 with 0 Critical/Serious violations. The remaining three pages (`/projects`, `/programs`, `/team/allocation`) also reached 0 Serious violations after the app-wide contrast sweep. A CI regression gate was added to block new Critical/Serious violations on merge. Full manual screen-reader validation remains pending.

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Total Serious violations | 0 | 0 | PASS |
| Total Critical violations | 0 | 0 | PASS |
| Pages with Serious violations | 0 | 0 | PASS |
| Lighthouse score (priority pages) | 100 | 100 | PASS |

## Test Status

All unit tests pass: **547 tests across 36 test files**, 0 failures (vitest, 2026-03-15).
