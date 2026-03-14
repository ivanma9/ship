

# Ship

**Project management that helps teams learn and improve**



---

## What is Ship?

Ship is a project management tool that combines documentation, issue tracking, and plan-driven weekly workflows in one place. Instead of switching between a wiki, a task tracker, and a spreadsheet, everything lives together.

**Built by the U.S. Department of the Treasury** for government teams, but useful for any organization that wants to work more effectively.

---

## How to Use Ship

Ship has four main views, each designed for different questions:


| View         | What it answers                                                |
| ------------ | -------------------------------------------------------------- |
| **Docs**     | "Where's that document?" — Wiki-style pages for team knowledge |
| **Issues**   | "What needs to be done?" — Track tasks, bugs, and features     |
| **Projects** | "What are we building?" — Group issues into deliverables       |
| **Teams**    | "Who's doing what?" — See workload across people and weeks     |


### The Basics

1. **Create documents** for anything your team needs to remember — meeting notes, specs, onboarding guides
2. **Create issues** for work that needs to get done — assign them to people and track progress
3. **Group issues into projects** to organize related work
4. **Write weekly plans** to declare what you intend to accomplish each week

Everyone on the team can edit documents at the same time. You'll see other people's cursors as they type.

---

## The Ship Philosophy

### Everything is a Document

In Ship, there's no difference between a "wiki page" and an "issue" at the data level. They're all documents with different properties. This means:

- You can link any document to any other document
- Issues can have rich content, not just a title and description
- Projects and weeks are documents too — they can contain notes, decisions, and context

### Plans Are the Unit of Intent

Ship is plan-driven: each week starts with a written plan declaring what you intend to accomplish and ends with a retro capturing what you learned. Issues are a trailing indicator of what was done, not a leading indicator of what to do.

1. **Plan (Weekly Plan)** — Before the week, write down what you intend to accomplish and why
2. **Execute (The Week)** — Do the work; issues track what was actually done
3. **Reflect (Weekly Retro)** — After the week, write down what actually happened and what you learned

This isn't paperwork for paperwork's sake. Teams that skip retrospectives repeat the same mistakes. Teams that write things down learn and improve.

### Learning, Not Compliance

Documentation requirements in Ship are visible but not blocking. You can start a new week without finishing the last retro. But the system makes missing documentation obvious — it shows up as a visual indicator that escalates from yellow to red over time.

The goal isn't to check boxes. It's to capture what your team learned so you can get better.

---

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) 20 or newer
- [pnpm](https://pnpm.io/) (`npm install -g pnpm`)
- [Docker](https://www.docker.com/) (for the database)

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/US-Department-of-the-Treasury/ship.git
cd ship

# 2. Install dependencies
pnpm install

# 3. Configure environment
cp api/.env.example api/.env.local
cp web/.env.example web/.env

# 4. Start the database
docker-compose up -d

# 5. Create sample data
pnpm db:seed

# 6. Run database migrations
pnpm db:migrate

# 7. Start the application
pnpm dev
```

### Open the App

Once it's running, open your browser to:

**[http://localhost:5173](http://localhost:5173)**

Log in with the demo account:

- **Email:** `dev@ship.local`
- **Password:** `admin123`

### What's Running


| Service      | URL                                                                              | Description                   |
| ------------ | -------------------------------------------------------------------------------- | ----------------------------- |
| Web app      | [http://localhost:5173](http://localhost:5173)                                   | The Ship interface            |
| API server   | [http://localhost:3000](http://localhost:3000)                                   | Backend services              |
| Swagger UI   | [http://localhost:3000/api/docs](http://localhost:3000/api/docs)                 | Interactive API documentation |
| OpenAPI spec | [http://localhost:3000/api/openapi.json](http://localhost:3000/api/openapi.json) | OpenAPI 3.0 specification     |
| PostgreSQL   | localhost:5432                                                                   | Database (via Docker)         |


### Common Commands

```bash
pnpm dev          # Start everything
pnpm dev:web      # Start just the web app
pnpm dev:api      # Start just the API
pnpm db:seed      # Reset database with sample data
pnpm db:migrate   # Run database migrations
pnpm test         # Run tests
```

---

## Technical Details

### Architecture

Ship is a monorepo with three packages:

- **web/** — React frontend with TipTap editor for real-time collaboration
- **api/** — Express backend with WebSocket support
- **shared/** — TypeScript types used by both

### Tech Stack


| Layer     | Technology                             |
| --------- | -------------------------------------- |
| Frontend  | React, Vite, TailwindCSS               |
| Editor    | TipTap + Yjs (real-time collaboration) |
| Backend   | Express, Node.js                       |
| Database  | PostgreSQL                             |
| Real-time | WebSocket                              |


### Design Decisions

- **Everything is a document** — Single `documents` table with a `document_type` field
- **Server is truth** — Offline-tolerant, syncs when reconnected
- **Boring technology** — Well-understood tools over cutting-edge experiments
- **E2E testing** — 73+ Playwright tests covering real user flows

See [docs/application-architecture.md](docs/application-architecture.md) for more.

### Repository Structure

```
ship/
├── api/                    # Express backend
│   ├── src/
│   │   ├── routes/         # REST endpoints
│   │   ├── collaboration/  # WebSocket + Yjs sync
│   │   └── db/             # Database queries
│   └── package.json
│
├── web/                    # React frontend
│   ├── src/
│   │   ├── components/     # UI components
│   │   ├── pages/          # Route pages
│   │   └── hooks/          # Custom hooks
│   └── package.json
│
├── shared/                 # Shared TypeScript types
├── e2e/                    # Playwright E2E tests
└── docs/                   # Architecture documentation
```

---

## Testing

```bash
# Run all E2E tests
pnpm test

# Run tests with UI
pnpm test:ui

# Run specific test file
pnpm test e2e/documents.spec.ts
```

Ship uses Playwright for end-to-end testing with 73+ tests covering all major functionality.

---

## Deployment

Ship can be deployed to **Railway + Vercel** (current production setup) or **AWS** (Elastic Beanstalk + S3/CloudFront).

---

### Option A: Railway + Vercel (current production)

#### Auto-deploy (recommended)

Both platforms watch `master` and deploy automatically on every push — no manual steps needed.

```bash
git push origin master
# Railway rebuilds and deploys the API automatically
# Vercel rebuilds and deploys the frontend automatically
```

#### Manual deploy — API (Railway CLI)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Authenticate
railway login

# Link to project (one-time setup)
railway link

# Deploy
railway up --detach
```

#### Manual deploy — Frontend (Vercel CLI)

```bash
# Install Vercel CLI
npm install -g vercel

# Build shared package first, then web
pnpm build:shared && pnpm --filter web build

# Deploy pre-built output to production
vercel deploy web/dist --prod --token $VERCEL_TOKEN
```

> **Note:** The Vercel GitHub App integration handles pnpm/corepack correctly. CLI deploys can hit corepack issues in some environments — see `docs/decisions/004-vercel-deployment-lessons.md` for details.

#### Environment variables (Railway API service)

| Variable         | Description                          |
| ---------------- | ------------------------------------ |
| `DATABASE_URL`   | PostgreSQL connection string         |
| `SESSION_SECRET` | Random 64-char hex string            |
| `CORS_ORIGIN`    | Vercel frontend URL                  |
| `APP_BASE_URL`   | Vercel frontend URL                  |
| `NODE_ENV`       | `production`                         |

> Do **not** set `AWS_REGION` — its absence enables the non-AWS config path in `api/src/config/ssm.ts`.

#### Environment variables (Vercel frontend)

| Variable       | Description              |
| -------------- | ------------------------ |
| `VITE_API_URL` | Railway API service URL  |

---

### Option B: AWS (Elastic Beanstalk + S3/CloudFront)

#### Prerequisites

- AWS CLI configured with credentials that have EB, S3, CloudFront, and SSM permissions
- Terraform installed
- SSM parameters bootstrapped (see `terraform/README.md`)

#### Deploy API (Elastic Beanstalk)

```bash
./scripts/deploy.sh prod
```

This script: builds the API, runs a Docker smoke test, zips a deployment bundle, uploads it to S3, and triggers a rolling EB update.

#### Monitor API rollout

```bash
# Poll every 30s until Health=Green and Status=Ready
aws elasticbeanstalk describe-environments \
  --environment-names ship-api-prod \
  --query 'Environments[0].[Health,HealthStatus,Status]'
```

#### Deploy Frontend (S3 + CloudFront)

```bash
# Build
pnpm build:shared && pnpm --filter web build

# Sync to S3
S3_BUCKET=$(cd terraform && terraform output -raw s3_bucket_name)
aws s3 sync web/dist/ s3://$S3_BUCKET/ --delete

# Invalidate CloudFront cache
DIST_ID=$(cd terraform && terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

#### Environment variables (EB)

| Variable         | Description                      |
| ---------------- | -------------------------------- |
| `DATABASE_URL`   | PostgreSQL connection string     |
| `SESSION_SECRET` | Cookie signing secret            |
| `CORS_ORIGIN`    | CloudFront frontend URL          |
| `APP_BASE_URL`   | CloudFront frontend URL          |
| `NODE_ENV`       | `production`                     |
| `AWS_REGION`     | e.g. `us-east-1`                 |

---

### Docker (local development)

```bash
# Build production images (context is repo root)
docker build -t ship-api .
docker build -t ship-web -f web/Dockerfile .

# Full local stack: Postgres + API + Web
pnpm docker:up
# Or: docker compose -f docker-compose.local.yml up --build
```

### Local Environment Variables

| Variable         | Description                  | Default  |
| ---------------- | ---------------------------- | -------- |
| `DATABASE_URL`   | PostgreSQL connection string | Required |
| `SESSION_SECRET` | Cookie signing secret        | Required |
| `PORT`           | API server port              | `3000`   |


---

## Security

- **No external telemetry** — No Sentry, PostHog, or third-party analytics
- **No external CDN** — All assets served from your infrastructure
- **Session timeout** — 15-minute idle timeout (government standard)
- **Audit logging** — Track all document operations

> **Reporting Vulnerabilities:** See [SECURITY.md](./SECURITY.md) for our vulnerability disclosure policy.

---

## Accessibility

Ship is Section 508 compliant and meets WCAG 2.1 AA standards:

- All color contrasts meet 4.5:1 minimum
- Full keyboard navigation
- Screen reader support
- Visible focus indicators

---

## Contributing

We welcome contributions. See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

---

## Documentation

- [Application Architecture](./docs/application-architecture.md) — Tech stack and design decisions
- [Unified Document Model](./docs/unified-document-model.md) — Data model and sync architecture
- [Document Model Conventions](./docs/document-model-conventions.md) — Terminology and patterns
- [Week Documentation Philosophy](./docs/week-documentation-philosophy.md) — Why weekly plans and retros work the way they do
- [Accountability Philosophy](./docs/accountability-philosophy.md) — How Ship enforces accountability
- [Accountability Manager Guide](./docs/accountability-manager-guide.md) — Using approval workflows
- [Contributing Guidelines](./CONTRIBUTING.md) — How to contribute
- [Security Policy](./SECURITY.md) — Vulnerability reporting

---

## License

[MIT License](./LICENSE)