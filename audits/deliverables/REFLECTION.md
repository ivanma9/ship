# Audit Reflection

Post-audit reflection on AI tool usage and effectiveness.

---

## 1. Where were AI tools most helpful? Least helpful?

**Most helpful:**
- **Understanding codebases** — AI excelled at scanning, summarizing, and navigating large codebases quickly, giving a working mental model without manually reading every file.
- **Creating tasks and plans** — Generating structured task breakdowns and implementation plans from specs saved significant planning time.
- **Testing and implementing** — AI was effective at writing tests, implementing features from plans, and iterating through code changes.
- **Automatically chaining tasks** — Once a plan was in place, AI could move through sequential tasks without needing to be re-prompted for each step.

**Least helpful:**
- **Manual testing and deployment setup** — AI can't click through a UI or verify visual/functional behavior the way a human would. Setting up deployment pipelines also required hands-on verification it couldn't do.
- **Identifying the right metrics** — AI didn't always know which metrics mattered most because it doesn't interact with the product like a real user. It lacked intuition for what a user actually notices or cares about.
- **Simulating real user flows** — AI doesn't naturally explore the product the way a person does. In hindsight, documenting personal user flows or recording screen sessions would have been more valuable than relying on AI to guess the important paths.
- **Multi-user / concurrency scenarios** — AI struggled with simultaneous-user edge cases. When tackling real-time collaboration and concurrency problems, it made mistakes that required manual verification and correction.

---

## 2. Did AI help you understand the codebase, or shortcut understanding?

Initially, there was a lot of shortcut understanding — the first pass through audits prioritized speed over depth, leaning on AI summaries to move quickly. But on the second and third passes, I went deeper: investigating what the system actually meant, what best practices looked like, and where the real improvement opportunities were.

When I asked AI to analyze the codebase, I didn't just accept the output — I tried to understand the reasoning and verified claims against actual evidence in the code. Over time, the process shifted from "trust the summary" to "use AI as a starting point, then confirm it myself."

---

## 3. Where did you override or correct AI suggestions? Why?

- **E2E test assumptions** — AI would report that it successfully ran through a user flow, but when I manually verified, it had made wrong assumptions about the flow, tested the wrong edge case, or skipped steps entirely. I had to run E2E tests myself to catch these.
- **Tendency to pass tests rather than fix problems** — AI showed a consistent bias toward making tests green. Sometimes that meant it would edit the test assertions to match broken behavior instead of fixing the actual bug. I had to repeatedly redirect it: solve the problem, don't rewrite the test.
- **Lenient test writing** — Even when tests passed, they didn't always emulate real user behavior accurately. The "passing" result gave false confidence, and I had to verify what the test actually did before trusting it.
- **Requiring documented justification** — To prevent silent shortcuts, I established a rule: if AI wanted to change a test instead of fixing the underlying issue, it had to log the reasoning in `ERROR_ANALYSIS.md`. This forced deliberate decision-making and gave me an audit trail for why changes were made.

---

## 4. What percentage of your final code changes were AI-generated vs. hand-written?

**~95% AI-generated, ~5% hand-written.** The vast majority of code — implementation, tests, refactoring — was produced by AI. The hand-written portion was concentrated in deployment configuration and documentation, areas where AI couldn't reliably operate without hands-on verification.

---

## Notes

- **Trust but verify** — AI output can't be taken at face value. Every change needs review, and understanding the "why" before implementing is critical. Blindly applying AI suggestions leads to subtle breakage.
- **Isolate problem scope, but track dependencies** — Working category by category kept the AI focused, but it would lose sight of cross-cutting concerns. I had to repeatedly remind it to account for all files and dependencies involved in a change, not just the immediate target.
- **Brownfield caution** — In an existing codebase, modifying or deleting files carries real risk. I added documentation requirements for why a file was being changed or removed, creating an audit trail that prevented accidental regressions.
- **Sequential over parallel** — I initially tried tackling two audit categories simultaneously, but it caused problems: branches conflicted, context got confused, and spec-driven development broke down when scopes overlapped. Going sequentially, one category at a time, was slower but far more reliable.
- **Process improvement is iterative** — This was my first time through this kind of audit workflow, so I was learning and refining techniques as I went — better document organization, clearer workflows, stronger guardrails. The process wasn't perfect, but it establishes a foundation for the next brownfield project.
