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
| In-repo coding-agent billing records | 0 | artifacts | No Cursor/Copilot/Claude Code billing export or seat-cost tracking |

## 4. Findings (Ranked)
| Rank | Severity | Type | Finding | Evidence | Impact | Scope |
|---|---|---|---|---|---|---|
| 1 | P1 | Weakness | Historical LLM spend is not measurable from this repo today. | No token/cost telemetry fields in code search; no DB schema fields for LLM usage/cost. | You cannot answer “total tokens consumed”, “input/output split”, or “number of API calls made” for development/production from repository data alone. | API + data model + observability |
| 2 | P1 | Weakness | Rate-limit contract mismatch (120 implemented vs 10 documented) risks incorrect cost assumptions. | `api/src/services/ai-analysis.ts` has `RATE_LIMIT = 120`; route/OpenAPI say “Max 10 per hour”. | Stakeholders may under/over-estimate potential AI spend and throttling behavior. | API behavior + docs + tests |
| 3 | P2 | Weakness | Multiple frontend AI trigger paths exist (including legacy/duplicate-style components), increasing risk of accidental extra calls. | AI POST calls appear in both `PlanQualityBanner.tsx` and `sidebars/QualityAssistant.tsx`. | Without runtime instrumentation, duplicate-trigger regressions can increase cost unnoticed. | Web editor UX |
| 4 | P2 | Opportunity | Existing hard caps already bound worst-case per-request spend. | `MAX_CONTENT_TEXT_LENGTH = 50_000`, `max_tokens = 2048`, rate limit in service. | Good basis for budget guardrails once telemetry is added; reduces runaway usage risk. | AI analysis service |
| 5 | P2 | Weakness | Coding-agent costs (Cursor/Claude Code/Copilot) are not tracked in-repo. | Docs mention Claude workflow integration, but no billing/seat/usage ingest artifacts. | “Development AI cost” remains incomplete without pulling provider billing exports. | Engineering operations |

## 5. Notable Successes
- Success: AI analysis path includes explicit input/output limiters (`MAX_CONTENT_TEXT_LENGTH`, `max_tokens`) and per-user rate limiting.
- Why it matters: These controls cap per-request and per-user burn rate even before formal cost telemetry exists.

## 6. Residual Risk Summary
- Highest-risk area: Missing telemetry for token and call accounting (cannot produce factual total spend from repo state).
- Confidence level: High for structural findings (static code evidence), low for absolute dollar totals (billing data absent).
- Unknowns / blind spots:
  - Actual production/dev request volumes over time.
  - Effective tokenization ratio (chars->tokens) by real payloads.
  - AWS Cost Explorer attribution split for Bedrock usage.
  - External coding-agent SaaS invoices/seats.

## 7. Audit Boundary Reminder
- This audit reports diagnosis only.
- No fixes were implemented during this audit.
