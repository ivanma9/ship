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

## Color Contrast Audit — Before / After

Full WCAG 2.1 AA audit run 2026-03-13 against `#0d0d0d` background.

### Fixes Applied (Session 1 — 007-a11y-completion-gates)

| Element | Old Value | Old Ratio | New Value | New Ratio | WCAG Result |
|---|---|---|---|---|---|
| Focus ring (`:focus-visible`) | `#005ea2` | 2.89:1 | `#1a85d9` | 5.00:1 | ✅ PASS |
| Editor placeholder text | `#525252` | 2.49:1 | `#808080` | 4.92:1 | ✅ PASS |
| Drag handle (default) | `#525252` | 2.49:1 | `#808080` | 4.92:1 | ✅ PASS |
| Toggle block placeholder | `#525252` | 2.49:1 | `#808080` | 4.92:1 | ✅ PASS |
| Checkbox unchecked border | `#525252` | 2.49:1 | `#808080` | 4.92:1 | ✅ PASS |
| `.mention` / `.mention-document` text | `#5e6ad2` | 4.14:1 | `#6b7ae0` | 5.08:1 | ✅ PASS |
| Programs.tsx unassigned dash | `text-muted/50` | 2.50:1 | `text-muted` | 5.63:1 | ✅ PASS |
| TeamMode.tsx archived avatars | `bg-gray-400` | 2.30:1 | `bg-gray-500` | 4.60:1 | ✅ PASS |

### Fixes Applied (Session 2 — contrast sweep)

| Element | Old Value | Old Ratio | New Value | New Ratio | WCAG Result |
|---|---|---|---|---|---|
| `text-accent` as text color (40+ components) | `#005ea2` | 2.89:1 | `#1a85d9` (via `text-accent-text`) | 5.00:1 | ✅ PASS |
| `text-muted/<opacity>` variants (all files) | `#8a8a8a` at 30–60% | 1.41–2.57:1 | `text-muted` (100%) | 5.63:1 | ✅ PASS |
| KanbanBoard archived assignee avatar | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | ✅ PASS |
| AccountabilityGrid empty-state badge | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | ✅ PASS |
| TeamDirectory archived avatar | `bg-gray-400` + white | 2.54:1 | `bg-gray-500` + white | 4.60:1 | ✅ PASS |

### Known Acceptable Non-Fixes

| Element | Value | Ratio | Reason |
|---|---|---|---|
| `accent` token as bg-button | `#005ea2` + white text | 6.72:1 | Passes — white text on dark blue button |
| `accent-hover` as bg-button | `#0071bc` + white text | 5.14:1 | Passes — hover state only |
| `#5e6ad2` non-text UI (outlines, fills) | `#5e6ad2` | 4.14:1 | Non-text UI — only needs 3:1 (WCAG 1.4.11) |
| Status dots (`bg-gray-400`, `h-2 w-2`) | `#9ca3af` on dark | 7.66:1 | Decorative dots — no text content |

## CI Gate Validation
| Run | Branch | Result | Violation Introduced | Notes |
|-----|--------|--------|----------------------|-------|
| — | — | — | — | Fill during T027/T028 |
| Configured | 007-a11y-completion-gates | Configured | N/A | CI job added to ci.yml; validates on merge |
