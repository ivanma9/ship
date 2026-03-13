# ADR-003: Migrate Deployment from AWS to Railway + Vercel

**Date:** 2026-03-13
**Status:** Accepted
**Deciders:** Ivan Ma

## Context

Ship runs on a full AWS stack: Elastic Beanstalk (API), Aurora PostgreSQL (database), S3 + CloudFront (frontend), WAF, VPC, and Terraform for infrastructure-as-code. Configuration is managed via AWS SSM Parameter Store, and deployments are triggered manually via shell scripts.

This is appropriate for an enterprise application but is over-engineered and expensive for a personal/portfolio project:
- **Cost:** Aurora Serverless + EB + CloudFront + WAF adds up to ~$80–200/month at minimum, even with zero traffic
- **Complexity:** Terraform state management, SSM bootstrapping, multi-service IAM, and two-tier deploy scripts create high maintenance burden
- **Deploy speed:** Manual `./scripts/deploy.sh prod` with Docker pre-validation takes 5–10 minutes per deploy

Ship needs WebSocket support for real-time Yjs/TipTap collaboration — this rules out fully serverless platforms (Vercel Functions, Lambda) for the backend.

## Decision

Replace the AWS infrastructure with:
- **Railway** — API backend (Docker-based) + managed PostgreSQL
- **Vercel** — React/Vite static frontend
- **GitHub Actions** — CI/CD pipeline that deploys automatically on merge to `master`

Config is injected as environment variables by Railway directly, eliminating the SSM dependency.

## Why

**Railway** is the right choice for the backend because:
1. Native persistent WebSocket connections (required for Yjs CRDT sync)
2. Managed PostgreSQL with automatic backups — no RDS/Aurora configuration
3. Deploys from the existing Dockerfile with zero infrastructure changes
4. Runs migrations on startup (`node dist/db/migrate.js`) — the existing pattern works unchanged
5. ~$5–15/month vs ~$80–200/month on AWS for this usage level

**Vercel** is the right choice for the frontend because:
1. Free tier for personal projects — indefinitely
2. Zero-config for Vite/React static builds
3. Automatic preview deployments per PR (better DX than manual CloudFront invalidation)
4. Global CDN with no configuration required

**GitHub Actions CD** closes the gap between CI (which already exists) and deployment, enabling automatic deploys without manual script execution.

## Consequences

**Good:**
- Deploy happens automatically on every merge to `master` — no manual steps
- Infrastructure cost drops to ~$5–15/month (Railway hobby tier)
- No Terraform, no SSM, no IAM roles, no VPC to maintain
- Frontend gets automatic PR preview deployments
- New contributor onboarding: just set 2 GitHub secrets, no AWS account needed

**Bad:**
- Lose WAF protection (acceptable: no sensitive data, personal portfolio)
- Lose multi-AZ high availability (acceptable: downtime tolerance for personal app)
- Railway is a third-party SaaS; outages are outside our control
- No existing Railway database to migrate to — fresh start (acceptable: portfolio app)

**Risks:**
- Railway pricing could increase; mitigated by the app being containerized (easy to move)
- Railway's managed Postgres is less configurable than Aurora; not a concern at this scale

## Alternatives Considered

| Option | Why rejected |
|--------|-------------|
| AWS App Runner | Simpler than EB but still AWS cost structure; SSM dependency remains |
| Fly.io | Good WebSocket support and Docker-native, but Railway's DX and managed Postgres are simpler for this use case |
| Render | Similar to Railway; Railway has better GitHub Actions integration |
| Vercel + serverless API | WebSocket connections cannot be held open in serverless functions; incompatible with Yjs |
| Keep AWS, add CI/CD | Doesn't address cost or complexity; just adds automation on top of an over-engineered stack |
