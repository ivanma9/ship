import { describe, it, expect, beforeEach, vi } from 'vitest';

vi.mock('../db/client.js', () => ({
  pool: {
    query: vi.fn(),
  },
}));

vi.mock('../middleware/auth.js', () => ({
  authMiddleware: vi.fn((req, _res, next) => {
    req.userId = 'user-123';
    req.workspaceId = 'ws-123';
    next();
  }),
}));

import express from 'express';
import request from 'supertest';
import { pool } from '../db/client.js';
import dashboardRouter from './dashboard.js';

describe('Dashboard API', () => {
  let app: express.Express;

  beforeEach(() => {
    vi.mocked(pool.query).mockReset();
    app = express();
    app.use(express.json());
    app.use('/api/dashboard', dashboardRouter);
  });

  it('includes paragraph-based weekly retro content in /api/dashboard/my-week', async () => {
    vi.mocked(pool.query)
      // Person lookup
      .mockResolvedValueOnce({ rows: [{ id: 'person-123', title: 'Test Person' }] } as any)
      // Workspace sprint config
      .mockResolvedValueOnce({ rows: [{ sprint_start_date: '2026-01-01' }] } as any)
      // Merged plan+retro query (plan, retro, and previous retro combined)
      .mockResolvedValueOnce({
        rows: [{
          id: 'retro-123',
          title: 'Week 13 Retro',
          document_type: 'weekly_retro',
          week_number: 13,
          properties: { submitted_at: null },
          content: {
            type: 'doc',
            content: [
              {
                type: 'heading',
                attrs: { level: 2 },
                content: [{ type: 'text', text: 'What I delivered this week' }],
              },
              {
                type: 'planReference',
                attrs: {
                  planItemText: 'Ship the dashboard',
                  planDocumentId: 'plan-123',
                  itemIndex: 0,
                },
              },
              {
                type: 'paragraph',
                content: [{ type: 'text', text: 'Completed the API refactoring' }],
              },
              {
                type: 'heading',
                attrs: { level: 2 },
                content: [{ type: 'text', text: 'Unplanned work' }],
              },
              {
                type: 'bulletList',
                content: [
                  {
                    type: 'listItem',
                    content: [
                      {
                        type: 'paragraph',
                        content: [{ type: 'text', text: 'Helped support debug prod issue' }],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        }],
      } as any)
      // Standups query
      .mockResolvedValueOnce({ rows: [] } as any)
      // Allocations query
      .mockResolvedValueOnce({ rows: [] } as any);

    const res = await request(app).get('/api/dashboard/my-week?week_number=13');

    expect(res.status).toBe(200);
    expect(res.body.retro).toBeTruthy();
    expect(res.body.retro.items).toEqual([
      { text: 'Completed the API refactoring', checked: false },
      { text: 'Helped support debug prod issue', checked: false },
    ]);
  });
});
