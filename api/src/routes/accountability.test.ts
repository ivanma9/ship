import { describe, it, expect, beforeAll, afterAll, beforeEach, vi } from 'vitest';
import request from 'supertest';
import crypto from 'crypto';

vi.mock('../services/accountability.js', () => ({
  checkMissingAccountability: vi.fn(),
}));

import { createApp } from '../app.js';
import { pool } from '../db/client.js';
import { checkMissingAccountability } from '../services/accountability.js';

describe('Accountability Routes', () => {
  const app = createApp('http://localhost:5173');
  const testRunId = Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
  const testEmail = `accountability-${testRunId}@ship.local`;
  const testWorkspaceName = `Accountability Test ${testRunId}`;

  let sessionCookie: string;
  let testWorkspaceId: string;
  let testUserId: string;

  beforeAll(async () => {
    const workspaceResult = await pool.query(
      `INSERT INTO workspaces (name) VALUES ($1) RETURNING id`,
      [testWorkspaceName]
    );
    testWorkspaceId = workspaceResult.rows[0].id;

    const userResult = await pool.query(
      `INSERT INTO users (email, password_hash, name)
       VALUES ($1, 'test-hash', 'Accountability Test User')
       RETURNING id`,
      [testEmail]
    );
    testUserId = userResult.rows[0].id;

    await pool.query(
      `INSERT INTO workspace_memberships (workspace_id, user_id, role)
       VALUES ($1, $2, 'member')`,
      [testWorkspaceId, testUserId]
    );

    const sessionId = crypto.randomBytes(32).toString('hex');
    await pool.query(
      `INSERT INTO sessions (id, user_id, workspace_id, expires_at)
       VALUES ($1, $2, $3, now() + interval '1 hour')`,
      [sessionId, testUserId, testWorkspaceId]
    );
    sessionCookie = `session_id=${sessionId}`;
  });

  afterAll(async () => {
    await pool.query('DELETE FROM sessions WHERE user_id = $1', [testUserId]);
    await pool.query('DELETE FROM workspace_memberships WHERE user_id = $1', [testUserId]);
    await pool.query('DELETE FROM users WHERE id = $1', [testUserId]);
    await pool.query('DELETE FROM workspaces WHERE id = $1', [testWorkspaceId]);
  });

  beforeEach(() => {
    vi.mocked(checkMissingAccountability).mockReset();
  });

  it('GET /api/accountability/action-items returns 401 without auth', async () => {
    const res = await request(app).get('/api/accountability/action-items');

    expect(res.status).toBe(401);
  });

  it('GET /api/accountability/action-items preserves response shape and urgency ordering', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2024-01-08T12:00:00Z'));

    vi.mocked(checkMissingAccountability).mockResolvedValue([
      {
        type: 'weekly_plan',
        targetId: '00000000-0000-0000-0000-000000000001',
        targetTitle: 'Week 2 Plan',
        targetType: 'project',
        dueDate: '2024-01-08',
        message: 'Write week 2 plan',
        personId: 'person-1',
        projectId: 'project-1',
        weekNumber: 2,
      },
      {
        type: 'standup',
        targetId: '00000000-0000-0000-0000-000000000002',
        targetTitle: 'Week 2',
        targetType: 'sprint',
        dueDate: '2024-01-06',
        message: 'Post standup',
      },
      {
        type: 'changes_requested_plan',
        targetId: '00000000-0000-0000-0000-000000000003',
        targetTitle: 'Week 2 Plan',
        targetType: 'sprint',
        dueDate: null,
        message: 'Changes requested on your Week 2 plan',
        personId: 'person-1',
        projectId: 'project-1',
        weekNumber: 2,
      },
    ] as any);

    const res = await request(app)
      .get('/api/accountability/action-items')
      .set('Cookie', sessionCookie);

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      total: 3,
      has_overdue: true,
      has_due_today: true,
    });
    expect(res.body.items.map((item: { accountability_type: string }) => item.accountability_type)).toEqual([
      'standup',
      'weekly_plan',
      'changes_requested_plan',
    ]);
    expect(res.body.items[0]).toMatchObject({
      id: 'standup-00000000-0000-0000-0000-000000000002',
      title: 'Post standup',
      accountability_type: 'standup',
      accountability_target_id: '00000000-0000-0000-0000-000000000002',
      target_title: 'Week 2',
      due_date: '2024-01-06',
      days_overdue: 2,
      is_system_generated: true,
    });
    expect(res.body.items[1]).toMatchObject({
      accountability_type: 'weekly_plan',
      due_date: '2024-01-08',
      days_overdue: 0,
      person_id: 'person-1',
      project_id: 'project-1',
      week_number: 2,
    });
    expect(res.body.items[2]).toMatchObject({
      accountability_type: 'changes_requested_plan',
      due_date: null,
      days_overdue: 0,
    });

    vi.useRealTimers();
  });
});
