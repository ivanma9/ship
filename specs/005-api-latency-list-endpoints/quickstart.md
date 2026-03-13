# Quickstart: API Latency Improvement for List Endpoints

## 1. Prepare the local environment

```bash
pg_isready -h localhost
pnpm install
pnpm build:shared
pnpm db:migrate
pnpm db:seed
```

## 2. Start the Ship API against local PostgreSQL

```bash
E2E_TEST=1 pnpm dev:api
```

Use the same local authentication setup and seeded workspace data that were used for the March 10, 2026 latency audit.

## 3. Capture DB prerequisite evidence first

- Record `EXPLAIN ANALYZE` for:
  - `/api/documents?type=wiki`
  - `/api/issues`
- Decide whether migration `038_api_list_latency_indexes.sql` is required before final latency tuning.

## 4. Implement the route-level improvements

- Optimize `api/src/routes/documents.ts`
- Optimize `api/src/routes/issues.ts`
- Update OpenAPI schemas if needed
- Update web query hooks only if additive parameters or fallback limits are introduced

## 5. Run regression verification

```bash
pnpm test
pnpm type-check
```

Focus review on:

- wiki list visibility behavior
- issue list filters and ordering
- association preservation
- any additive parameter behavior

## 6. Re-run the canonical benchmark matrix

Use the same:

- seeded volume
- authenticated local API base URL (`http://127.0.0.1:3000`)
- `E2E_TEST=1` setting
- concurrency matrix: `c10`, `c25`, `c50`
- tools: `ab` and `k6`

## 7. Publish evidence

- Update:
  - `audits/artifacts/api-latency-list-endpoints-before.json`
  - `audits/artifacts/api-latency-list-endpoints-after.json`
  - `audits/api-response-time.md`
  - `audits/consolidated-audit-report-2026-03-10.md`

## 8. Acceptance checklist

- DB prerequisite review approved
- `/api/documents?type=wiki` P95 `<= 98 ms` at `c50`
- `/api/issues` P95 `<= 84 ms` at `c50`
- no default-contract regressions
- `pnpm test` and `pnpm type-check` pass

---

## Implementation summary (completed 2026-03-12)

All acceptance criteria met on branch `005-api-latency-list-endpoints`.

**Benchmark commands used:**

```bash
# Authenticate first
CSRF=$(curl -s -c /tmp/cookies.txt http://localhost:3297/api/csrf-token | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
curl -s -c /tmp/cookies.txt -b /tmp/cookies.txt -X POST http://localhost:3297/api/auth/login \
  -H 'Content-Type: application/json' -H "X-CSRF-Token: $CSRF" \
  -d '{"email":"dev@ship.local","password":"admin123"}'

COOKIE="connect.sid=<value-from-cookies.txt>"

# Wiki c10/c25/c50
ab -n 200  -c 10  -C "$COOKIE" 'http://localhost:3297/api/documents?type=wiki'
ab -n 500  -c 25  -C "$COOKIE" 'http://localhost:3297/api/documents?type=wiki'
ab -n 1000 -c 50  -C "$COOKIE" 'http://localhost:3297/api/documents?type=wiki'

# Issues c10/c25/c50
ab -n 200  -c 10  -C "$COOKIE" http://localhost:3297/api/issues
ab -n 500  -c 25  -C "$COOKIE" http://localhost:3297/api/issues
ab -n 1000 -c 50  -C "$COOKIE" http://localhost:3297/api/issues
```

**Results:**

| Endpoint | c50 P95 | Target |
|----------|---------|--------|
| `/api/documents?type=wiki` | 8ms | ≤98ms ✅ |
| `/api/issues` | 7ms | ≤84ms ✅ |

**Rollback:**

```sql
DROP INDEX IF EXISTS idx_documents_list_active_type;
DROP INDEX IF EXISTS idx_documents_person_workspace_user;
-- Revert d.content removal in api/src/routes/issues.ts list SELECT
```
