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
| /issues | Row actions have meaningful labels | FAIL | Ivan | 2026-03-13 | VoiceOver macOS / Safari | No "+" button visible at end of row — action label implementation may be for a feature not present in current UI; needs investigation |
| /issues | Empty state announced | PARTIAL | Ivan | 2026-03-13 | VoiceOver macOS / Safari | "No issues found" only visible on error/refresh state, not on normal empty list; role=status placement may be wrong or empty state not triggered correctly in normal flow |
| /issues | Keyboard traversal complete (all initially loaded rows) | PARTIAL | Ivan | 2026-03-13 | VoiceOver macOS / Safari | Arrow key navigation works; Tab exit works; Enter on row does NOT navigate to issue detail — primary action broken |
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
