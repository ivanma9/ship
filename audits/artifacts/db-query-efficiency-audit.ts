import { createApp } from '../../api/src/app.js';
import { pool } from '../../api/src/db/client.js';
import request from 'supertest';

type FlowKey =
  | 'load_main_page'
  | 'view_document'
  | 'list_issues'
  | 'load_sprint_board'
  | 'accountability_action_items'
  | 'search_content';

type QueryRecord = {
  text: string;
  values: unknown[] | undefined;
  durationMs: number;
};

type FlowResult = {
  flowKey: FlowKey;
  flow: string;
  totalQueries: number;
  slowestMs: number;
  slowestSql: string;
  nPlusOneDetected: boolean;
  repeatedQueryCount: number;
  targetQueryCount: number | null;
};

type AuditResult = {
  at: string;
  flows: FlowResult[];
  slowestOverall: QueryRecord | null;
};

const allQueries: QueryRecord[] = [];
let flowQueries: QueryRecord[] = [];

const flowMetadata: Record<FlowKey, { flow: string; targetQueryCount: number | null }> = {
  load_main_page: { flow: 'Load main page', targetQueryCount: null },
  view_document: { flow: 'View a document', targetQueryCount: null },
  list_issues: { flow: 'List issues', targetQueryCount: null },
  load_sprint_board: { flow: 'Load sprint board', targetQueryCount: null },
  accountability_action_items: { flow: 'Accountability action-items', targetQueryCount: null },
  search_content: { flow: 'Search content', targetQueryCount: 4 },
};

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

function summarizeFlow(flowKey: FlowKey, queries: QueryRecord[]): FlowResult {
  const slowest = queries.reduce<QueryRecord | null>((acc, q) => {
    if (!acc || q.durationMs > acc.durationMs) return q;
    return acc;
  }, null);
  const n1 = detectNPlusOne(queries);
  const metadata = flowMetadata[flowKey];

  return {
    flowKey,
    flow: metadata.flow,
    totalQueries: queries.length,
    slowestMs: Number((slowest?.durationMs ?? 0).toFixed(2)),
    slowestSql: slowest ? normalizeSql(slowest.text) : '',
    nPlusOneDetected: n1.detected,
    repeatedQueryCount: n1.maxRepeat,
    targetQueryCount: metadata.targetQueryCount,
  };
}

async function runFlow(flowKey: FlowKey, fn: () => Promise<void>): Promise<FlowResult> {
  flowQueries = [];
  await fn();
  return summarizeFlow(flowKey, flowQueries);
}

async function assertOk(res: request.Response, label: string): Promise<void> {
  if (res.status >= 400) {
    throw new Error(`${label} failed: ${res.status} ${JSON.stringify(res.body).slice(0, 400)}`);
  }
}

async function main() {
  const originalConsoleLog = console.log;
  console.log = (...args: unknown[]) => {
    const [first] = args;
    if (typeof first === 'string' && first.includes('CAIA not configured, skipping initialization')) {
      return;
    }
    originalConsoleLog(...args);
  };

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

  results.push(await runFlow('load_main_page', async () => {
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

  results.push(await runFlow('view_document', async () => {
    await assertOk(await agent.get(`/api/documents/${firstDocId}`), 'doc/get');
    await assertOk(await agent.get('/api/team/people'), 'doc/team-people');
    await assertOk(await agent.get('/api/programs'), 'doc/programs');
    await assertOk(await agent.get('/api/projects'), 'doc/projects');
  }));

  results.push(await runFlow('list_issues', async () => {
    await assertOk(await agent.get('/api/issues'), 'issues/list');
    await assertOk(await agent.get('/api/team/people'), 'issues/team-people');
    await assertOk(await agent.get('/api/programs'), 'issues/programs');
    await assertOk(await agent.get('/api/projects'), 'issues/projects');
  }));

  results.push(await runFlow('load_sprint_board', async () => {
    await assertOk(await agent.get(`/api/weeks/${firstWeekId}`), 'sprint/detail');
    await assertOk(await agent.get(`/api/weeks/${firstWeekId}/issues`), 'sprint/issues');
    await assertOk(await agent.get(`/api/weeks/${firstWeekId}/standups`), 'sprint/standups');
  }));

  results.push(await runFlow('accountability_action_items', async () => {
    await assertOk(await agent.get('/api/accountability/action-items'), 'accountability/action-items');
  }));

  results.push(await runFlow('search_content', async () => {
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
