# Manual Screen-Reader Validation

## Setup
- Browser: Safari (for VoiceOver) or Chrome (for NVDA)
- Seed: `pnpm db:seed` on local dev instance
- Login: dev@ship.local / admin123
- Screen reader: VoiceOver (macOS) — `Cmd + F5` to toggle

## Test Matrix

| Route | Criterion | Result | Tester | Date | SR Version | Notes |
|-------|-----------|--------|--------|------|------------|-------|
| /issues | All cells announced with column header | PASS | Ivan | 2026-03-13 | VoiceOver macOS / Safari | VoiceOver announces cell content correctly |
| /issues | Row actions have meaningful labels | N/A | Ivan | 2026-03-13 | VoiceOver macOS / Safari | "+" button only renders in "Show All Issues" mode (allowShowAllIssues + showAllIssues both true). aria-label is correct when button is visible. Re-test with Show All Issues enabled. |
| /issues | Empty state announced | FIXED — re-test needed | Ivan | 2026-03-13 | VoiceOver macOS / Safari | Error state ("something went wrong") now has role=status aria-live=polite. Normal empty state also has it. To test: filter issues to zero results or trigger an error state. |
| /issues | Keyboard traversal complete (all initially loaded rows) | FIXED — re-test needed | Ivan | 2026-03-13 | VoiceOver macOS / Safari | Row-level onKeyDown Enter handler added directly to each tr — no longer depends on table-level event bubbling. Re-test Enter navigation in VoiceOver. |
| /projects | No serious contrast violations | PASS | automated | 2026-03-13 | | Confirmed by automated axe scan (zero serious violations) |
| /projects | Keyboard traversal complete | — | | | | |
| /programs | No serious contrast violations | PASS | automated | 2026-03-13 | | Confirmed by automated axe scan (zero serious violations) |
| /programs | Keyboard traversal complete | — | | | | |
| /team/allocation | No serious contrast violations | PASS | automated | 2026-03-13 | | Confirmed by automated axe scan (zero serious violations) |
| /team/allocation | Keyboard traversal complete | — | | | | |

## Evidence Format
- **PASS**: Fill in Tester name, Date (YYYY-MM-DD), SR Version (e.g. "VoiceOver macOS 14.3 / Safari 17")
- **FAIL**: Include element selector, violation description, and screenshot or recording reference in Notes

## CI Gate Validation
| Run | Branch | Result | Violation Introduced | Notes |
|-----|--------|--------|----------------------|-------|
| — | — | — | — | Fill during T027/T028 |
| Configured | 007-a11y-completion-gates | Configured | N/A | CI job added to ci.yml; validates on merge |
