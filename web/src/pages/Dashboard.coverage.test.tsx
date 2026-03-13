import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { act, render, screen } from '@testing-library/react';
import { DashboardPage } from './Dashboard';
import type { ActionItemsResponse } from '@/hooks/useDashboardActionItems';
import type { ActionItem } from '@/hooks/useDashboardActionItems';
import type { ActiveWeeksResponse, ActiveWeek } from '@/hooks/useWeeksQuery';
import type { Project } from '@/contexts/ProjectsContext';

function createActiveWeeksResponse(overrides: Partial<ActiveWeeksResponse> = {}): ActiveWeeksResponse {
  return {
    weeks: [],
    current_sprint_number: 11,
    days_remaining: 5,
    sprint_start_date: '2026-03-10',
    sprint_end_date: '2026-03-16',
    ...overrides,
  };
}

function createActionItem(overrides: Partial<ActionItem> = {}): ActionItem {
  return {
    id: 'action-default',
    type: 'plan',
    sprint_id: 'week-default',
    sprint_title: 'Week 11',
    program_id: 'program-default',
    program_name: 'Default Program',
    sprint_number: 11,
    urgency: 'due_today',
    days_until_due: 0,
    message: 'Due today',
    ...overrides,
  };
}

const weeksState = vi.hoisted(() => ({
  data: createActiveWeeksResponse(),
  isLoading: false,
}));

const projectsState = vi.hoisted(() => ({
  projects: [] as Project[],
  loading: false,
}));

const actionItemsState = vi.hoisted(() => ({
  data: { action_items: [] } as ActionItemsResponse,
  isLoading: false,
}));

vi.mock('@/hooks/useWeeksQuery', () => ({
  useActiveWeeksQuery: () => weeksState,
}));

vi.mock('@/contexts/ProjectsContext', () => ({
  useProjects: () => projectsState,
}));

vi.mock('@/hooks/useDashboardActionItems', () => ({
  useDashboardActionItems: () => actionItemsState,
}));

vi.mock('@/components/dashboard/DashboardVariantC', () => ({
  DashboardVariantC: () => <div data-testid="dashboard-variant-c">Variant C</div>,
}));

function renderPage(initialEntry = '/dashboard?view=overview') {
  return render(
    <MemoryRouter initialEntries={[initialEntry]}>
      <Routes>
        <Route path="/dashboard" element={<DashboardPage />} />
      </Routes>
    </MemoryRouter>
  );
}

function createProject(overrides: Partial<Project> = {}): Project {
  return {
    id: 'project-default',
    title: 'Default Project',
    impact: null,
    confidence: null,
    ease: null,
    ice_score: null,
    color: '#005ea2',
    emoji: null,
    program_id: null,
    owner: null,
    sprint_count: 0,
    issue_count: 0,
    inferred_status: 'backlog' as const,
    archived_at: null,
    created_at: '2026-03-01T00:00:00Z',
    updated_at: '2026-03-01T00:00:00Z',
    is_complete: null,
    missing_fields: [],
    ...overrides,
  };
}

function createWeek(overrides: Partial<ActiveWeek> = {}): ActiveWeek {
  return {
    id: 'week-default',
    name: 'Default Week',
    sprint_number: 11,
    status: 'active',
    owner: null,
    issue_count: 0,
    completed_count: 0,
    started_count: 0,
    total_estimate_hours: 0,
    program_id: 'program-default',
    program_name: 'Default Program',
    days_remaining: 5,
    ...overrides,
  };
}

describe('DashboardPage coverage', () => {
  const fetchMock = vi.fn();

  beforeEach(() => {
    weeksState.data = createActiveWeeksResponse();
    weeksState.isLoading = false;
    projectsState.projects = [];
    projectsState.loading = false;
    actionItemsState.data = { action_items: [] };
    actionItemsState.isLoading = false;

    fetchMock.mockReset();
    vi.stubGlobal('fetch', fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('renders the loading state while dashboard queries are pending', () => {
    weeksState.isLoading = true;

    renderPage();

    expect(screen.getByText('Loading dashboard...')).toBeInTheDocument();
  });

  it('shows the my-work variant when selected', () => {
    renderPage('/dashboard?view=my-work');

    expect(screen.getByRole('heading', { name: 'My Work' })).toBeInTheDocument();
    expect(screen.getByText('What you need to do right now')).toBeInTheDocument();
    expect(screen.getByTestId('dashboard-variant-c')).toBeInTheDocument();
  });

  it('renders overview metrics, overdue banner, and sorted standups from active weeks', async () => {
    weeksState.data = createActiveWeeksResponse({
      weeks: [
        createWeek({
          id: 'week-1',
          name: 'Atlas Week 11',
          owner: { id: 'owner-1', name: 'Taylor', email: 'taylor@example.com' },
          issue_count: 6,
          completed_count: 3,
          started_count: 2,
          program_id: 'program-1',
          program_name: 'Atlas',
          days_remaining: 3,
        }),
        createWeek({
          id: 'week-2',
          name: 'Beacon Week 11',
          program_id: 'program-2',
          program_name: 'Beacon',
          days_remaining: 3,
        }),
      ],
      days_remaining: 3,
    });
    projectsState.projects = [
      createProject({
        id: 'project-1',
        title: 'Atlas Dashboard',
        owner: { id: 'owner-1', name: 'Taylor', email: 'taylor@example.com' },
        ice_score: 150,
        color: '#005ea2',
        emoji: 'A',
      }),
      createProject({
        id: 'project-2',
        title: 'Archived Project',
        archived_at: '2026-03-01T00:00:00Z',
        ice_score: 500,
        color: '#162e51',
        emoji: 'Z',
      }),
      createProject({
        id: 'project-3',
        title: 'Beacon Alerts',
        ice_score: 90,
        color: '#0050d8',
        emoji: null,
      }),
    ];
    actionItemsState.data = {
      action_items: [
        createActionItem({
          id: 'retro-overdue',
          urgency: 'overdue',
          sprint_id: 'week-1',
          sprint_number: 11,
          type: 'retro',
          program_name: 'Atlas',
        }),
        createActionItem({
          id: 'plan-overdue',
          urgency: 'overdue',
          sprint_id: 'week-2',
          sprint_number: 11,
          type: 'plan',
          program_name: 'Beacon',
        }),
      ],
    };
    fetchMock
      .mockResolvedValueOnce({
        ok: true,
        json: async () => [
          {
            id: 'standup-1',
            sprint_id: 'week-1',
            title: 'Atlas update',
            content: { type: 'doc', content: [{ type: 'paragraph', content: [{ text: 'Shipped API coverage' }] }] },
            author_id: 'user-1',
            author_name: null,
            author_email: null,
            created_at: '2026-03-11T09:00:00Z',
            updated_at: '2026-03-11T09:00:00Z',
          },
        ],
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => [
          {
            id: 'standup-2',
            sprint_id: 'week-2',
            title: 'Beacon update',
            content: { type: 'doc', content: [{ type: 'paragraph', content: [{ text: 'Handled support work' }] }] },
            author_id: 'user-2',
            author_name: 'Jordan',
            author_email: 'jordan@example.com',
            created_at: '2026-03-12T09:00:00Z',
            updated_at: '2026-03-12T09:00:00Z',
          },
        ],
      } as Response);

    await act(async () => {
      renderPage();
    });

    expect(screen.getByText(/2 overdue weekly documents need your attention/i)).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /Atlas Week 11 \(retro\)/i })).toHaveAttribute('href', '/documents/week-1');
    expect(screen.getAllByText('2').length).toBeGreaterThanOrEqual(2);
    expect(screen.getByText('3 remaining')).toBeInTheDocument();
    expect(screen.getByText('Atlas Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Beacon Alerts')).toBeInTheDocument();
    expect(screen.getByText('50% complete')).toBeInTheDocument();

    expect(await screen.findByText('Jordan')).toBeInTheDocument();

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock.mock.calls[0][0]).toContain('/api/weeks/week-1/standups');
    expect(fetchMock.mock.calls[1][0]).toContain('/api/weeks/week-2/standups');
    const standupAuthors = screen.getAllByText(/Jordan|Unknown/).map((node) => node.textContent);
    expect(standupAuthors).toEqual(['Jordan', 'Unknown']);
    expect(screen.getByText('Handled support work')).toBeInTheDocument();
    expect(screen.getByText('Shipped API coverage')).toBeInTheDocument();
  });

  it('handles standup fetch failures without blocking the rest of the overview', async () => {
    weeksState.data = createActiveWeeksResponse({
      weeks: [
        createWeek({
          id: 'week-1',
          name: 'Atlas Week 11',
          program_id: 'program-1',
          program_name: 'Atlas',
          days_remaining: 2,
        }),
      ],
      days_remaining: 2,
    });
    fetchMock.mockRejectedValueOnce(new Error('network down'));

    await act(async () => {
      renderPage();
      await Promise.resolve();
    });

    expect(await screen.findByText('No recent standups')).toBeInTheDocument();
  });
});
