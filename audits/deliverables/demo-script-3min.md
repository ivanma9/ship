# 3-Minute Demo Script — Ship Performance & Quality Sprint

**Total runtime:** ~3 minutes
**Format:** Live narration with screen/terminal evidence
**Audience:** Technical reviewers / evaluators

---

## [0:00–0:20] Hook — The Problem

> "Ship is a real-time collaborative doc platform — wiki, issues, sprints, all in one place. We ran a full audit across 7 categories. What we found was a 2 MB entry bundle, API responses taking over 100ms at load, and 34 accessibility violations blocking screen readers. Here's what we fixed."

---

## [0:20–0:50] Bundle Size — −55.8% Entry Chunk *(30 sec)*

**Show:** Terminal — `pnpm build` output or the budget script

> "Before our work, the entire app — TipTap editor, emoji picker, syntax highlighting — shipped in one 587 KB gzipped chunk. Every user downloaded the editor on page load, even if they never opened one."

**Call out on screen:**
```
BEFORE  Entry chunk gzip:  587.59 KB   (one monolithic chunk)
AFTER   Entry chunk gzip:  259.97 KB   (−55.8%)
        Lazy chunks added: +45 new files  (editor, emoji, highlight.js)
```

> "We lazy-loaded the TipTap editor, emoji picker, and highlight.js. First paint is now 55% lighter. A CI budget script blocks any future PR that pushes it back over 275 KB."

---

## [0:50–1:30] API Response Time — −94% at P95 *(40 sec)*

**Show:** Side-by-side terminal — `ab` benchmark before vs after (or JSON artifact)

> "The wiki list endpoint was our slowest — 123ms P95 at 50 concurrent users. PostgreSQL was doing a full sequential scan on every request."

**Call out on screen:**
```
BEFORE  /api/documents?type=wiki   P95 c50:  123 ms   (seq scan, 24 buffer hits)
AFTER   /api/documents?type=wiki   P95 c50:    8 ms   (−94%, 7 buffer hits)

BEFORE  /api/issues                P95 c50:  105 ms   (fetching full content column)
AFTER   /api/issues                P95 c50:    7 ms   (−93%)
```

> "Two composite partial indexes in migration 038, plus removing the full document content from the issue list query. EXPLAIN ANALYZE went from 2,527 buffer hits down to 32 on the issues endpoint."

---

## [1:30–1:55] Database Efficiency — Search CTE Merge *(25 sec)*

**Show:** `db-query-efficiency-baseline.json` vs `db-query-efficiency-after.json` (or narrate)

> "The search endpoint was firing two separate queries — one for people, one for documents — then merging in application code."

**Call out on screen:**
```
BEFORE  Search: 2 queries  →  0.979 ms total
AFTER   Search: 1 CTE      →  0.360 ms total   (−63%)
```

> "Merged into a single CTE with a UNION ALL. One round-trip instead of two. We also measured the main page flow: 54 queries on load, driven by an N+1 in the accountability service — partially addressed, still tracked."

---

## [1:55–2:25] Test Coverage — +15 Points Web *(30 sec)*

**Show:** Coverage summary diff or the two snapshot files side by side

> "Test coverage on the web package was at 33%. We added targeted unit tests for the highest-risk hooks and components."

**Call out on screen:**
```
BEFORE  API   stmt: 41.3%   branch: 34.3%
AFTER   API   stmt: 45.4%   branch: 38.0%   (+4 pts / +4 pts)

BEFORE  Web   stmt: 33.9%   branch: 24.1%
AFTER   Web   stmt: 49.4%   branch: 41.9%   (+15 pts / +18 pts)

E2E fixed waits:   619 → 537   (−82 hardcoded sleeps removed)
Dark-logic specs:    0 → 3     (reconnect, autosave, timeout — now tested)
```

> "We also replaced 82 hardcoded `waitForTimeout` calls with proper event-driven waits, and added three new specs for the dark logic paths that had zero test coverage."

---

## [2:25–2:55] Accessibility — 34 Violations → 0 *(30 sec)*

**Show:** `docs/a11y-manual-validation.md` contrast table, or Lighthouse score screenshots

> "axe-core flagged 34 serious contrast violations. Every page scored 95–96 on Lighthouse accessibility — not bad, but not compliant."

**Call out on screen:**
```
BEFORE  Lighthouse:  Dashboard 95 | My Week 95 | Issues 96
        Serious violations: 34  (all contrast failures)

AFTER   Lighthouse:  Dashboard 100 | My Week 100 | Issues 100
        Serious violations: 0   (app-wide sweep of 40+ components)
```

> "We swept 40+ components — focus rings, placeholders, text-accent tokens, mention chips. All WCAG AA compliant now. A Playwright + axe-core CI gate catches regressions on every PR."

---

## [2:55–3:00] Close

> "Five of seven categories fully measured before and after. Type safety and runtime error re-measurement are the open items. All changes are on master, CI green."

---

## Speaker Notes

- **Pacing:** Each section has a hard time box — don't expand on details, hit the number and move on.
- **Evidence order:** Show terminal/file first, then narrate the number. Don't narrate a number that isn't visible yet.
- **If asked about type safety:** "We audited 1,283 core violations and have a 4-phase plan targeting 25% reduction. Implementation deferred — that's an honest gap we're tracking."
- **If asked about runtime errors:** "Three targeted fixes shipped — autosave hook, reconnect guard, issues empty state. Full re-measurement pending under identical conditions."
