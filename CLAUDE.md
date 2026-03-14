# ship Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-13

## Active Technologies
- TypeScript 5.x strict, Node 20 + React 18, Vite 5, Playwright + `@axe-core/playwright` (already in use), GitHub Actions (007-a11y-completion-gates)
- N/A (frontend-only changes; no schema changes) (007-a11y-completion-gates)

- TypeScript 5.x (strict), Node 20 + React 18, Vite 5, Rollup (via Vite), rollup-plugin-visualizer, TipTap, Yjs, emoji-picker-react, lowligh (006-bundle-size-reduction)

## Project Structure

```text
backend/
frontend/
tests/
```

## Commands

npm test && npm run lint

## Code Style

TypeScript 5.x (strict), Node 20: Follow standard conventions

## Recent Changes
- 007-a11y-completion-gates: Added TypeScript 5.x strict, Node 20 + React 18, Vite 5, Playwright + `@axe-core/playwright` (already in use), GitHub Actions

- 006-bundle-size-reduction: Added TypeScript 5.x (strict), Node 20 + React 18, Vite 5, Rollup (via Vite), rollup-plugin-visualizer, TipTap, Yjs, emoji-picker-react, lowligh

<!-- MANUAL ADDITIONS START -->
## Implementation Rules

5. **Before/After proof is mandatory.** Every improvement must include a reproducible benchmark or measurement showing the before state and the after state, run under identical conditions.
6. **Tests must still pass.** If any existing test breaks because of your change, you must either fix the test (with justification) or revert the change.
7. **Document your reasoning.** For each improvement, write a short explanation of: what you changed, why the original code was suboptimal, why your approach is better, and what tradeoffs you made.
8. **No cosmetic changes.** Renaming variables, reformatting code, or updating comments do not count as improvements unless they directly support a measurable change in one of the 7 categories.
9. **Commit discipline matters.** Each improvement should be in its own branch or clearly separated commit(s) with descriptive messages. We will read your git history.
<!-- MANUAL ADDITIONS END -->
