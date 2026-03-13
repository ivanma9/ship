import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { render, screen } from '@testing-library/react';
import { DashboardVariantC } from './DashboardVariantC';
import type { ActionItemsResponse } from '@/hooks/useDashboardActionItems';
import type { FocusResponse } from '@/hooks/useDashboardFocus';

function createFocusResponse(overrides: Partial<FocusResponse> = {}): FocusResponse {
  return {
    person_id: 'person-1',
    current_week_number: 11,
    week_start: '2026-03-09',
    week_end: '2026-03-15',
    projects: [],
    ...overrides,
  };
}

const actionItemsState = vi.hoisted(() => ({
  data: { action_items: [] } as ActionItemsResponse,
  isLoading: false,
}));

const focusState = vi.hoisted(() => ({
  data: createFocusResponse(),
  isLoading: false,
}));

vi.mock('@/hooks/useDashboardActionItems', () => ({
  useDashboardActionItems: () => actionItemsState,
}));

vi.mock('@/hooks/useDashboardFocus', () => ({
  useDashboardFocus: () => focusState,
}));

function renderComponent() {
  return render(
    <MemoryRouter>
      <DashboardVariantC />
    </MemoryRouter>
  );
}

describe('DashboardVariantC', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-03-09T12:00:00Z'));

    actionItemsState.data = { action_items: [] };
    actionItemsState.isLoading = false;
    focusState.data = createFocusResponse();
    focusState.isLoading = false;
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('shows a loading shell while either dashboard query is pending', () => {
    actionItemsState.isLoading = true;

    renderComponent();

    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  it('renders the zen card and previous-plan fallback when all rituals are complete', () => {
    focusState.data = createFocusResponse({
      projects: [
        {
          id: 'project-1',
          title: 'Atlas Dashboard',
          program_name: 'Atlas',
          plan: null,
          previous_plan: {
            id: 'plan-10',
            week_number: 10,
            items: [{ text: 'Close review comments', checked: false }],
          },
          recent_activity: [],
        },
      ],
    });

    renderComponent();

    expect(screen.getByText("You're in the zone")).toBeInTheDocument();
    expect(screen.getByText('Retro W11 due Thursday')).toBeInTheDocument();
    expect(screen.getByText('Your Focus This Week')).toBeInTheDocument();
    expect(screen.getByText('Week 10 plan')).toBeInTheDocument();
    expect(screen.getByText('1.')).toBeInTheDocument();
    expect(screen.getByText('Close review comments')).toBeInTheDocument();
  });

  it('orders prompt cards by urgency and shows retro-specific actions', () => {
    actionItemsState.data = {
      action_items: [
        {
          id: 'plan-11',
          type: 'plan',
          sprint_id: 'sprint-11',
          sprint_title: 'Week 11',
          program_id: 'program-1',
          program_name: 'Atlas',
          sprint_number: 11,
          urgency: 'due_today',
          days_until_due: 0,
          message: 'Due today',
        },
        {
          id: 'retro-10',
          type: 'retro',
          sprint_id: 'sprint-10',
          sprint_title: 'Week 10',
          program_id: 'program-1',
          program_name: 'Atlas',
          sprint_number: 10,
          urgency: 'overdue',
          days_until_due: -2,
          message: 'Overdue',
        },
      ],
    };
    focusState.data = createFocusResponse({
      projects: [
        {
          id: 'project-1',
          title: 'Atlas Dashboard',
          program_name: 'Atlas',
          plan: {
            id: 'plan-11',
            week_number: 11,
            items: [{ text: 'Ship the dashboard', checked: false }],
          },
          previous_plan: null,
          recent_activity: [],
        },
      ],
    });

    renderComponent();

    const headings = screen.getAllByRole('heading', { level: 2 });
    expect(headings.map((node) => node.textContent)).toEqual([
      'Your Focus',
    ]);
    const writeCopy = screen.getAllByText(/Write your Week/i).map((node) => node.textContent);
    expect(writeCopy[0]).toContain('Write your Week 10 retro');
    expect(writeCopy[1]).toContain('Write your Week 11 plan');
    expect(screen.getByRole('link', { name: /Write retro/i })).toHaveAttribute('href', '/documents/sprint-10');
    expect(screen.getByRole('button', { name: /View last week's plan/i })).toBeInTheDocument();
  });

  it('shows an empty focus state and next-week ritual after Thursday', () => {
    vi.setSystemTime(new Date('2026-03-13T12:00:00Z'));
    focusState.data = createFocusResponse({
      projects: [
        {
          id: 'project-2',
          title: 'Operations',
          program_name: 'Ops',
          plan: null,
          previous_plan: null,
          recent_activity: [],
        },
      ],
    });

    renderComponent();

    expect(screen.getByText('Plan W12 due Monday')).toBeInTheDocument();
    expect(screen.getByText(/No plan written yet/)).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /Write your plan/i })).toHaveAttribute('href', '/documents/project-2');
  });
});
