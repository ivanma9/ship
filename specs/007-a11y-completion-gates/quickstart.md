# Quickstart: Accessibility Completion and Regression Gates

## Prerequisites
- Local PostgreSQL running
- `pnpm install` complete
- `pnpm db:seed` run (for authenticated E2E pages to render real content)

## Run the accessibility audit locally

```bash
# Start app in background (API + Web)
pnpm dev &

# Run the full audit (produces reports in audits/artifacts/accessibility/results/)
node audits/artifacts/accessibility/run-a11y-audit.mjs

# Or run just the axe E2E tests
pnpm --filter e2e exec playwright test e2e/accessibility.spec.ts --reporter=list
```

## Check a specific page for violations

```bash
# In the browser, open DevTools → Console, then:
# Install axe bookmarklet or use browser extension
# OR use Playwright REPL:
npx playwright open http://localhost:5173/issues
```

## Run keyboard traversal test manually

1. Open `/issues` in Chrome or Safari
2. Press Tab until focus enters the table
3. Use ArrowDown/ArrowUp to move between rows
4. Use ArrowRight/ArrowLeft to move between cells
5. Press Enter on a row to open the issue
6. Press Tab to exit the grid

## Run VoiceOver validation (macOS)

1. Enable VoiceOver: `Cmd + F5`
2. Open Safari → `http://localhost:5173/issues`
3. Use VO + Right Arrow to navigate through the table
4. Confirm each cell is announced as `"[Column]: [Value]"`
5. Record results in `docs/a11y-manual-validation.md`

## Check contrast on a specific element

```bash
# Using axe CLI (if installed globally):
npx axe http://localhost:5173/projects --tags wcag2aa --exit

# Or filter in the audit script output for color-contrast violations
node audits/artifacts/accessibility/run-a11y-audit.mjs 2>&1 | grep -i contrast
```

## Verify CI gate locally with act

```bash
# Install act: brew install act
act pull_request -j accessibility-gates
```
