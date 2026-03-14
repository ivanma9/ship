# Data Model: Accessibility Completion and Regression Gates

**Feature**: 007-a11y-completion-gates
**Date**: 2026-03-13

---

## Overview

This feature has no new database entities. All changes are frontend ARIA/CSS modifications and CI configuration. The only "data" artifacts are evidence documents and structured test records.

---

## Evidence Artifacts

### Axe Violation Report (ephemeral CI artifact)

Produced per-run by `@axe-core/playwright`. Uploaded to GitHub Actions artifacts as `a11y-gate-results`.

```
Shape (per page):
{
  page: string,              // e.g. "/issues"
  violations: [
    {
      id: string,            // axe rule id, e.g. "color-contrast"
      impact: "critical" | "serious" | "moderate" | "minor",
      description: string,
      nodes: [{ html: string, failureSummary: string }]
    }
  ],
  passes: number,
  timestamp: ISO8601
}
```

**Retention**: GitHub Actions default (90 days). Not persisted to database.

---

### Manual Validation Record (durable doc)

Stored in `docs/a11y-manual-validation.md`. Structure:

```
Row fields:
- route: string             // e.g. "/issues"
- criterion: string         // e.g. "All cells announced with column header"
- result: "PASS" | "FAIL"
- tester: string            // name
- date: ISO date
- sr_version: string        // e.g. "VoiceOver macOS 14.3 / Safari 17"
- notes: string             // for FAILs: element selector + violation description
```

**Retention**: Committed to repo; lives alongside feature documentation permanently.

---

## ARIA Attribute Contract (SelectableList)

The enhanced `SelectableList` component exposes this ARIA tree to assistive technologies:

```
[role="grid", aria-label="<list name>", aria-rowcount=N, aria-colcount=M]
  [role="row", aria-rowindex=1]
    [role="columnheader", id="col-<name>"] ... (one per column)
  [role="row", aria-rowindex=2..N]
    [role="gridcell", aria-colindex=1..M, aria-label="<colHeader>: <value>"]
      <interactive children if any>
```

State attributes populated as needed:
- `aria-selected` on rows (already implemented)
- `aria-sort` on sortable column headers
- `aria-expanded` on rows with expandable children (future; not in scope)
