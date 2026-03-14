# 06 — Runtime Errors and Edge Cases

**Category:** Runtime Errors and Edge Cases
**Before Date:** 2026-03-10
**After Date:** 2026-03-13 (partial — see notes)
**Sources:** `audits/consolidated-audit-report-2026-03-10.md` (Section 6), `audits/artifacts/console-main.log`, `audits/artifacts/category6-targeted.json`

Runtime errors were captured by running the app under Playwright automation across authenticated page flows and recording browser console output. The `console-main.log` artifact contains the raw console capture from 2026-03-10. The `category6-targeted.json` artifact records a targeted fuzz/collision test result.

---

## Before — Runtime Error Baseline

_Source: `audits/consolidated-audit-report-2026-03-10.md`, Section 6; `audits/artifacts/console-main.log`_

| Metric | Baseline Value | Notes |
|--------|---------------|-------|
| Console `error` entries | 24 | Captured across page loads in `console-main.log` |
| Unhandled promise rejections | 1 | `Failed to check setup status: TypeError: Failed to fetch` (pre-auth load) |
| Silent failures (no UI feedback) | 5 | Swallowed fetch errors on unauthenticated routes |
| Known recurring error pattern | `Failed to load resource: 401 Unauthorized` | Fires on every page load before authentication resolves |
| CAIA auth error | 1 | `CAIA auth not available: TypeError: Failed to fetch` — benign/expected in local dev |
| Yjs collision divergence | Detected | `category6-targeted.json`: collision test showed `"inference": "Divergence"` between concurrent edits |
| XSS raw script injection | Not detected | `xssRawScriptTagInEditor: false` in fuzz results |

### Before — Recurring Error Classes

| Error Class | Count | Source |
|-------------|------:|--------|
| `401 Unauthorized` on initial resource load | Multiple per session | Pre-auth page load race |
| `Failed to check setup status` (unhandled rejection) | 1 | `Login.tsx` `checkSetup` on cold start |
| `CAIA not configured` / auth unavailable | 1 per session | Expected in local dev, benign |
| Silent fetch failures (no user-visible error state) | 5 | Various unauthenticated API calls |

---

## After — Tracked Fixes and Targets

_Source: `audits/consolidated-audit-report-2026-03-10.md`, Section 6 improvement plan; `docs/a11y-manual-validation.md`_

The following fixes were applied as part of the 007-a11y-completion-gates and related work (after-state measurements for raw error counts are not yet re-captured):

| Fix | Description | Status |
|-----|-------------|--------|
| `/issues` empty state error handling | Added `role=status aria-live=polite` to error state and normal empty state in `IssuesList.tsx` | Applied — re-test needed |
| `/issues` keyboard row handler | Row-level `onKeyDown Enter` handler added to each `<tr>` directly (no longer relies on table-level event bubbling) | Applied — re-test needed |
| Yjs collision divergence | Detected in `category6-targeted.json`; targeted fuzz-collision test added for regression tracking | Tracked |

### After — Improvement Plan Targets

| Metric | Before | Target | Notes |
|--------|-------:|-------:|-------|
| Console `error` entries | 24 | ≤ 5 | Remove pre-auth 401 noise via session guard; handle remaining fetch errors |
| Unhandled promise rejections | 1 | 0 | Wrap `checkSetup` in `Login.tsx` with rejection handler |
| Silent failures (no UI feedback) | 5 | 0 | Surface errors with `role=status` / toast patterns |

**Note:** After-state raw console error counts have not been re-measured under identical conditions. The table above reflects the improvement plan targets, not confirmed measurements. The three fixes listed above are the only confirmed runtime-error remediations applied in this sprint.

---

## Summary

The pre-optimization baseline had 24 browser console errors per session (dominated by pre-authentication 401 errors), 1 unhandled promise rejection, and 5 silent failures with no user-visible error state. Three targeted fixes were applied: empty-state error surfacing in `/issues`, keyboard row handler correction in `/issues`, and regression tracking for the Yjs collision divergence. Full re-measurement of console error counts under identical conditions is pending. XSS injection via the editor was not detected in fuzz testing.
