# AI Cost Analysis

## Development Costs — All Sessions

| Date | Sessions | Model(s) | Total Tokens | Cost (USD) |
|------|----------|----------|-------------|------------|
| 2026-03-12 | 2 | Sonnet 4.6 | 22.8M | $9.39 |
| 2026-03-13 | 12 | Sonnet 4.6 | 119.8M | $43.42 |
| 2026-03-14 | 7 | Sonnet 4.6 | 61.2M | $26.87 |
| 2026-03-15 | 21 | Sonnet 4.6 + **Opus 4.6** | 163.4M | $171.58 |
| | **Total** | | **367.2M** | **$251.26** |

### 2026-03-15 Model Breakdown

| Model | Sessions | Cost |
|-------|----------|------|
| claude-sonnet-4-6 | 10 | $23.03 |
| claude-opus-4-6 | 11 | $148.54 |
| **Day total** | **21** | **$171.58** |

> **Note:** 2026-03-15 spike driven by switching to Opus 4.6 for complex sessions. Two sessions alone accounted for $90.31 (b191bc81: $54.72 at 29.2M tokens; f6975dac: $35.59 at 19.7M tokens).

---

## Per-Session Detail

| Date | Session ID (prefix) | Model | Total Tokens | Cost |
|------|---------------------|-------|-------------|------|
| 2026-03-12 | 90b794a3 | Sonnet 4.6 | 15.1M | $6.08 |
| 2026-03-12 | 5cd8cbf8 | Sonnet 4.6 | 7.8M | $3.31 |
| 2026-03-13 | 65eb1c01 | Sonnet 4.6 | 3.3M | $1.83 |
| 2026-03-13 | 13ed30a8 | Sonnet 4.6 | 13.9M | $6.25 |
| 2026-03-13 | 455c7218 | Sonnet 4.6 | 1.1M | $0.66 |
| 2026-03-13 | 683da97e | Sonnet 4.6 | 33.3M | $11.82 |
| 2026-03-13 | bb07e193 | Sonnet 4.6 | 27.2M | $12.43 |
| 2026-03-13 | cf07308c | Sonnet 4.6 | 2.8M | $1.55 |
| 2026-03-13 | 05d4981a | Sonnet 4.6 | 1.1M | $0.52 |
| 2026-03-13 | 9bb59247 | Sonnet 4.6 | 4.2M | $3.12 |
| 2026-03-13 | 53f6f02d | Sonnet 4.6 | 2.0M | $1.05 |
| 2026-03-13 | 729c5209 | Sonnet 4.6 | 0.07M | $0.14 |
| 2026-03-13 | dbf2a4cf | Sonnet 4.6 | 3.3M | $1.87 |
| 2026-03-13 | 0b44eeef | Sonnet 4.6 | 5.6M | $2.19 |
| 2026-03-14 | a564428b | Sonnet 4.6 | 16.9M | $6.33 |
| 2026-03-14 | ee70e60f | Sonnet 4.6 | 4.5M | $2.39 |
| 2026-03-14 | 4ce26ff9 | Sonnet 4.6 | 15.4M | $6.08 |
| 2026-03-14 | 0cb913e5 | Sonnet 4.6 | 8.1M | $3.89 |
| 2026-03-14 | 0b0582a5 | Sonnet 4.6 | 4.3M | $2.26 |
| 2026-03-14 | 671126cf | Sonnet 4.6 | 1.6M | $0.79 |
| 2026-03-14 | d16b80dd | Sonnet 4.6 | 10.5M | $5.14 |
| 2026-03-15 | 556996bc | Sonnet 4.6 | 0.10M | $0.09 |
| 2026-03-15 | 1524eb79 | **Opus 4.6** | 10.4M | $21.54 |
| 2026-03-15 | 8e05d086 | Sonnet 4.6 | 4.1M | $1.83 |
| 2026-03-15 | 00af2b3d | Sonnet 4.6 | 0.07M | $0.13 |
| 2026-03-15 | b191bc81 | **Opus 4.6** | 29.2M | **$54.72** |
| 2026-03-15 | 4fe47d50 | **Opus 4.6** | 0.49M | $2.47 |
| 2026-03-15 | 8801cc98 | **Opus 4.6** | 8.2M | $15.57 |
| 2026-03-15 | 76a74fd7 | **Opus 4.6** | 0.77M | $1.79 |
| 2026-03-15 | 9de3dd2e | **Opus 4.6** | 2.5M | $5.79 |
| 2026-03-15 | f6975dac | **Opus 4.6** | 19.7M | **$35.59** |
| 2026-03-15 | 8678a5b8 | **Opus 4.6** | 2.9M | $7.43 |
| 2026-03-15 | ba51cb6a | **Opus 4.6** | 0.19M | $1.27 |
| 2026-03-15 | a3e3b2bc | **Opus 4.6** | 0.36M | $1.28 |
| 2026-03-15 | 20be3a77 | Sonnet 4.6 | 22.1M | $9.31 |
| 2026-03-15 | 031bc601 | **Opus 4.6** | 0.27M | $1.09 |
| 2026-03-15 | d50b844a | Sonnet 4.6 | 24.7M | $9.22 |
| 2026-03-15 | ab9f47b0 | Sonnet 4.6 | 0.13M | $0.16 |
| 2026-03-15 | 8937f47f | Sonnet 4.6 | 0.96M | $0.58 |
| 2026-03-15 | b82433e9 | Sonnet 4.6 | 2.5M | $1.40 |
| 2026-03-15 | f651ccc1 | Sonnet 4.6 | 0.44M | $0.32 |

---

## Anthropic Pricing Reference

| Model | Input (per M) | Output (per M) | Cache Write | Cache Read |
|-------|--------------|----------------|-------------|------------|
| Claude Opus 4.6 | $15.00 | $75.00 | $18.75 | $1.50 |
| Claude Sonnet 4.6 | $3.00 | $15.00 | $3.75 | $0.30 |
| Claude Haiku 4.5 | $0.80 | $4.00 | $1.00 | $0.08 |

*Token counts include prompt caching. ~95%+ of tokens are cache reads, which significantly reduces cost vs. raw input pricing.*

---

## Cost Optimization Notes

1. **Opus vs Sonnet cost ratio:** Opus 4.6 costs 5x more on input, 5x on output, 5x on cache reads. Mar 15's Opus sessions cost $148.54 vs $23.03 for Sonnet — same day. Reserve Opus for brainstorming/review only.
2. **Cache leverage is high:** Cache reads dominate (~90–99% of tokens per session), keeping effective cost/token well below list price.
3. **Two sessions drove $90 alone** (b191bc81 + f6975dac on Mar 15) — both long Opus sessions. Limiting Opus session scope is the single biggest lever.
