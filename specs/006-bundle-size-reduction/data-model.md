# Data Model: Web Bundle Size Reduction

**Branch**: `006-bundle-size-reduction` | **Date**: 2026-03-13

## Overview

This feature is a build-system and frontend-architecture change. There are no new database tables, API endpoints, or persistent data entities. The "data" in scope is the bundle analysis artifact set (files produced by the build and committed/uploaded as CI artifacts).

---

## Entities

### BundleBaseline

Represents the before-change measurement, captured once from `master` before any optimization work begins.

| Field | Type | Description |
|-------|------|-------------|
| generatedAt | ISO 8601 string | Timestamp of the build run |
| totalBytes | number | Total dist directory size in bytes |
| totalKb | number | Total dist directory size in KB |
| totalMb | number | Total dist directory size in MB |
| entryChunkGzipKb | number | Gzipped size of the largest JS entry chunk in KB |

Stored as: `dist/bundle-size.json` (extended to include `entryChunkGzipKb`)

---

### BundleBudget

Configuration object defining the maximum allowed gzipped size per tracked chunk.

| Field | Type | Description |
|-------|------|-------------|
| entryChunkMaxGzipKb | number | Budget ceiling for the main entry JS chunk (gzip KB) |
| rationale | string | Human-readable note (e.g., "baseline 210 KB + 5% = 221 KB") |

Stored as: inline constant in `web/scripts/check-bundle-budget.mjs`

---

### BundleCheckResult

Output of the CI budget check script.

| Field | Type | Description |
|-------|------|-------------|
| chunkName | string | Filename of the measured chunk |
| actualGzipKb | number | Measured gzip size in KB |
| budgetGzipKb | number | Configured budget in KB |
| passed | boolean | true if actualGzipKb ≤ budgetGzipKb |
| delta | number | actualGzipKb − budgetGzipKb (negative = under budget) |

Output to: stdout (script exits 0 on pass, 1 on budget breach)

---

## State Transitions (CI artifact lifecycle)

```
master branch (pre-change)
  └─ run pnpm analyze  →  before-bundle-size.json, before-bundle-report.html
                              │
                              ▼
feature branch (post-change)
  └─ run pnpm analyze  →  after-bundle-size.json, after-bundle-report.html
                              │
                              ▼
CI bundle budget check
  └─ passes  →  artifacts uploaded, PR green
  └─ fails   →  CI exits 1, PR blocked with error message
```

---

## No New Database Entities

This feature does not touch:
- The `documents` table or any other PostgreSQL table
- Any API routes or shared types
- Any authentication or session logic

All changes are scoped to `web/` package (component files, build scripts) and `.github/workflows/ci.yml`.
