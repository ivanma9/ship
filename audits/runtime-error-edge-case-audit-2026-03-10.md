# Category 6 Audit: Runtime Errors and Edge Cases

## Audit Deliverable


| Metric                                | Your Baseline                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Console errors during normal usage    | **24** (`audits/artifacts/console-main.log`, 10-minute active editing window)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| Unhandled promise rejections (server) | **1** observed server-side runtime rejection signal (`ForbiddenError: invalid csrf token`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Network disconnect recovery           | **Partial** (pass in baseline reconnect flow; partial under chaos due to redirect churn and aborted calls)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| Missing error boundaries              | `web/src/components/UnifiedEditor.tsx` (no clear user-facing boundary for autosave/collab hard failures); `web/src/pages/Login.tsx` (setup-status failures primarily surfaced in console)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| Silent failures identified            | 1) Autosave terminal failure is console-only (`web/src/hooks/useAutoSave.ts`) Repro: edit title/content, force repeated save failures, wait for retries to exhaust. 2) Reconnect-triggered session-expired redirect churn (`web/src/lib/api.ts`) Repro: edit doc, force 10s offline, reconnect. 3) Login rate limiting (`429`) can block valid credentials while UI shows generic "Login failed". Repro: repeat login attempts until rate-limited, then retry correct credentials. 4) Reviews button returns `403 Forbidden`. Repro: click Reviews. 5) On 3G + refresh, receiving collaborator stayed stale. Repro: throttle to 3G, refresh receiver, continue edits from sender. |

### Screenshot Evidence (Provided 2026-03-10)

| Screenshot | Attached Evidence | Mapped Finding(s) |
| --- | --- | --- |
| Gap 1 Screenshot | `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/assets/gap1.png` | Gap 1: concurrent title collision divergence |
| Gap 2 Screenshot | `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/assets/gap2.png` | Gap 2: reconnect redirect/auth churn |
| Gap 3 Screenshot | `/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/assets/gap3.png` | Gap 3: autosave failure visibility gap |


## 1. Scope

- Focus: runtime resilience under network instability, adversarial input, and concurrent edits.
- Repository: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`
- Test setup: local `pnpm dev`, demo auth user, headless Playwright.
- Runs executed: one long chaos session (~16 minutes with ~10 active editing minutes) and one targeted fuzz/collision session.

## 2. How We Measured


| Area                     | Tooling                 | Command(s)                                                              | Notes                                                      |
| ------------------------ | ----------------------- | ----------------------------------------------------------------------- | ---------------------------------------------------------- |
| Console/runtime errors   | Playwright + `rg`       | `pnpm exec node audits/artifacts/category6-runtime-chaos-audit.mjs`     | Counted error lines in `audits/artifacts/console-main.log` |
| Failed network requests  | Playwright + `wc`/`rg`  | `wc -l < audits/artifacts/requestfailed.log`                            | Isolated disconnect and session-expiry patterns            |
| Concurrency collisions   | Playwright targeted run | `pnpm exec node audits/artifacts/category6-targeted-fuzz-collision.mjs` | Two clients edited the same title within ~50ms             |
| Input fuzzing/injection  | Playwright targeted run | `pnpm exec node audits/artifacts/category6-targeted-fuzz-collision.mjs` | Tested empty title, 52k-char title, XSS/SQL-like payloads  |
| Server integrity signals | API dev logs            | `pnpm dev` output correlation                                           | Tracked CSRF failures and reconnect churn during chaos     |


### Execution Path

1. Started `pnpm dev` and confirmed API and web were reachable.
2. Ran `audits/category6-runtime-chaos-audit.mjs`.
3. Collected `audits/artifacts/console-main.log` and `audits/artifacts/requestfailed.log`.
4. Ran `audits/category6-targeted-fuzz-collision.mjs`.
5. Counted baseline values with `rg`/`wc` and mapped issues to:
  - `web/src/hooks/useAutoSave.ts`
  - `web/src/lib/api.ts`
  - `web/src/components/UnifiedEditor.tsx`
  - `web/src/pages/Login.tsx`

## 3. Five-Vector Findings

- Client resilience and observability: no browser unhandled rejections, but 24 console errors and multiple user-silent failures, including generic login messaging when the backend rate-limits even valid credential attempts.
- Network resilience: baseline disconnect/reconnect preserved collaborative data and UI state, but degraded conditions still showed failures (10-second chaos redirect/abort churn and a user-observed 3G-refresh stale receiver).
- Input fuzzing and security: script payload did not persist as raw `<script>`; long title acceptance suggests potential validation mismatch risk.
- Concurrency and race conditions: near-simultaneous title edits diverged between clients, and one startup case showed mismatched shared versions that converged only after leaving and reopening the document.
- Server integrity: CSRF rejection, reviews endpoint `403 Forbidden`, and frequent connect/disconnect cycles were visible; no clear burst of server 500s in artifacts.

## 4. Ranked Findings


| Rank | Severity | Finding                                              | Evidence                                                                                                                                    | User Impact                                                                                                                                   |
| ---- | -------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | P0       | Concurrent title edits diverge across clients        | `audits/artifacts/category6-targeted.json` (`final1 != final2`)                                                                             | Two users can each believe different final states are saved                                                                                   |
| 2    | P1       | Reconnect can trigger session-expired redirect churn | `audits/artifacts/requestfailed.log` shows 9 `login?expired=true&returnTo=` attempts + aborted calls                                        | Mid-edit disruption and possible loss of confidence in save state                                                                             |
| 3    | P1       | Autosave failures are mostly silent                  | `web/src/hooks/useAutoSave.ts` retries then logs terminal failure to console                                                                | User may assume content saved when it is not                                                                                                  |
| 4    | P1       | 3G refresh can leave receiving collaborator stale    | User-observed: after refresh on 3G, receiver did not update to new document edits                                                           | Receiver can work from outdated state and miss current edits after reconnect/refresh                                                          |
| 5    | P2       | Login rate-limit errors are not surfaced clearly     | User-observed repeated attempts can return `429 Too Many Requests` even when credentials are correct, while UI shows generic "Login failed" | Users cannot distinguish temporary lockout from credential problems, causing repeated retries and failed valid logins during cooldown windows |
| 6    | P2       | Initial collaboration version mismatch on open       | User-observed shared document versions differed on first open, then converged after navigating out of the doc and back in                   | Users can see stale/conflicting state at entry and may lose trust in real-time accuracy until manual re-entry                                 |
| 7    | P2       | Reviews button fails with `403 Forbidden`            | User-observed click on Reviews leads to `403 Forbidden` response                                                                            | Users cannot access review flow and may interpret this as a broken feature rather than a permission/state issue                               |


## 5. Top 3 Fixes

### Gap 1: Concurrent title collision divergence

- Repro:
  1. Open the same doc in two authenticated browser contexts.
  2. Update title in both within ~50ms.
  3. Observe divergent post-sync title values.
- Root cause: title updates use async patch/autosave flow outside CRDT convergence guarantees.
- Before: clients can display conflicting final titles.
- After (target): stale writes return `409 WRITE_CONFLICT`, and client prompts refresh/merge.
- Implementation sketch: add title-focused compare-and-swap on title patch (`expected_title` guard in SQL `WHERE` clause).
- Screenshot evidence:
![Gap 1 evidence](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/assets/gap1.png)

### Gap 2: Reconnect redirect storm after transient outage

- Repro:
  1. Start editing with active sync.
  2. Force offline for 10 seconds.
  3. Reconnect and observe aborted requests plus repeated `expired=true` redirects.
- Root cause: immediate redirect behavior on first `401` during reconnect turbulence.
- Before: short outages can kick users into redirect churn.
- After (target): apply short reconnect grace window and retry gate before forced session-expired redirect.
- Implementation sketch: add circuit-breaker style `401` deferral window in `web/src/lib/api.ts`.
- Screenshot evidence:
![Gap 2 evidence](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/assets/gap2.png)

### Gap 3: Autosave terminal failure has no persistent UI signal

- Repro:
  1. Edit title or content.
  2. Force repeated save failures (offline or forced 5xx).
  3. Wait for retries to exhaust and observe console-only failure.
- Root cause: autosave hook does not expose terminal error state to UI.
- Before: user receives no clear "not saved" status.
- After (target): sticky error banner/toast appears on terminal failure and clears only after successful save.
- Implementation sketch: add `onFailure` callback and exponential backoff handling in `useAutoSave`.
- Screenshot evidence:
![Gap 3 evidence](/Users/ivanma/Desktop/gauntlet/ShipShape/ship/audits/assets/gap3.png)

## 6. What Worked

- XSS hardening passed the tested payload: raw `<script>` did not persist.
- Collaborative editing survived disconnect/reconnect in baseline testing, and the UI recovered after reconnection.
- WebSocket collaboration recovered repeatedly during stable online periods.

## 7. Residual Risk and Limits

- Highest residual risk: non-CRDT title/property writes under contention.
- Confidence: medium-high for observed runtime failures; medium for DB persistence inference in collision scenario.
- Limits:
  - Targeted collision run did not include DB-readback verification for every write.
  - Local dev behavior may differ from production CDN/proxy behavior.
  - Top 3 gaps now have dedicated screenshots in `audits/assets/gap1.png`, `gap2.png`, and `gap3.png`.
  - Reviews `403` still has no dedicated screenshot artifact.

## 8. Boundary and Coverage

- Original run was diagnosis-only; remediation updates are tracked in Section 9.
- Artifacts are in `audits/artifacts/`; harness scripts are in `audits/`.
- Requirement status:
  - Three critical gaps with repro/cause/before/after: addressed.
  - User-facing confusion/data-loss scenario: addressed.
  - Explicit measurement path: addressed.
  - Per-gap screenshot/recording evidence for top 3 gaps: complete

## 9. Improvement Plan and Execution Update (2026-03-10)

### 9.1 Priority Plan

| Priority | Finding | Plan | Status |
| --- | --- | --- | --- |
| P0 | Concurrent title edits diverge across clients | Add title-focused optimistic concurrency token (`expected_title`) on document PATCH and return `409 WRITE_CONFLICT` on stale updates; wire title autosave to send token and prompt refresh on conflict. | **Implemented** |
| P1 | Reconnect redirect/auth churn | Add retry-once gate for transient 401s and a short delayed redirect window so successful reconnect traffic can cancel session-expired redirect. | **Implemented** |
| P1 | Autosave terminal failures are silent | Extend autosave hook with terminal success/failure callbacks and show persistent editor banner until successful save clears it. | **Implemented** |
| P2 | Login rate-limit (`429`) not clear | Normalize rate-limit responses to structured error shape and surface explicit lockout messaging in login UI. | **Implemented** |
| P2 | Reviews button leads to `403` confusion | Hide Reviews nav entry for non-admin users and show explicit admin-access message on direct URL access. | **Implemented** |
| P1/P2 | 3G stale receiver + initial collaboration mismatch | Add targeted collaboration lifecycle instrumentation and reconnect-sync assertions; tighten cache/provider handoff for slow refresh paths. | **Planned (next)** |

### 9.2 Code Changes Applied

- `api/src/routes/documents.ts`
  - Added optional `expected_title` on PATCH for title-specific optimistic locking (plus `expected_updated_at` fallback support).
  - Added optimistic concurrency guard with idempotent repeat-save tolerance for title updates.
  - Added `409 WRITE_CONFLICT` response with `current_updated_at`.
- `api/src/routes/documents.test.ts`
  - Added regression tests for stale `expected_updated_at` and stale `expected_title` conflict behavior.
- `web/src/components/UnifiedEditor.tsx`
  - Title autosave now sends `expected_title`.
  - Added persistent banner for terminal title-save failure, cleared on success.
- `web/src/hooks/useAutoSave.ts`
  - Added `onSuccess` / `onFailure` callbacks for terminal autosave visibility.
- `web/src/lib/api.ts`
  - Added reconnect retry gate for transient auth failures.
  - Added short delayed session-expired redirect and cancellation on successful requests.
  - Added API response normalization for non-standard error payloads (including rate limit).
- `api/src/app.ts`
  - Login limiter now returns structured `{ success: false, error: { code, message } }` JSON.
- `web/src/hooks/useAuth.tsx`, `web/src/pages/Login.tsx`
  - Added error code propagation and explicit `RATE_LIMITED` UI handling.
- `web/src/pages/App.tsx`, `web/src/pages/ReviewsPage.tsx`
  - Hide Reviews nav for non-admin users; clearer admin-only message on fetch.

### 9.3 Validation Run

- `pnpm --filter @ship/api exec vitest run src/routes/documents.test.ts -t "WRITE_CONFLICT"`: **pass**
- `pnpm --filter @ship/web type-check`: **pass**
- `pnpm --filter @ship/api type-check`: **pass**
- `pnpm --filter @ship/shared type-check`: **pass**
