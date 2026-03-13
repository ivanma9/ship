import React from 'react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { renderHook, waitFor } from '@testing-library/react';

vi.mock('@/lib/api', () => ({
  apiGet: vi.fn(),
}));

import { apiGet } from '@/lib/api';
import { useDashboardFocus } from './useDashboardFocus';

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

  return function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    );
  };
}

describe('useDashboardFocus', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('returns dashboard focus data when the request succeeds', async () => {
    vi.mocked(apiGet).mockResolvedValue({
      ok: true,
      json: async () => ({
        person_id: 'person-1',
        current_week_number: 11,
        week_start: '2026-03-09',
        week_end: '2026-03-15',
        projects: [],
      }),
    } as Response);

    const { result } = renderHook(() => useDashboardFocus(), {
      wrapper: createWrapper(),
    });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data).toEqual({
      person_id: 'person-1',
      current_week_number: 11,
      week_start: '2026-03-09',
      week_end: '2026-03-15',
      projects: [],
    });
    expect(apiGet).toHaveBeenCalledWith('/api/dashboard/my-focus');
  });

  it('surfaces the failing status when the request is not ok', async () => {
    vi.mocked(apiGet).mockResolvedValue({
      ok: false,
      status: 503,
      json: async () => ({}),
    } as Response);

    const { result } = renderHook(() => useDashboardFocus(), {
      wrapper: createWrapper(),
    });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });

    expect(result.current.error).toMatchObject({
      message: 'Failed to fetch focus data',
      status: 503,
    });
  });
});
