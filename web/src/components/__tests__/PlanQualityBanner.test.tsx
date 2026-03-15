import { render, screen, waitFor } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { PlanQualityBanner, RetroQualityBanner } from '../PlanQualityBanner';

// Mock fetch globally
const mockFetch = vi.fn();
global.fetch = mockFetch;

function mockFetchResponses(responses: Record<string, unknown>) {
  mockFetch.mockImplementation((url: string) => {
    for (const [pattern, body] of Object.entries(responses)) {
      if (url.includes(pattern)) {
        return Promise.resolve({
          ok: true,
          json: () => Promise.resolve(body),
        });
      }
    }
    return Promise.resolve({ ok: false, json: () => Promise.resolve({}) });
  });
}

describe('PlanQualityBanner', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('shows API key warning when analyze-plan returns ai_unavailable', async () => {
    mockFetchResponses({
      '/api/ai/status': { available: true },
      '/api/csrf-token': { token: 'test' },
      '/api/documents/doc-1': { content: { type: 'doc', content: [{ type: 'paragraph', content: [{ type: 'text', text: 'test' }] }] } },
      '/api/ai/analyze-plan': { error: 'ai_unavailable' },
    });

    render(
      <PlanQualityBanner
        documentId="doc-1"
        editorContent={{ type: 'doc', content: [{ type: 'paragraph', content: [{ type: 'text', text: 'test' }] }] }}
      />
    );

    await waitFor(() => {
      expect(screen.getByText('Please enter an API key to use AI functionality.')).toBeInTheDocument();
    });
  });

  it('does not show warning when analyze-plan succeeds', async () => {
    mockFetchResponses({
      '/api/ai/status': { available: true },
      '/api/csrf-token': { token: 'test' },
      '/api/documents/doc-1': { content: { type: 'doc', content: [{ type: 'paragraph' }] }, properties: {} },
      '/api/ai/analyze-plan': {
        overall_score: 0.8,
        items: [],
        workload_assessment: 'moderate',
        workload_feedback: 'Good',
      },
    });

    render(
      <PlanQualityBanner
        documentId="doc-1"
        editorContent={{ type: 'doc', content: [{ type: 'paragraph' }] }}
      />
    );

    await waitFor(() => {
      expect(screen.getByText('80%')).toBeInTheDocument();
    });

    expect(screen.queryByText('Please enter an API key to use AI functionality.')).not.toBeInTheDocument();
  });
});

describe('RetroQualityBanner', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('shows API key warning when analyze-retro returns ai_unavailable', async () => {
    const planContent = { type: 'doc', content: [{ type: 'paragraph' }] };

    mockFetchResponses({
      '/api/ai/status': { available: true },
      '/api/csrf-token': { token: 'test' },
      '/api/documents/doc-2': { content: { type: 'doc', content: [{ type: 'paragraph', content: [{ type: 'text', text: 'retro' }] }] }, properties: {} },
      '/api/ai/analyze-retro': { error: 'ai_unavailable' },
    });

    render(
      <RetroQualityBanner
        documentId="doc-2"
        editorContent={{ type: 'doc', content: [{ type: 'paragraph', content: [{ type: 'text', text: 'retro' }] }] }}
        planContent={planContent}
      />
    );

    await waitFor(() => {
      expect(screen.getByText('Please enter an API key to use AI functionality.')).toBeInTheDocument();
    });
  });
});
