# Manual Screen-Reader Validation

## Setup
- Browser: Safari (for VoiceOver) or Chrome (for NVDA)
- Seed: `pnpm db:seed` on local dev instance
- Login: dev@ship.local / admin123
- Screen reader: VoiceOver (macOS) — `Cmd + F5` to toggle

## Test Matrix

| Route | Criterion | Result | Tester | Date | SR Version | Notes |
|-------|-----------|--------|--------|------|------------|-------|
| /issues | All cells announced with column header | — | | | | |
| /issues | Row actions have meaningful labels | — | | | | |
| /issues | Empty state announced | — | | | | |
| /issues | Keyboard traversal complete (all initially loaded rows) | Pending manual verification — to be filled by developer before merge | | | | ARIA grid attributes added (aria-rowcount, aria-colcount, aria-rowindex, aria-colindex); ArrowLeft/Right cell navigation added in SelectableList |
| /projects | No serious contrast violations | — | | | | |
| /projects | Keyboard traversal complete | — | | | | |
| /programs | No serious contrast violations | — | | | | |
| /programs | Keyboard traversal complete | — | | | | |
| /team/allocation | No serious contrast violations | — | | | | |
| /team/allocation | Keyboard traversal complete | — | | | | |

## Evidence Format
- **PASS**: Fill in Tester name, Date (YYYY-MM-DD), SR Version (e.g. "VoiceOver macOS 14.3 / Safari 17")
- **FAIL**: Include element selector, violation description, and screenshot or recording reference in Notes

## CI Gate Validation
| Run | Branch | Result | Violation Introduced | Notes |
|-----|--------|--------|----------------------|-------|
| — | — | — | — | Fill during T027/T028 |
