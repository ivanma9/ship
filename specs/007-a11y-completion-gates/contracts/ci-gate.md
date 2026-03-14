# Contract: CI Accessibility Gate

## Job name
`accessibility-gates` in `.github/workflows/ci.yml`

## Trigger
- Every push to `master`
- Every pull request targeting `master`

## Pass condition
All tests in `e2e/accessibility.spec.ts` pass: zero violations with `impact === "critical"` or `impact === "serious"` on every covered route.

## Fail condition
Any covered route returns ≥ 1 violation with `impact === "critical"` or `impact === "serious"`.

## Covered routes (minimum)
- `/login` (no auth)
- `/dashboard` (auth)
- `/issues` (auth)
- `/projects` (auth)
- `/programs` (auth)
- `/team/allocation` (auth)

## Artifact
On every run (pass or fail), upload `test-results/` as GitHub Actions artifact `a11y-gate-results` with 30-day retention.

## Blocking behavior
Job MUST be a required status check on `master` PRs. Merges MUST NOT proceed while this job is failing unless an active exception is recorded (per constitution Section VII exception policy).

## Extension protocol
To add a new route to coverage: add a test case to `e2e/accessibility.spec.ts` following the existing per-page pattern (navigate, waitForLoadState, AxeBuilder scan, assert zero critical/serious violations).
