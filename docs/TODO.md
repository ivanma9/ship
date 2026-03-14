# TODO — Post-Sprint Follow-up

Items deferred from the audit sprint. Each has a clear definition of done.

---

## Type Safety — Option A: Reduce Core Violations to ≤ 962 (−25% from baseline)

**Current state:** 1,143 core violations (was 1,283 baseline). Target: ≤ 962. Need −181 more.
**CI gate:** `scripts/check-type-ceiling.mjs` — ceiling at 1,143. Lower it after each phase.

### Phase 1 — API hotspot hardening (target −120)

- [ ] `api/src/routes/weeks.ts` — replace 48 non-null assertions (`!`) with explicit null checks; type the 26 `as` casts with proper interfaces
- [ ] `api/src/routes/issues.ts` — type `any` params in query handlers; replace unsafe `as` casts in response shaping
- [ ] After: re-run `node scripts/type-violation-scan.cjs`, update `CEILING` in `check-type-ceiling.mjs`, update `audits/deliverables/01-type-safety.md`

### Phase 2 — Web core flow typing (target −110)

- [ ] `web/src/pages/ReviewsPage.tsx` — add explicit types to 57 untyped params; replace 6 `as` casts
- [ ] `web/src/pages/App.tsx` — type 30 untyped params; fix missing return types on exported functions
- [ ] `web/src/components/IssuesList.tsx` — type 47 untyped params
- [ ] After: re-run scan, update ceiling and deliverable

### Phase 3 — Test and mock typing cleanup (target −70)

- [ ] `api/src/__tests__/transformIssueLinks.test.ts` — replace `any` mocks with typed fixtures using `mockQueryResult<T>`
- [ ] Any remaining `as any` casts in test files — replace with properly typed mocks
- [ ] After: re-run scan, update ceiling and deliverable

### Phase 4 — Lock-in

- [ ] Lower `CEILING` in `scripts/check-type-ceiling.mjs` to final achieved value
- [ ] Add `check-type-ceiling.mjs` to CI pipeline (`.github/workflows/`)
- [ ] Update `audits/deliverables/01-type-safety.md` with confirmed ≤ 962 measurement

---

## Runtime Errors — Category 6 Re-measurement

**Current state:** After-state not re-measured under identical conditions.
**What to do:**
- [ ] Run the app locally, navigate all 5 major flows (main page, doc view, issues, sprint board, search)
- [ ] Capture `console-main.log` equivalent (browser DevTools Console → Save as)
- [ ] Count: console errors, unhandled promise rejections, silent failures
- [ ] Update `audits/deliverables/06-runtime-errors-edge-cases.md` with confirmed numbers
- [ ] Target: ≤ 5 console errors, 0 unhandled rejections, 0 silent failures

---

## Login Redirect Issue

**Current state:** Possible redirect problem after login — destination URL may not be preserved or may redirect incorrectly in certain flows (e.g. deep links, session expiry, OAuth callback).

**Known trigger:** Session inactivity timeout (15-min inactivity / 12-hr absolute) fires and redirects the user to the login page, but the originally requested URL is not preserved — user lands on `/` after re-authenticating instead of where they were.

**What to do:**
- [ ] Reproduce: stay idle for 15 min on a deep page (e.g. `/issues/123`), wait for inactivity redirect to login, log back in — confirm landing page is `/` not `/issues/123`
- [ ] Check `web/src/hooks/useSessionTimeout.ts` — verify it captures `window.location.pathname` before redirecting and passes it as a `?returnTo=` param
- [ ] Check login success handler in `web/src/` — confirm it reads `returnTo` from query params and navigates there after auth
- [ ] Check `api/src/routes/` for any server-side 401 redirect that might strip the return URL
- [ ] Identify root cause: missing `returnTo` param, overwritten redirect, or race condition between auth state and router
- [ ] Fix and verify: after session timeout + re-login, user should land on the originally visited URL
- [ ] Add an E2E test: navigate to deep link → trigger session expiry → log in → assert correct redirect

---

## Specs/008 — Image Command Fix

**Current state:** Fix deferred; no before/after proof exists.
**What to do:**
- [ ] Implement fix per `specs/008-image-command-fix/tasks.md`
- [ ] Capture before state: screenshot or error log showing broken `/image` command
- [ ] Apply fix, capture after state: `/image` command works in production
- [ ] Create `audits/deliverables/08-image-command-fix.md` with before/after evidence
