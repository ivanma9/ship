# Category Audit Report

## 1. Scope
- Category: AI development cost
- Repository: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`
- Boundaries / assumptions:
  - Audit is repository-evidence only (code, config, docs in-repo).
  - No cloud billing export, runtime log archive, or SaaS billing portal data was provided.
  - “Development costs” interpreted as LLM API cost drivers + coding-agent cost observability.

## 2. Measurement Method
| Metric | Tool | Command | Methodology | Limitations |
|---|---|---|---|---|
| AI provider integrations in code | `rg` | `rg -n "OpenAI|openai|Anthropic|anthropic|Bedrock|InvokeModel" api/src web/src shared/src --glob '!**/node_modules/**'` | Count explicit LLM provider SDK usage and model references. | Static code only; does not prove runtime traffic volume. |
| AI request entry points | `rg` | `rg -n "analyze-plan|analyze-retro|/api/ai/status" api/src/routes api/src/openapi web/src/components` | Identify API endpoints and frontend call sites that can trigger LLM requests. | Cannot distinguish active vs dead code without runtime tracing. |
| Request/token caps per call path | `rg` + `sed` | `rg -n "RATE_LIMIT|MAX_CONTENT_TEXT_LENGTH|max_tokens|InvokeModelCommand" api/src/services/ai-analysis.ts api/src/routes/ai.ts api/src/openapi/schemas/ai.ts` | Read hard limits that bound spend (rate limit, input size, output cap). | Cap != observed usage. |
| Historical token/accounting fields | `rg` | `rg -n "prompt_tokens|completion_tokens|input_tokens|output_tokens|total_tokens|usage|cost" api/src web/src shared/src --glob '!**/node_modules/**'` | Check for persisted or logged token/cost telemetry fields. | String search can miss telemetry implemented externally (CloudWatch, APM, SaaS). |
| Coding-agent cost observability | `rg` | `rg -n "cursor|copilot|claude code|claude-cli|billing|seat|subscription|cost" --glob '!**/node_modules/**' .` | Identify whether repo captures coding-assistant billing or metering artifacts. | Provider dashboards and org invoices are outside repo. |

## 3. Baseline Numbers
| Baseline | Value | Unit | Denominator / Context |
|---|---|---|---|
| Direct LLM runtime providers wired in backend | 1 | provider | Anthropic via AWS Bedrock (`@aws-sdk/client-bedrock-runtime`) |
| Direct OpenAI runtime integrations | 0 | provider | No OpenAI SDK/runtime call path found in app code |
| AI analysis endpoints | 3 | endpoints | `GET /api/ai/status`, `POST /api/ai/analyze-plan`, `POST /api/ai/analyze-retro` |
| Frontend AI POST call sites | 4 | call sites | 2 banner call sites + 2 sidebar assistant call sites |
| Implemented per-user rate limit | 120 | requests/hour/user | `RATE_LIMIT = 120` in `api/src/services/ai-analysis.ts` |
| Documented/user-facing rate limit text | 10 | requests/hour/user | Route error text + OpenAPI descriptions still say 10 |
| Max output tokens per LLM request | 2048 | tokens/request | Bedrock payload `max_tokens` |
| Max input text length per analysis request | 50,000 | characters/request | `MAX_CONTENT_TEXT_LENGTH` guard |
| In-repo historical token ledger fields found | 0 | fields | No prompt/completion/total token fields in app code |
| In-repo historical LLM cost ledger fields found | 0 | fields | No per-call or aggregated cost persistence |
| **Claude Code development sessions tracked** | **41** | sessions | `.claude/tracking/tokens.json` (2026-03-12 → 2026-03-15) |
| **Claude Code total development spend** | **$251.26** | USD | Sum across all 41 tracked sessions |
| **Claude Code total tokens consumed** | **367.2M** | tokens | ~95–99% cache reads per session |
| Claude Sonnet 4.6 sessions | 30 | sessions | $102.20 total |
| Claude Opus 4.6 sessions | 11 | sessions | $148.54 total (Mar 15 only) |

### Coding-Agent Spend by Day
| Date | Sessions | Cost | Notes |
|------|----------|------|-------|
| 2026-03-12 | 2 | $9.39 | Sonnet only |
| 2026-03-13 | 14 | $43.42 | Sonnet only |
| 2026-03-14 | 7 | $26.87 | Sonnet only |
| 2026-03-15 | 18 | $171.58 | Opus introduced; 2 sessions alone = $90.31 |
| **Total** | **41** | **$251.26** | |

## 4. Findings (Ranked)
| Rank | Severity | Type | Finding | Evidence | Impact | Scope |
|---|---|---|---|---|---|---|
| 1 | P1 | Weakness | Historical LLM spend is not measurable from this repo today. | No token/cost telemetry fields in code search; no DB schema fields for LLM usage/cost. | You cannot answer “total tokens consumed”, “input/output split”, or “number of API calls made” for development/production from repository data alone. | API + data model + observability |
| 2 | P1 | Weakness | Rate-limit contract mismatch (120 implemented vs 10 documented) risks incorrect cost assumptions. | `api/src/services/ai-analysis.ts` has `RATE_LIMIT = 120`; route/OpenAPI say “Max 10 per hour”. | Stakeholders may under/over-estimate potential AI spend and throttling behavior. | API behavior + docs + tests |
| 3 | P2 | Weakness | Multiple frontend AI trigger paths exist (including legacy/duplicate-style components), increasing risk of accidental extra calls. | AI POST calls appear in both `PlanQualityBanner.tsx` and `sidebars/QualityAssistant.tsx`. | Without runtime instrumentation, duplicate-trigger regressions can increase cost unnoticed. | Web editor UX |
| 4 | P2 | Opportunity | Existing hard caps already bound worst-case per-request spend. | `MAX_CONTENT_TEXT_LENGTH = 50_000`, `max_tokens = 2048`, rate limit in service. | Good basis for budget guardrails once telemetry is added; reduces runaway usage risk. | AI analysis service |
| 5 | P2 | ~~Weakness~~ **Resolved** | Coding-agent costs (Claude Code) are now tracked in-repo via `.claude/tracking/tokens.json`. | 41 sessions, $251.26 total (2026-03-12 → 2026-03-15). Opus sessions on Mar 15 drove 59% of total spend ($148.54). | Development AI spend is now measurable; model selection is the key cost lever. | Engineering operations |

## 5. Notable Successes
- Success: AI analysis path includes explicit input/output limiters (`MAX_CONTENT_TEXT_LENGTH`, `max_tokens`) and per-user rate limiting.
- Why it matters: These controls cap per-request and per-user burn rate even before formal cost telemetry exists.
- Success: Claude Code development sessions are fully instrumented via `.claude/tracking/tokens.json` with per-session token counts, model used, and estimated cost.
- Why it matters: $251.26 in development spend is now fully accountable; we can see that Opus 4.6 (11 sessions = $148.54) costs 5× more than Sonnet 4.6 for similar tasks, enabling informed model routing decisions.

## 6. Residual Risk Summary
- Highest-risk area: Production runtime telemetry (Bedrock) remains unmeasured — cannot produce factual API spend from repo state.
- Confidence level: High for development AI spend (41 sessions tracked in-repo); low for production Bedrock usage (billing data absent).
- Unknowns / blind spots:
  - Actual production request volumes and Bedrock token usage over time.
  - Effective tokenization ratio (chars→tokens) by real user payloads.
  - AWS Cost Explorer attribution split for Bedrock usage.
- **Resolved since initial audit:** Claude Code development spend is now fully tracked ($251.26 across 41 sessions, 2026-03-12 → 2026-03-15).

## 7. Audit Boundary Reminder
- This audit reports diagnosis only.
- No fixes were implemented during this audit.
