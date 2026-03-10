# API Response-Time Audit

Canonical record for Category 3 API response-time results.

## Scope

- Repository: `/Users/ivanma/Desktop/gauntlet/ShipShape/ship`
- Data volume used:
  - Documents: 572
  - Issues: 104
  - Users: 26
  - Sprints: 35
- Endpoints tested (common frontend flows):
  - `/api/documents?type=wiki`
  - `/api/issues`
  - `/api/projects`
  - `/api/programs`
  - `/api/weeks`
- Concurrency levels:
  - `c10` = 10 concurrent requests
  - `c25` = 25 concurrent requests
  - `c50` = 50 concurrent requests

## Method

- Ran authenticated benchmarks against local API `http://127.0.0.1:3000` with local PostgreSQL.
- Enabled `E2E_TEST=1` during runs to avoid rate-limit (`429`) contamination.
- Used two tools:
  - ApacheBench (`ab`) for baseline
  - `k6` for validation
- Reported P50/P95/P99 in milliseconds for each concurrency level.

## Audit deliverable Key Result (c50)

At 50-concurrency load, `/api/documents?type=wiki` and `/api/issues` are the slowest list endpoints and remain the primary optimization targets.

Metric format for this table: `(ab/k6)` in milliseconds.


| Audit Deliverable | Endpoint                   | P50             | P95             | P99             |
| ----------------- | -------------------------- | --------------- | --------------- | --------------- |
| 1                 | `/api/documents?type=wiki` | (101/110.92) ms | (123/138.65) ms | (131/153.41) ms |
| 2                 | `/api/issues`              | (87/97.48) ms   | (105/120.60) ms | (116/134.52) ms |
| 3                 | `/api/projects`            | (42/46.65) ms   | (54/57.40) ms   | (58/62.79) ms   |
| 4                 | `/api/weeks`               | (39/45.19) ms   | (46/54.22) ms   | (53/60.29) ms   |
| 5                 | `/api/programs`            | (30/34.79) ms   | (36/46.14) ms   | (40/49.59) ms   |


## Full Baseline Results (AB)


| Endpoint                   | c10 P50/P95/P99 (ms) | c25 P50/P95/P99 (ms) | c50 P50/P95/P99 (ms) |
| -------------------------- | -------------------- | -------------------- | -------------------- |
| `/api/documents?type=wiki` | 22/35/47             | 51/65/73             | 101/123/131          |
| `/api/issues`              | 17/28/41             | 41/55/61             | 87/105/116           |
| `/api/projects`            | 9/14/20              | 21/69/82             | 42/54/58             |
| `/api/programs`            | 6/10/12              | 15/20/21             | 30/36/40             |
| `/api/weeks`               | 8/12/15              | 20/25/28             | 39/46/53             |


## Full Validation Results (k6)


| Endpoint                   | c10 P50/P95/P99 (ms) | c25 P50/P95/P99 (ms) | c50 P50/P95/P99 (ms) |
| -------------------------- | -------------------- | -------------------- | -------------------- |
| `/api/documents?type=wiki` | 23.94/39.01/47.83    | 59.59/99.51/150.83   | 110.92/138.65/153.41 |
| `/api/issues`              | 17.72/32.80/59.52    | 48.70/108.85/140.73  | 97.48/120.60/134.52  |
| `/api/projects`            | 9.16/15.49/37.93     | 23.09/30.85/35.79    | 46.65/57.40/62.79    |
| `/api/programs`            | 6.60/9.84/13.20      | 17.40/38.64/47.49    | 34.79/46.14/49.59    |
| `/api/weeks`               | 8.34/16.34/23.61     | 20.97/30.33/35.69    | 45.19/54.22/60.29    |


## Notes

- Discarded one earlier AB run due to heavy rate-limiting and non-2xx responses.
- This file replaces earlier split API response-time and k6 report files.

## Improvement Plan

- Goal: reduce P95 by 20% on at least two endpoints under identical benchmark conditions.
- Primary targets (AB c50 baseline):
  - `/api/documents?type=wiki`: `123ms` -> `<=98ms`
  - `/api/issues`: `105ms` -> `<=84ms`

1. Reduce list-endpoint payload size.
2. Add targeted database indexes for current list query filters and sorts.
3. Re-run the same benchmark matrix (`c10/c25/c50`) with the same seeded volume.
4. Record before/after P95 deltas in this file.
5. If either target is missed, apply pagination/default limits and rerun.

