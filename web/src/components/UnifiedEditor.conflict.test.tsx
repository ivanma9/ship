import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, act, fireEvent } from '@testing-library/react';
import type { AutoSaveFailureContext } from '@/hooks/useAutoSave';
import type { RequestError } from '@/lib/http-error';

// Capture the onFailure/onSuccess callbacks from useAutoSave
let capturedOnFailure: ((error: unknown, value: string, ctx: AutoSaveFailureContext) => void) | undefined;
let capturedOnSuccess: ((value: string) => void) | undefined;

vi.mock('@/hooks/useAutoSave', () => ({
  useAutoSave: (opts: {
    onSuccess?: (value: string) => void;
    onFailure?: (error: unknown, value: string, ctx: AutoSaveFailureContext) => void;
  }) => {
    capturedOnFailure = opts.onFailure;
    capturedOnSuccess = opts.onSuccess;
    const fn = vi.fn() as unknown as ReturnType<typeof import('@/hooks/useAutoSave').useAutoSave>;
    fn.flush = vi.fn().mockResolvedValue(undefined);
    return fn;
  },
}));

vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: 'u1', name: 'Test User', email: 'test@example.com' } }),
}));

vi.mock('react-router-dom', () => ({
  useNavigate: () => vi.fn(),
}));

// Stub out the lazy Editor to a simple passthrough
vi.mock('@/components/Editor', () => ({
  Editor: ({ contentBanner }: { contentBanner?: React.ReactNode }) => (
    <div data-testid="editor">{contentBanner}</div>
  ),
}));

vi.mock('@/components/ui/LazyErrorBoundary', () => ({
  LazyErrorBoundary: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}));

vi.mock('@/components/ui/EditorSkeleton', () => ({
  EditorSkeleton: () => <div />,
}));

vi.mock('@/components/PlanQualityBanner', () => ({
  PlanQualityBanner: () => null,
  RetroQualityBanner: () => null,
}));

vi.mock('@/components/sidebars/PropertiesPanel', () => ({
  PropertiesPanel: () => null,
}));

vi.mock('@/components/sidebars/DocumentTypeSelector', () => ({
  DocumentTypeSelector: () => null,
  getMissingRequiredFields: () => [],
}));

vi.mock('@/hooks/useWeeklyReviewActions', () => ({
  useWeeklyReviewActions: () => ({ weeklyReviewState: null }),
}));

import React, { Suspense } from 'react';
import { UnifiedEditor } from './UnifiedEditor';

const baseDoc = {
  id: 'doc-1',
  title: 'My Doc',
  document_type: 'wiki' as const,
};

const baseProps = {
  document: baseDoc,
  onUpdate: vi.fn().mockResolvedValue(undefined),
};

async function renderEditor(props = baseProps) {
  render(
    <Suspense fallback={null}>
      <UnifiedEditor {...props} />
    </Suspense>
  );
  // Wait for lazy Editor to resolve
  await screen.findByTestId('editor');
}

function makeConflictError(currentTitle: string): RequestError {
  const err = new Error('conflict') as RequestError;
  err.status = 409;
  err.code = 'WRITE_CONFLICT';
  err.currentTitle = currentTitle;
  err.currentUpdatedAt = '2026-03-13T10:00:00.000Z';
  err.attemptedTitle = 'My Local Title';
  return err;
}

describe('UnifiedEditor — conflict banner', () => {
  beforeEach(() => {
    capturedOnFailure = undefined;
    capturedOnSuccess = undefined;
    vi.clearAllMocks();
  });

  it('shows no banner by default', async () => {
    await renderEditor();
    expect(screen.queryByRole('alert')).toBeNull();
  });

  it('shows conflict banner when onFailure is called with a 409 WRITE_CONFLICT error', async () => {
    await renderEditor();

    act(() => {
      capturedOnFailure!(makeConflictError('Server Title'), 'My Local Title', {
        attemptCount: 1,
        maxRetries: 3,
        terminal: false,
      });
    });

    const alert = screen.getByRole('alert');
    expect(alert).toBeTruthy();
    expect(alert.textContent).toContain('Server Title');
    expect(alert.textContent).toContain('Retry my title');
  });

  it('displays the correct error message from getTitleSaveErrorMessage for a 409 with currentTitle', async () => {
    await renderEditor();

    act(() => {
      capturedOnFailure!(makeConflictError('Remote Title'), 'Local', {
        attemptCount: 1,
        maxRetries: 3,
        terminal: false,
      });
    });

    const alert = screen.getByRole('alert');
    expect(alert.textContent).toMatch(/Title changed elsewhere/);
    expect(alert.textContent).toContain('"Remote Title"');
  });

  it('shows generic error message for non-409 errors', async () => {
    await renderEditor();

    const genericErr = new Error('network error') as RequestError;
    genericErr.status = 500;

    act(() => {
      capturedOnFailure!(genericErr, 'title', {
        attemptCount: 3,
        maxRetries: 3,
        terminal: true,
      });
    });

    const alert = screen.getByRole('alert');
    expect(alert.textContent).toContain('Title could not be saved');
    expect(screen.queryByText('Retry my title')).toBeNull();
  });

  it('dismisses the conflict banner after clicking "Retry my title"', async () => {
    const onUpdate = vi.fn().mockResolvedValue({ title: 'My Doc', updated_at: '2026-03-13T11:00:00Z' });
    await renderEditor({ ...baseProps, onUpdate });

    act(() => {
      capturedOnFailure!(makeConflictError('Server Title'), 'My Local Title', {
        attemptCount: 1,
        maxRetries: 3,
        terminal: false,
      });
    });

    expect(screen.getByRole('alert')).toBeTruthy();

    await act(async () => {
      fireEvent.click(screen.getByText('Retry my title'));
    });

    expect(screen.queryByRole('alert')).toBeNull();
    expect(onUpdate).toHaveBeenCalledWith(
      expect.objectContaining({ expected_title: 'Server Title' })
    );
  });
});
