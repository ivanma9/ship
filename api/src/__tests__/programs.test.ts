import { describe, it, expect, beforeEach, vi } from 'vitest';
import request from 'supertest';
import express from 'express';

vi.mock('../db/client.js', () => ({
  pool: { query: vi.fn() },
}));

vi.mock('../middleware/auth.js', () => ({
  authMiddleware: (req: import('express').Request, _res: import('express').Response, next: import('express').NextFunction) => {
    (req as any).workspaceId = 'ws-aaa';
    (req as any).userId = 'user-1';
    next();
  },
}));

vi.mock('../middleware/visibility.js', () => ({
  getVisibilityContext: vi.fn().mockResolvedValue({ isAdmin: false }),
  VISIBILITY_FILTER_SQL: () => 'TRUE',
}));

vi.mock('../services/audit.js', () => ({
  logAuditEvent: vi.fn().mockResolvedValue(undefined),
}));

import programsRouter from '../routes/programs.js';
import { pool } from '../db/client.js';
import { mockQueryResult } from '../test-utils/mock-query-result.js';

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/programs', programsRouter);
  return app;
}

const BASE_ROW = {
  id: 'prog-1',
  title: 'Alpha Program',
  properties: { color: '#6366f1' },
  archived_at: null,
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString(),
  owner_id: null,
  owner_name: null,
  owner_email: null,
};

describe('Programs API — count correctness', () => {
  let app: ReturnType<typeof createApp>;

  beforeEach(() => {
    vi.clearAllMocks();
    app = createApp();
  });

  describe('GET /programs — issue_count and sprint_count', () => {
    it('returns correct non-zero counts from the query row', async () => {
      vi.mocked(pool.query).mockResolvedValueOnce(
        mockQueryResult([{ ...BASE_ROW, issue_count: '7', sprint_count: '3' }])
      );

      const res = await request(app).get('/programs').expect(200);

      expect(res.body[0].issue_count).toBe('7');
      expect(res.body[0].sprint_count).toBe('3');
    });

    it('returns 0 (not null) when program has no issues or sprints', async () => {
      vi.mocked(pool.query).mockResolvedValueOnce(
        mockQueryResult([{ ...BASE_ROW, issue_count: '0', sprint_count: '0' }])
      );

      const res = await request(app).get('/programs').expect(200);

      expect(res.body[0].issue_count).toBe('0');
      expect(res.body[0].sprint_count).toBe('0');
    });
  });

  describe('GET /programs/:id — issue_count and sprint_count', () => {
    it('returns correct counts for a single program', async () => {
      vi.mocked(pool.query).mockResolvedValueOnce(
        mockQueryResult([{ ...BASE_ROW, id: 'prog-1', issue_count: '12', sprint_count: '2' }])
      );

      const res = await request(app).get('/programs/prog-1').expect(200);

      expect(res.body.issue_count).toBe('12');
      expect(res.body.sprint_count).toBe('2');
    });

    it('returns 0 counts when program has no associations', async () => {
      vi.mocked(pool.query).mockResolvedValueOnce(
        mockQueryResult([{ ...BASE_ROW, id: 'prog-1', issue_count: '0', sprint_count: '0' }])
      );

      const res = await request(app).get('/programs/prog-1').expect(200);

      expect(res.body.issue_count).toBe('0');
      expect(res.body.sprint_count).toBe('0');
    });
  });

  describe('Workspace isolation — derived tables include workspace_id filter', () => {
    it('list route passes workspace_id as a parameter to pool.query', async () => {
      vi.mocked(pool.query).mockResolvedValueOnce(mockQueryResult([]));

      await request(app).get('/programs').expect(200);

      const [sql, params] = vi.mocked(pool.query).mock.calls[0] as unknown as [string, unknown[]];

      // workspace_id ($1) must appear as a param
      expect(params[0]).toBe('ws-aaa');
      // The SQL must reference $1 inside the derived tables (not just the outer WHERE)
      // Both ISSUE_COUNT_JOIN and SPRINT_COUNT_JOIN use the workspaceParam placeholder
      const workspaceRefs = (sql.match(/workspace_id\s*=\s*\$1/g) || []).length;
      expect(workspaceRefs).toBeGreaterThanOrEqual(2); // one per derived table
    });

    it('detail route passes workspace_id as the second parameter', async () => {
      vi.mocked(pool.query).mockResolvedValueOnce(
        mockQueryResult([{ ...BASE_ROW, issue_count: '0', sprint_count: '0' }])
      );

      await request(app).get('/programs/prog-1').expect(200);

      const [sql, params] = vi.mocked(pool.query).mock.calls[0] as unknown as [string, unknown[]];

      // params: [id, workspaceId, userId, isAdmin]
      expect(params[1]).toBe('ws-aaa');
      // Both derived tables reference $2 for workspace isolation
      const workspaceRefs = (sql.match(/workspace_id\s*=\s*\$2/g) || []).length;
      expect(workspaceRefs).toBeGreaterThanOrEqual(2);
    });
  });
});
