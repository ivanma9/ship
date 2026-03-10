# Category 7 Accessibility Compliance Audit (Ship)

Date: 2026-03-10  
Environment: local dev (`pnpm dev`)  
Base URL: `http://localhost:5174`  
Credentials used: `dev@ship.local` (seed user)

## Scope and Method

- Lighthouse accessibility audits run on major pages:
  - `/login`, `/dashboard`, `/my-week`, `/docs`, `/issues`, `/projects`, `/programs`, `/team/allocation`, `/settings`
- Automated scanner: `axe-core` (`@axe-core/playwright`) with WCAG 2.1 A/AA + Section 508 tags
- Keyboard navigation: automated Tab traversal coverage on each audited page (focus-reachability)
- Screen reader: structural proxy checks (heading/landmark presence) collected in automation
- Color contrast: extracted from axe `color-contrast` violations

Raw evidence:
- `summary.json`
- `lighthouse-*.json`
- `screenshot-*.png`

---

## Audit Deliverable (Baseline)

### Lighthouse Accessibility Score (per page)

| Page | Route | Score |
|---|---|---:|
| Login | `/login` | 100 |
| Dashboard | `/dashboard` | 95 |
| My Week | `/my-week` | 95 |
| Docs | `/docs` | 100 |
| Issues | `/issues` | 96 |
| Projects | `/projects` | 96 |
| Programs | `/programs` | 95 |
| Team Allocation | `/team/allocation` | 96 |
| Settings | `/settings` | 100 |

### Total Critical / Serious Violations

- Critical: **0**
- Serious: **34**
- Moderate: **0**
- Minor: **0**

All 34 serious violations were `color-contrast` failures.

### Keyboard Navigation Completeness

- Automated Tab reachability result: **Full** on all pages (Team Allocation reached 19/20 focusable targets, still >=90% threshold).
- Overall compliance call: **Partial** (Enter/Escape/Arrow interaction patterns were not exhaustively validated end-to-end in this automated run).

### Color Contrast Failures

- Total failures: **34**
- Primary affected pages:
  - `Dashboard` (10)
  - `My Week` (20)
  - `Issues` (1)
  - `Projects` (1)
  - `Programs` (1)
  - `Team Allocation` (1)

Representative failing selectors:
- `Dashboard`: `.bg-accent\/10`, `.text-accent.text-[10px].mb-1.5`, `.text-muted\/50` micro-labels in stat cards
- `My Week`: `.text-accent.font-medium.text-xs`, `.bg-surface.opacity-40 ... .text-xs`, `.ml-1.text-xs`
- List pages: `.mt-2` empty-state link text (`text-accent` on dark background)

Observed failure pattern from axe: accent blue `#005ea2` and muted text with opacity on dark surfaces frequently fall below 4.5:1.

### Missing ARIA Labels or Roles

- **No missing ARIA label/role violations** detected by axe in audited routes.

---

## Compliance Assessment

- Claim of broad WCAG 2.1 AA/Section 508 alignment is **mostly supported** by high Lighthouse scores and zero critical/ARIA failures.
- However, current state is **not fully conformant** due to 34 serious color-contrast failures.

---

## Improvement Target Strategy

Requested target options:
1. +10 Lighthouse on lowest page, or
2. Fix all Critical/Serious on 3 most important pages.

### Feasible target path

- Lowest score is 95, so +10 is mathematically impossible (max score is 100).
- Use option 2 on top 3 pages: **`/my-week`, `/dashboard`, `/issues`**.

### Plan to Achieve Target

1. Token-level contrast remediation
- Introduce dedicated text token for links/accents on dark backgrounds (e.g., `accent-text`) with >=4.5:1 contrast.
- Keep existing `accent` token for filled controls/buttons if needed.
- Stop using reduced-opacity muted text (`text-muted/50`) for content smaller than 14px.

2. Page-level fixes (highest impact first)
- `My Week`: update status pills and low-opacity rows (`text-xs` over dark/transparent surfaces).
- `Dashboard`: update KPI micro-labels and accent text in stat widgets.
- `Issues`: update empty-state/action link color from failing accent text to compliant token.

3. Verification loop
- Re-run this same audit script after each fix batch.
- Exit criteria for target:
  - 0 Critical and 0 Serious on `/my-week`, `/dashboard`, `/issues`.
  - No `color-contrast` violations on those three pages.

4. Guardrails to prevent regressions
- Add CI check that fails on new axe Critical/Serious issues for core routes.
- Add a lightweight Lighthouse accessibility threshold gate (for example >=96 on core routes).

### Expected Outcome

- Eliminates all currently observed severe issues on the three key pages.
- Should raise `My Week`/`Dashboard` Lighthouse scores into high-90s while preserving current strengths (ARIA/keyboard focus reachability).
