# ADR-006: SameSite=None for Session Cookies in Production

**Date:** 2026-03-14
**Status:** Accepted
**Deciders:** Ivan

## Context

The frontend (`ship-frontend-web.vercel.app`) and API (`web-production-cd8b.up.railway.app`) are deployed on different domains (cross-origin). After login, the API sets a `session_id` cookie, but every subsequent API call returned 401. The session cookie was never sent by the browser.

Root cause: `SameSite=Strict` cookies are blocked by browsers on cross-origin fetch requests. The browser sets the cookie on login, but refuses to attach it to subsequent requests from a different origin.

The `express-session` middleware (used for CSRF) already used `SameSite=None` in production — the custom `session_id` cookie was the only inconsistency.

## Decision

Use `SameSite=None; Secure` in production and `SameSite=Strict` in local development. Implemented via a shared `sessionCookieOptions()` helper in `api/src/lib/cookie-options.ts`, imported by all cookie-setting code paths.

## Why

- `SameSite=None` is the only value that allows cookies to be sent on cross-origin requests
- `SameSite=Strict` is the correct default locally since frontend and API share the same origin (`localhost`)
- A single helper ensures the policy is consistent across all 5 call sites (login, logout, extend-session, session refresh, CAIA OAuth callback)

## Consequences

**Good:** Login works end-to-end in production. No more 401 floods after successful authentication.

**Bad:** `SameSite=None` cookies are sent on all cross-origin requests, including potential third-party embeds — mitigated by `HttpOnly` and the session validation logic.

**Risks:** If `NODE_ENV` is not set to `production` on Railway, cookies will still be `Strict` and the bug reappears. Verify env var on deploy.

## Alternatives Considered

| Option | Why rejected |
|--------|-------------|
| Proxy all API calls through Vercel (`/api/*` rewrites) | Adds latency, complicates WebSocket (Yjs collaboration), and ties frontend deployment to API availability |
| Move to a shared domain (subdomain cookies) | Requires DNS changes and a custom domain setup we don't have today |
| Store session in Authorization header (JWT) | Large refactor; changes auth model significantly |
