import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest';
import express from 'express';
import request from 'supertest';

vi.mock('../db/client.js', () => ({
  pool: {
    query: vi.fn(),
  },
}));

vi.mock('../middleware/auth.js', () => ({
  authMiddleware: vi.fn((req, _res, next) => {
    req.userId = '11111111-1111-1111-1111-111111111111';
    req.workspaceId = 'ws-123';
    next();
  }),
}));

vi.mock('../middleware/visibility.js', () => ({
  getVisibilityContext: vi.fn().mockResolvedValue({ isAdmin: false }),
  VISIBILITY_FILTER_SQL: vi.fn(() => 'TRUE'),
}));

import { pool } from '../db/client.js';
import dashboardRouter from './dashboard.js';

describe('Dashboard API coverage', () => {
  let app: express.Express;

  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-03-12T12:00:00Z'));
    vi.mocked(pool.query).mockReset();

    app = express();
    app.use(express.json());
    app.use('/api/dashboard', dashboardRouter);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('groups /my-work items by urgency and computes current sprint metadata', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [{ sprint_start_date: '2026-03-02' }] } as never)
      .mockResolvedValueOnce({
        rows: [
          {
            id: 'issue-overdue',
            title: 'Past week issue',
            properties: { state: 'in_progress', priority: 'high' },
            ticket_number: 42,
            sprint_id: 'sprint-1',
            sprint_name: 'Week 1',
            sprint_number: 1,
            program_name: 'Atlas',
          },
          {
            id: 'issue-current',
            title: 'Current week issue',
            properties: { state: 'todo', priority: 'urgent' },
            ticket_number: 43,
            sprint_id: 'sprint-2',
            sprint_name: 'Week 2',
            sprint_number: 2,
            program_name: 'Atlas',
          },
          {
            id: 'issue-backlog',
            title: 'Backlog issue',
            properties: { state: 'backlog', priority: 'low' },
            ticket_number: 44,
            sprint_id: null,
            sprint_name: null,
            sprint_number: null,
            program_name: 'Atlas',
          },
        ],
      } as never)
      .mockResolvedValueOnce({
        rows: [
          {
            id: 'project-active',
            title: 'Modernize dashboard',
            properties: { impact: 10, confidence: 8, ease: 5 },
            inferred_status: 'active',
            program_name: 'Atlas',
          },
          {
            id: 'project-backlog',
            title: 'Future backlog project',
            properties: { impact: 4, confidence: 5, ease: 6 },
            inferred_status: 'backlog',
            program_name: 'Atlas',
          },
        ],
      } as never)
      .mockResolvedValueOnce({
        rows: [
          {
            id: 'sprint-2',
            title: 'Atlas Week 2',
            properties: { sprint_number: 2 },
            sprint_number: 2,
            program_name: 'Atlas',
          },
        ],
      } as never);

    const res = await request(app).get('/api/dashboard/my-work');

    expect(res.status).toBe(200);
    expect(res.body.current_sprint_number).toBe(2);
    expect(res.body.days_remaining).toBe(4);
    expect(res.body.grouped.overdue.map((item: { id: string }) => item.id)).toEqual(['issue-overdue']);
    expect(res.body.grouped.this_sprint.map((item: { id: string }) => item.id)).toEqual([
      'issue-current',
      'project-active',
      'sprint-2',
    ]);
    expect(res.body.grouped.later.map((item: { id: string }) => item.id)).toEqual([
      'issue-backlog',
      'project-backlog',
    ]);
    expect(res.body.items).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: 'project-active',
          type: 'project',
          ice_score: 400,
          urgency: 'this_sprint',
        }),
        expect.objectContaining({
          id: 'sprint-2',
          type: 'sprint',
          days_remaining: 4,
        }),
      ])
    );
  });

  it('assembles /my-focus project context with parsed plans and recent activity', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [{ id: 'person-1', title: 'Taylor' }] } as never)
      .mockResolvedValueOnce({ rows: [{ sprint_start_date: '2026-03-02' }] } as never)
      .mockResolvedValueOnce({
        rows: [
          {
            project_id: 'project-1',
            project_title: 'Ship dashboard',
            program_name: 'Atlas',
          },
        ],
      } as never)
      .mockResolvedValueOnce({
        rows: [
          {
            id: 'plan-current',
            properties: { project_id: 'project-1', week_number: 2 },
            content: {
              type: 'doc',
              content: [
                {
                  type: 'taskItem',
                  attrs: { checked: true },
                  content: [{ type: 'text', text: 'Ship API coverage batch' }],
                },
                {
                  type: 'paragraph',
                  content: [{ type: 'text', text: 'Coordinate dashboard rollout' }],
                },
              ],
            },
          },
          {
            id: 'plan-previous',
            properties: { project_id: 'project-1', week_number: 1 },
            content: {
              type: 'doc',
              content: [
                {
                  type: 'listItem',
                  content: [{ type: 'text', text: 'Close retro actions' }],
                },
              ],
            },
          },
        ],
      } as never)
      .mockResolvedValueOnce({
        rows: [
          {
            id: 'issue-1',
            title: 'Fix week banner',
            ticket_number: 19,
            state: 'in_progress',
            updated_at: '2026-03-11T09:00:00Z',
            project_id: 'project-1',
          },
        ],
      } as never);

    const res = await request(app).get('/api/dashboard/my-focus');

    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({
      person_id: 'person-1',
      current_week_number: 2,
      week_start: '2026-03-09',
      week_end: '2026-03-15',
    });
    expect(res.body.projects).toEqual([
      {
        id: 'project-1',
        title: 'Ship dashboard',
        program_name: 'Atlas',
        plan: {
          id: 'plan-current',
          week_number: 2,
          items: [
            { text: 'Ship API coverage batch', checked: true },
            { text: 'Coordinate dashboard rollout', checked: false },
          ],
        },
        previous_plan: {
          id: 'plan-previous',
          week_number: 1,
          items: [{ text: 'Close retro actions', checked: false }],
        },
        recent_activity: [
          {
            id: 'issue-1',
            title: 'Fix week banner',
            ticket_number: 19,
            state: 'in_progress',
            updated_at: '2026-03-11T09:00:00Z',
          },
        ],
      },
    ]);
  });

  it('maps /my-week standups into seven day slots and respects requested week navigation', async () => {
    vi.mocked(pool.query)
      .mockResolvedValueOnce({ rows: [{ id: 'person-1', title: 'Taylor' }] } as never)
      .mockResolvedValueOnce({ rows: [{ sprint_start_date: '2026-03-02' }] } as never)
      .mockResolvedValueOnce({
        rows: [
          {
            id: 'plan-3',
            title: 'Week 3 plan',
            properties: { submitted_at: '2026-03-16T10:00:00Z' },
            content: {
              type: 'doc',
              content: [
                {
                  type: 'taskItem',
                  attrs: { checked: false },
                  content: [{ type: 'text', text: 'Write the weekly plan' }],
                },
              ],
            },
          },
        ],
      } as never)
      .mockResolvedValueOnce({ rows: [] } as never)
      .mockResolvedValueOnce({
        rows: [
          {
            id: 'retro-2',
            title: 'Week 2 retro',
            properties: { submitted_at: null },
          },
        ],
      } as never)
      .mockResolvedValueOnce({
        rows: [
          {
            id: 'standup-1',
            title: 'Monday update',
            properties: { date: '2026-03-16' },
            created_at: '2026-03-16T13:00:00Z',
          },
          {
            id: 'standup-2',
            title: 'Wednesday update',
            properties: { date: '2026-03-18' },
            created_at: '2026-03-18T13:00:00Z',
          },
        ],
      } as never)
      .mockResolvedValueOnce({
        rows: [
          {
            project_id: 'project-1',
            project_title: 'Ship dashboard',
            program_name: 'Atlas',
          },
        ],
      } as never);

    const res = await request(app).get('/api/dashboard/my-week?week_number=3');

    expect(res.status).toBe(200);
    expect(res.body.week).toEqual({
      week_number: 3,
      current_week_number: 2,
      start_date: '2026-03-16',
      end_date: '2026-03-22',
      is_current: false,
    });
    expect(res.body.plan).toEqual({
      id: 'plan-3',
      title: 'Week 3 plan',
      submitted_at: '2026-03-16T10:00:00Z',
      items: [{ text: 'Write the weekly plan', checked: false }],
    });
    expect(res.body.previous_retro).toEqual({
      id: 'retro-2',
      title: 'Week 2 retro',
      submitted_at: null,
      week_number: 2,
    });
    expect(res.body.projects).toEqual([
      { id: 'project-1', title: 'Ship dashboard', program_name: 'Atlas' },
    ]);
    expect(res.body.standups).toHaveLength(7);
    expect(res.body.standups[0]).toEqual({
      date: '2026-03-16',
      day: 'Monday',
      standup: {
        id: 'standup-1',
        title: 'Monday update',
        date: '2026-03-16',
        created_at: '2026-03-16T13:00:00Z',
      },
    });
    expect(res.body.standups[1]).toEqual({
      date: '2026-03-17',
      day: 'Tuesday',
      standup: null,
    });
    expect(res.body.standups[2].standup.id).toBe('standup-2');
  });
});
