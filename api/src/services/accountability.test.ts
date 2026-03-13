import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { mockQueryResult, mockEmptyResult } from '../test-utils/mock-query-result.js';

// Mock pool before importing service
vi.mock('../db/client.js', () => ({
  pool: {
    query: vi.fn(),
  },
}));

// Mock business-days to control date behavior
vi.mock('../utils/business-days.js', async () => {
  const actual = await vi.importActual<typeof import('../utils/business-days.js')>('../utils/business-days.js');
  return {
    ...actual,
    isBusinessDay: vi.fn().mockReturnValue(true),
  };
});

// Mock getAllocations to avoid fragile query ordering
vi.mock('../utils/allocation.js', () => ({
  getAllocations: vi.fn().mockResolvedValue([]),
}));

import { pool } from '../db/client.js';
import { isBusinessDay } from '../utils/business-days.js';
import { getAllocations } from '../utils/allocation.js';
import { checkMissingAccountability } from './accountability.js';

describe('Accountability Service', () => {
  const userId = 'user-123';
  const workspaceId = 'workspace-456';
  const sprintId = 'sprint-789';
  const projectId = 'project-abc';
  const personId = 'person-doc-123';

  beforeEach(() => {
    vi.mocked(pool.query).mockReset();
    // Default fallback: return empty rows for any unmocked query calls
    // This prevents crashes when new accountability checks are added
    vi.mocked(pool.query).mockResolvedValue(mockEmptyResult());
    vi.mocked(isBusinessDay).mockReturnValue(true);
    vi.mocked(getAllocations).mockReset().mockResolvedValue([]);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  // Helper to mock the standard setup queries (workspace + person lookup)
  const mockSetupQueries = (sprintStartDate = '2024-01-01') => {
    return vi.mocked(pool.query)
      // 1. Workspace query
      .mockResolvedValueOnce(mockQueryResult([{ sprint_start_date: sprintStartDate }]))
      // 2. Person document lookup
      .mockResolvedValueOnce(mockQueryResult([{ id: personId }]));
  };

  /**
   * Helper to set up a minimal mock sequence for tests that don't care about
   * specific accountability types. After setup queries, the sequence is:
   * - standup active sprints (skipped if !isBusinessDay)
   * - owned sprints (sprint accountability)
   * - (getAllocations is mocked directly)
   * - past sprints without review
   * - completed projects without retro
   */
  const mockMinimalQueries = (sprintStartDate = '2024-01-01') => {
    vi.mocked(isBusinessDay).mockReturnValue(false); // skip standup checks
    return mockSetupQueries(sprintStartDate)
      // owned sprints
      .mockResolvedValueOnce(mockEmptyResult())
      // past sprints without review
      .mockResolvedValueOnce(mockEmptyResult())
      // completed projects without retro
      .mockResolvedValueOnce(mockEmptyResult())
      // changes_requested check
      .mockResolvedValueOnce(mockEmptyResult());
  };

  describe('checkMissingAccountability', () => {
    it('returns empty array when workspace not found', async () => {
      vi.mocked(pool.query).mockResolvedValueOnce(mockEmptyResult());

      const result = await checkMissingAccountability(userId, workspaceId);

      expect(result).toEqual([]);
    });

    it('returns only weekly_plan/weekly_retro/changes_requested types (standups, sprint, project checks disabled)', async () => {
      mockSetupQueries();

      const result = await checkMissingAccountability(userId, workspaceId);

      // Only weekly plan/retro and changes_requested checks are active
      const types = result.map((item) => item.type);
      expect(types).not.toContain('standup');
      expect(types).not.toContain('week_start');
      expect(types).not.toContain('week_issues');
      expect(types).not.toContain('project_retro');
    });
  });

  describe('date calculations', () => {
    it('handles workspace start date as Date object', async () => {
      const startDate = new Date('2024-01-01');
      vi.mocked(pool.query)
        .mockResolvedValueOnce(mockQueryResult([{ sprint_start_date: startDate }]))
        .mockResolvedValueOnce(mockQueryResult([{ id: personId }]))
        .mockResolvedValueOnce(mockEmptyResult())
        .mockResolvedValueOnce(mockEmptyResult())
        .mockResolvedValueOnce(mockEmptyResult())
        .mockResolvedValueOnce(mockEmptyResult());

      const result = await checkMissingAccountability(userId, workspaceId);
      expect(result).toBeDefined();
    });

    it('handles workspace start date as string', async () => {
      mockSetupQueries()
        .mockResolvedValueOnce(mockEmptyResult())
        .mockResolvedValueOnce(mockEmptyResult())
        .mockResolvedValueOnce(mockEmptyResult())
        .mockResolvedValueOnce(mockEmptyResult());

      const result = await checkMissingAccountability(userId, workspaceId);
      expect(result).toBeDefined();
    });
  });

  // ======================================================================
  // Scenario tests for plan/retro due windows and next-sprint lookahead
  // ======================================================================

  describe('per-person weekly plan due window (Saturday through Monday EOD)', () => {
    // Workspace sprint_start_date = 2024-01-01 (Monday)
    // Week 1: Jan 1-7, Week 2: Jan 8-14

    it('shows next sprint plan as due on Saturday before the week starts', async () => {
      // Saturday Jan 6 = last day of Week 1, but 2 days before Week 2 starts
      // Plan for Week 2 should be due (weekStart - 2 = Jan 8 - 2 = Jan 6)
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-06T12:00:00Z'));
      vi.mocked(isBusinessDay).mockReturnValue(false); // Saturday

      mockMinimalQueries();
      vi.mocked(getAllocations)
        .mockResolvedValueOnce([]) // current sprint (Week 1) - no allocations
        .mockResolvedValueOnce([{ projectId, projectName: 'Test Project' }]); // next sprint (Week 2)

      // Plan query for Week 2 - no plan exists
      vi.mocked(pool.query).mockResolvedValueOnce(mockEmptyResult());

      const result = await checkMissingAccountability(userId, workspaceId);

      const planItem = result.find((item) => item.type === 'weekly_plan' && item.weekNumber === 2);
      expect(planItem).toBeDefined();
      expect(planItem?.message).toContain('week 2 plan');
    });

    it('shows current sprint plan as due on Monday (the week has started)', async () => {
      // Monday Jan 8 = start of Week 2
      // Plan was due from Saturday Jan 6, still in yellow window until Tuesday
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-08T12:00:00Z'));

      mockMinimalQueries();
      vi.mocked(getAllocations)
        .mockResolvedValueOnce([{ projectId, projectName: 'Test Project' }]) // current (Week 2)
        .mockResolvedValueOnce([]); // next sprint (Week 3) - no allocations

      // Plan query for Week 2 - no plan exists
      vi.mocked(pool.query).mockResolvedValueOnce(mockEmptyResult());

      const result = await checkMissingAccountability(userId, workspaceId);

      const planItem = result.find((item) => item.type === 'weekly_plan' && item.weekNumber === 2);
      expect(planItem).toBeDefined();
    });

    it('does NOT show next sprint plan on Friday (too early)', async () => {
      // Friday Jan 5 = day 5 of Week 1
      // Week 2 plan due from Saturday Jan 6, so Friday is too early
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-05T12:00:00Z'));

      mockMinimalQueries();
      vi.mocked(getAllocations)
        .mockResolvedValueOnce([]) // current sprint (Week 1)
        .mockResolvedValueOnce([{ projectId, projectName: 'Test Project' }]); // next sprint (Week 2)

      const result = await checkMissingAccountability(userId, workspaceId);

      const planItem = result.find((item) => item.type === 'weekly_plan' && item.weekNumber === 2);
      expect(planItem).toBeUndefined();
    });

    it('shows plan as overdue on Tuesday (after Monday EOD)', async () => {
      // Tuesday Jan 9 = weekStart + 1 = overdue threshold
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-09T12:00:00Z'));

      mockMinimalQueries();
      vi.mocked(getAllocations)
        .mockResolvedValueOnce([{ projectId, projectName: 'Test Project' }]) // current (Week 2)
        .mockResolvedValueOnce([]); // next (Week 3)

      // Plan query for Week 2 - no plan exists
      vi.mocked(pool.query).mockResolvedValueOnce(mockEmptyResult());

      const result = await checkMissingAccountability(userId, workspaceId);

      const planItem = result.find((item) => item.type === 'weekly_plan' && item.weekNumber === 2);
      expect(planItem).toBeDefined();
      // Due date should reflect the overdue date (Tuesday = weekStart + 1)
      expect(planItem?.dueDate).toBe('2024-01-09');
    });
  });

  describe('per-person weekly retro due window (Thursday through Friday EOD)', () => {
    // Workspace sprint_start_date = 2024-01-01 (Monday)
    // Week 1: Jan 1-7

    it('shows retro as due on Thursday', async () => {
      // Thursday Jan 4 = weekStart + 3 = retro due threshold
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-04T12:00:00Z'));

      mockMinimalQueries();
      vi.mocked(getAllocations)
        .mockResolvedValueOnce([{ projectId, projectName: 'Test Project' }]) // current (Week 1)
        .mockResolvedValueOnce([]); // next (Week 2)

      // Plan query for Week 1 - plan exists (done)
      vi.mocked(pool.query)
        .mockResolvedValueOnce(mockQueryResult([{ id: 'plan-1', content: { type: 'doc', content: [{ type: 'text', text: 'My plan' }] } }]))
        // Retro query for Week 1 - no retro
        .mockResolvedValueOnce(mockEmptyResult());

      const result = await checkMissingAccountability(userId, workspaceId);

      const retroItem = result.find((item) => item.type === 'weekly_retro' && item.weekNumber === 1);
      expect(retroItem).toBeDefined();
      expect(retroItem?.message).toContain('retro');
    });

    it('does NOT show retro on Wednesday (too early)', async () => {
      // Wednesday Jan 3 = weekStart + 2 = before retro due threshold
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-03T12:00:00Z'));

      mockMinimalQueries();
      vi.mocked(getAllocations)
        .mockResolvedValueOnce([{ projectId, projectName: 'Test Project' }]) // current (Week 1)
        .mockResolvedValueOnce([]); // next (Week 2)

      // Plan query for Week 1 - plan exists
      vi.mocked(pool.query)
        .mockResolvedValueOnce(mockQueryResult([{ id: 'plan-1', content: { type: 'doc', content: [{ type: 'text', text: 'My plan' }] } }]));
      // Retro is NOT queried because today < retroDueStr

      const result = await checkMissingAccountability(userId, workspaceId);

      const retroItem = result.find((item) => item.type === 'weekly_retro');
      expect(retroItem).toBeUndefined();
    });

    it('shows retro as overdue on Saturday', async () => {
      // Saturday Jan 6 = weekStart + 5 = retro overdue threshold
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-06T12:00:00Z'));
      vi.mocked(isBusinessDay).mockReturnValue(false);

      mockMinimalQueries();
      vi.mocked(getAllocations)
        .mockResolvedValueOnce([{ projectId, projectName: 'Test Project' }]) // current (Week 1)
        .mockResolvedValueOnce([]); // next (Week 2)

      // Plan query - plan exists
      vi.mocked(pool.query)
        .mockResolvedValueOnce(mockQueryResult([{ id: 'plan-1', content: { type: 'doc', content: [{ type: 'text', text: 'My plan' }] } }]))
        // Retro query - no retro
        .mockResolvedValueOnce(mockEmptyResult());

      const result = await checkMissingAccountability(userId, workspaceId);

      const retroItem = result.find((item) => item.type === 'weekly_retro' && item.weekNumber === 1);
      expect(retroItem).toBeDefined();
      // Due date should reflect Friday (weekStart + 4), the end of the due window
      expect(retroItem?.dueDate).toBe('2024-01-05');
    });
  });

  describe('next-sprint lookahead', () => {
    it('checks both current AND next sprint for accountability', async () => {
      // Sunday Jan 7 = last day of Week 1
      // Next sprint (Week 2) plan due from Jan 6 (Saturday)
      // Today (Jan 7) is in the due window for Week 2's plan
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-07T12:00:00Z'));
      vi.mocked(isBusinessDay).mockReturnValue(false);

      // getAllocations is called twice: once for current sprint, once for next
      vi.mocked(getAllocations)
        .mockResolvedValueOnce([{ projectId, projectName: 'Current Project' }])  // Week 1
        .mockResolvedValueOnce([{ projectId: 'proj-2', projectName: 'Next Project' }]); // Week 2

      // Mock queries in execution order:
      // 1. workspace, 2. person,
      // 3. owned sprints (sprint accountability), 4-5. Week 1 plan+retro queries,
      // 6. Week 2 plan query, 7. changes_requested check
      // (standup skipped because isBusinessDay=false)
      mockSetupQueries()
        // owned sprints (sprint accountability) - no sprints owned
        .mockResolvedValueOnce(mockEmptyResult())
        // Week 1 plan - exists (done)
        .mockResolvedValueOnce(mockQueryResult([{ id: 'plan-1', content: { type: 'doc', content: [{ type: 'text', text: 'done' }] } }]))
        // Week 1 retro - exists (done) (today Jan 7 >= retroDueStr Jan 4)
        .mockResolvedValueOnce(mockQueryResult([{ id: 'retro-1', content: { type: 'doc', content: [{ type: 'text', text: 'done' }] } }]))
        // Week 2 plan - NOT exists
        .mockResolvedValueOnce(mockEmptyResult())
        // changes_requested check
        .mockResolvedValueOnce(mockEmptyResult());

      const result = await checkMissingAccountability(userId, workspaceId);

      // Current sprint (Week 1) items should NOT appear (plan and retro are done)
      const week1Items = result.filter((item) => item.weekNumber === 1 && (item.type === 'weekly_plan' || item.type === 'weekly_retro'));
      expect(week1Items).toHaveLength(0);

      // Next sprint (Week 2) plan should appear
      const week2Plan = result.find((item) => item.type === 'weekly_plan' && item.weekNumber === 2);
      expect(week2Plan).toBeDefined();
      expect(week2Plan?.message).toContain('week 2 plan');
      expect(week2Plan?.projectId).toBe('proj-2');
    });

    it('does not duplicate items when plan is due for both current and next sprint', async () => {
      // Tuesday Jan 9 = day 2 of Week 2
      // Week 2 plan is overdue, Week 3 plan is not yet due (Jan 13 is due start)
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-09T12:00:00Z'));

      mockMinimalQueries();

      vi.mocked(getAllocations)
        .mockResolvedValueOnce([{ projectId, projectName: 'Test Project' }])  // Week 2
        .mockResolvedValueOnce([{ projectId, projectName: 'Test Project' }]); // Week 3

      // Week 2 plan - NOT exists
      vi.mocked(pool.query)
        .mockResolvedValueOnce(mockEmptyResult());
      // Week 3 plan is not checked because today < planDueStr for Week 3

      const result = await checkMissingAccountability(userId, workspaceId);

      const planItems = result.filter((item) => item.type === 'weekly_plan');
      // Only Week 2 plan should appear, not Week 3
      expect(planItems).toHaveLength(1);
      expect(planItems[0]?.weekNumber).toBe(2);
    });
  });

  describe('batched query behavior', () => {
    it('batches standup status lookups across active sprints', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-08T12:00:00Z'));

      mockSetupQueries()
        // active sprints for standups
        .mockResolvedValueOnce(mockQueryResult([
          { id: 'sprint-1', title: 'Week 2 Alpha', properties: { sprint_number: 2 }, issue_count: '2' },
          { id: 'sprint-2', title: 'Week 2 Beta', properties: { sprint_number: 2 }, issue_count: '1' },
        ]))
        // grouped standup status query
        .mockResolvedValueOnce(mockQueryResult([
          { sprint_id: 'sprint-1', has_standup_today: false, last_standup_date: '2024-01-06' },
          { sprint_id: 'sprint-2', has_standup_today: true, last_standup_date: '2024-01-08' },
        ]))
        // owned sprints
        .mockResolvedValueOnce(mockEmptyResult())
        // changes_requested check
        .mockResolvedValueOnce(mockEmptyResult());

      const result = await checkMissingAccountability(userId, workspaceId);

      expect(result.filter((item) => item.type === 'standup')).toHaveLength(1);
      const standupSqlCalls = vi.mocked(pool.query).mock.calls.filter(([sql]) =>
        typeof sql === 'string' && sql.includes('BOOL_OR(created_at >= $3::date')
      );
      expect(standupSqlCalls).toHaveLength(1);
    });

    it('batches sprint issue counts across owned sprints', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-15T12:00:00Z'));
      vi.mocked(isBusinessDay).mockReturnValue(false);

      mockSetupQueries()
        // owned sprints
        .mockResolvedValueOnce(mockQueryResult([
          { id: 'sprint-1', title: 'Week 1', properties: { sprint_number: 1, status: 'planned' }, project_id: null },
          { id: 'sprint-2', title: 'Week 2', properties: { sprint_number: 2, status: 'active' }, project_id: null },
        ]))
        // grouped issue counts
        .mockResolvedValueOnce(mockQueryResult([{ sprint_id: 'sprint-2', issue_count: '2' }]))
        // changes_requested check
        .mockResolvedValueOnce(mockEmptyResult());

      const result = await checkMissingAccountability(userId, workspaceId);

      expect(result).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ type: 'week_start', targetId: 'sprint-1' }),
          expect.objectContaining({ type: 'week_issues', targetId: 'sprint-1' }),
        ])
      );
      expect(result.some((item) => item.type === 'week_issues' && item.targetId === 'sprint-2')).toBe(false);

      const issueCountSqlCalls = vi.mocked(pool.query).mock.calls.filter(([sql]) =>
        typeof sql === 'string' && sql.includes('GROUP BY da.related_id')
      );
      expect(issueCountSqlCalls).toHaveLength(1);
    });

    it('reuses weekly plan and retro lookups across multiple allocations in the same sprint', async () => {
      vi.useFakeTimers();
      vi.setSystemTime(new Date('2024-01-04T12:00:00Z'));
      vi.mocked(isBusinessDay).mockReturnValue(false);

      mockSetupQueries()
        // owned sprints
        .mockResolvedValueOnce(mockEmptyResult())
        // current sprint weekly_plan lookup
        .mockResolvedValueOnce(mockEmptyResult())
        // current sprint weekly_retro lookup
        .mockResolvedValueOnce(mockEmptyResult())
        // changes_requested check
        .mockResolvedValueOnce(mockEmptyResult());

      vi.mocked(getAllocations)
        .mockResolvedValueOnce([
          { projectId: 'project-1', projectName: 'Alpha' },
          { projectId: 'project-2', projectName: 'Beta' },
        ])
        .mockResolvedValueOnce([]);

      const result = await checkMissingAccountability(userId, workspaceId);

      expect(result.filter((item) => item.type === 'weekly_plan')).toHaveLength(2);
      expect(result.filter((item) => item.type === 'weekly_retro')).toHaveLength(2);

      const planQueryCalls = vi.mocked(pool.query).mock.calls.filter(([sql]) =>
        typeof sql === 'string' && sql.includes("document_type = 'weekly_plan'")
      );
      const retroQueryCalls = vi.mocked(pool.query).mock.calls.filter(([sql]) =>
        typeof sql === 'string' && sql.includes("document_type = 'weekly_retro'")
      );

      expect(planQueryCalls).toHaveLength(1);
      expect(retroQueryCalls).toHaveLength(1);
    });
  });
});
