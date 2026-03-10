import { createApp } from '../api/src/app.js';
import { pool } from '../api/src/db/client.js';
import request from 'supertest';

type QueryRecord = {
  text: string;
  values: unknown[] | undefined;
  durationMs: number;
};

type FlowResult = {
  flow: string;
  totalQueries: number;
  slowestMs: number;
  slowestSql: string;
  nPlusOneDetected: boolean;
  repeatedQueryCount: number;
};

type AuditResult = {
  at: string;
  flows: FlowResult[];
  slowestOverall: QueryRecord | null;
};

const allQueries: QueryRecord[] = [];
let flowQueries: QueryRecord[] = [];

const originalQuery = pool.query.bind(pool) as any;
(pool as any).query = async (text: any, values?: any) => {
  const started = process.hrtime.bigint();
  const result = await originalQuery(text, values);
  const ended = process.hrtime.bigint();
  const durationMs = Number(ended - started) / 1_000_000;

  const record: QueryRecord = {
    text: typeof text === 'string' ? text : text?.text ?? String(text),
    values: Array.isArray(values) ? values : (text?.values ?? undefined),
    durationMs,
  };

  allQueries.push(record);
  flowQueries.push(record);
  return result;
};

function normalizeSql(sql: string): string {
  return sql.replace(/\s+/g, ' ').trim();
}

function detectNPlusOne(queries: QueryRecord[]): { detected: boolean; maxRepeat: number } {
  const counts = new Map<string, number>();
  for (const q of queries) {
    const key = normalizeSql(q.text);
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  let maxRepeat = 0;
  for (const n of counts.values()) {
    if (n > maxRepeat) maxRepeat = n;
  }
  // Heuristic: same query shape repeated 6+ times in one flow is likely N+1
  return { detected: maxRepeat >= 6, maxRepeat };
}

function summarizeFlow(flow: string, queries: QueryRecord[]): FlowResult {
  const slowest = queries.reduce<QueryRecord | null>((acc, q) => {
    if (!acc || q.durationMs > acc.durationMs) return q;
    return acc;
  }, null);
  const n1 = detectNPlusOne(queries);

  return {
    flow,
    totalQueries: queries.length,
    slowestMs: Number((slowest?.durationMs ?? 0).toFixed(2)),
    slowestSql: slowest ? normalizeSql(slowest.text) : '',
    nPlusOneDetected: n1.detected,
    repeatedQueryCount: n1.maxRepeat,
  };
}

async function runFlow(name: string, fn: () => Promise<void>): Promise<FlowResult> {
  flowQueries = [];
  await fn();
  return summarizeFlow(name, flowQueries);
}

async function assertOk(res: request.Response, label: string): Promise<void> {
  if (res.status >= 400) {
    throw new Error(`${label} failed: ${res.status} ${JSON.stringify(res.body).slice(0, 400)}`);
  }
}

async function main() {
  const app = createApp('http://localhost:5173');
  const agent = request.agent(app);

  const csrf = await agent.get('/api/csrf-token');
  await assertOk(csrf, 'csrf');
  const token = csrf.body.token;

  const login = await agent
    .post('/api/auth/login')
    .set('x-csrf-token', token)
    .send({ email: 'dev@ship.local', password: 'admin123' });
  await assertOk(login, 'login');

  // Warm-up me endpoint once to ensure authenticated session
  const me = await agent.get('/api/auth/me');
  await assertOk(me, 'auth me');

  const docsRes = await agent.get('/api/documents');
  await assertOk(docsRes, 'documents bootstrap');
  const firstDocId: string | undefined = docsRes.body?.[0]?.id;

  const activeWeeksRes = await agent.get('/api/weeks');
  await assertOk(activeWeeksRes, 'weeks bootstrap');
  const firstWeekId: string | undefined = activeWeeksRes.body?.weeks?.[0]?.id;

  if (!firstDocId) {
    throw new Error('No documents found for view-document flow');
  }

  if (!firstWeekId) {
    throw new Error('No active weeks found for sprint-board flow');
  }

  const results: FlowResult[] = [];

  results.push(await runFlow('Load main page', async () => {
    await assertOk(await agent.get('/api/auth/me'), 'main/auth-me');
    await assertOk(await agent.get('/api/documents'), 'main/documents');
    await assertOk(await agent.get('/api/programs'), 'main/programs');
    await assertOk(await agent.get('/api/projects'), 'main/projects');
    await assertOk(await agent.get('/api/issues'), 'main/issues');
    await assertOk(await agent.get('/api/team/people'), 'main/team-people');
    await assertOk(await agent.get('/api/standups/status'), 'main/standup-status');
    await assertOk(await agent.get('/api/accountability/action-items'), 'main/action-items');
    await assertOk(await agent.get('/api/dashboard/my-week'), 'main/my-week');
  }));

  results.push(await runFlow('View a document', async () => {
    await assertOk(await agent.get(`/api/documents/${firstDocId}`), 'doc/get');
    await assertOk(await agent.get('/api/team/people'), 'doc/team-people');
    await assertOk(await agent.get('/api/programs'), 'doc/programs');
    await assertOk(await agent.get('/api/projects'), 'doc/projects');
  }));

  results.push(await runFlow('List issues', async () => {
    await assertOk(await agent.get('/api/issues'), 'issues/list');
    await assertOk(await agent.get('/api/team/people'), 'issues/team-people');
    await assertOk(await agent.get('/api/programs'), 'issues/programs');
    await assertOk(await agent.get('/api/projects'), 'issues/projects');
  }));

  results.push(await runFlow('Load sprint board', async () => {
    await assertOk(await agent.get(`/api/weeks/${firstWeekId}`), 'sprint/detail');
    await assertOk(await agent.get(`/api/weeks/${firstWeekId}/issues`), 'sprint/issues');
    await assertOk(await agent.get(`/api/weeks/${firstWeekId}/standups`), 'sprint/standups');
  }));

  results.push(await runFlow('Search content', async () => {
    await assertOk(await agent.get('/api/search/mentions?q=pro'), 'search/mentions');
  }));

  const slowestOverall = allQueries.reduce<QueryRecord | null>((acc, q) => {
    if (!acc || q.durationMs > acc.durationMs) return q;
    return acc;
  }, null);

  const report: AuditResult = {
    at: new Date().toISOString(),
    flows: results,
    slowestOverall,
  };

  console.log(JSON.stringify(report, null, 2));

  await pool.end();
  process.exit(0);
}

main().catch(async (err) => {
  console.error(err);
  try { await pool.end(); } catch {}
  process.exit(1);
});
