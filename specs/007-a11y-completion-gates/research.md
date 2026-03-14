# Research: Accessibility Completion and Regression Gates

**Feature**: 007-a11y-completion-gates
**Date**: 2026-03-13
**Status**: Complete — all unknowns resolved

---

## 1. Axe Integration for CI

**Decision**: Use `@axe-core/playwright` already present in the repo (imported in `e2e/accessibility.spec.ts` and `audits/artifacts/accessibility/run-a11y-audit.mjs`).

**Rationale**: No new dependency needed. The existing E2E suite already authenticates, navigates to each page, and runs axe scans — the CI job simply needs to execute these tests in the pipeline.

**Alternatives considered**:
- `jest-axe`: Requires jsdom, not suitable for full-page rendered tests.
- Lighthouse CI (`@lhci/cli`): Heavier; Lighthouse scores are already captured in audit scripts but overkill as a PR gate. Reserved for periodic audit runs.
- `eslint-plugin-jsx-a11y`: Useful for static analysis but does not catch runtime issues (dynamic ARIA, color contrast on rendered output). Can be added as a future enhancement.

---

## 2. CI Authentication Strategy

**Decision**: Use the existing `isolated-env` Playwright fixture (`e2e/fixtures/isolated-env.ts`) which authenticates via `dev@ship.local` / `admin123` against the seeded database. The CI job mirrors the existing E2E pattern.

**Rationale**: This is the exact mechanism already working for `e2e/accessibility.spec.ts` in the E2E suite. No new auth plumbing needed.

**Alternatives considered**:
- Static HTML snapshots (no auth needed): Would miss dynamic rendering, JavaScript-driven contrast issues, and ARIA state changes.
- Separate test user created in CI: Unnecessary complexity; seed data already provides the dev user.

---

## 3. ARIA Grid Pattern for SelectableList

**Decision**: Enhance `SelectableList` to fully implement the ARIA grid pattern: `role="grid"` container, `role="row"` per row, `role="columnheader"` for header cells, `role="gridcell"` for data cells. Add `aria-rowcount`, `aria-colcount`, `aria-rowindex`, `aria-colindex`.

**Rationale**: The component already has `role="grid"` and partial ARIA attributes. The gap is missing row/cell roles and count attributes that screen readers use to announce position (e.g., "row 3 of 47, column 2 of 6"). Adding these attributes is additive and does not change visual rendering or keyboard behavior.

**ARIA grid vs. ARIA table**:
- `role="table"` is for static read-only data.
- `role="grid"` is correct for interactive data grids where cells can receive focus and be activated — which matches SelectableList's behavior.

**Alternatives considered**:
- Native `<table>` element: Would require restructuring the DOM from flex-based layout to table layout. High risk of CSS regression. ARIA overlay on existing DOM is lower risk and equally valid per ARIA spec.
- `role="listbox"`: Wrong semantic — listbox is for selection lists, not 2D data grids.

---

## 4. Cell Announcement Pattern

**Decision**: Add `aria-label="[Column Header]: [Cell Value]"` to each `role="gridcell"` OR use `headers` attribute pointing to the column header cell's `id`. Use `aria-label` as the primary approach for dynamic content where header IDs may be generated.

**Rationale**: Screen readers in browse mode read gridcells in isolation; without explicit label association, VoiceOver reads only the cell content without column context. The `aria-label` pattern is widely supported and does not require DOM restructuring.

**Alternatives considered**:
- `headers` + `id` association: More semantically pure but requires each header cell to have a stable `id` and each data cell to reference it. Works well for static tables; fragile for dynamically rendered/virtualized lists. `aria-label` is more robust here.
- `aria-describedby`: Describes rather than labels; not the right choice for primary cell identification.

---

## 5. Contrast Fix Strategy

**Decision**: Surgical CSS token / Tailwind class swaps on the specific failing elements. No design system overhaul.

**Rationale**: The audit identified ≤3 serious contrast violations per page — specific elements using colors that fail the 4.5:1 ratio. Each can be addressed by changing the color class on that element to an existing passing alternative. No new tokens or brand changes needed.

**WCAG 2.1 AA thresholds**:
- Normal text (< 18pt / < 14pt bold): 4.5:1
- Large text (≥ 18pt / ≥ 14pt bold): 3:1
- UI components and graphical objects: 3:1

**Alternatives considered**:
- Design system color audit and global token update: Necessary eventually but out of scope for this sprint; would risk broad visual regressions.

---

## 6. Manual Validation Protocol

**Decision**: VoiceOver on macOS as primary validator; NVDA on Windows as documented secondary. Structured evidence table in `docs/a11y-manual-validation.md`.

**Rationale**: VoiceOver is available on all Apple developer machines without additional tooling. NVDA requires a Windows environment; it is documented for completeness but not mandatory for this sprint's sign-off.

**Screen reader + browser pairings**:
- VoiceOver + Safari: Recommended primary
- VoiceOver + Chrome: Acceptable secondary
- NVDA + Chrome: Windows secondary

**Alternatives considered**:
- Automated SR simulation (e.g., `aria-query` assertions): Useful for ARIA structure checks but does not replicate real SR announcement behavior. Manual validation is still required.
