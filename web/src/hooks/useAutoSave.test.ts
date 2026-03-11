import { act, renderHook } from '@testing-library/react';
import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { useAutoSave } from './useAutoSave';

describe('useAutoSave', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('retries with exponential backoff and reports terminal failure after exhaustion', async () => {
    const onSave = vi.fn().mockRejectedValue(new Error('save failed'));
    const onFailure = vi.fn();

    const { result } = renderHook(() => useAutoSave({
      onSave,
      maxRetries: 2,
      throttleMs: 100,
      onFailure,
    }));

    act(() => {
      result.current('Unsaved Title');
    });

    await act(async () => {
      await vi.advanceTimersByTimeAsync(100);
      await Promise.resolve();
      await vi.advanceTimersByTimeAsync(1000);
      await Promise.resolve();
      await vi.advanceTimersByTimeAsync(2000);
      await Promise.resolve();
      await vi.runAllTimersAsync();
    });

    expect(onSave.mock.calls.length).toBeGreaterThanOrEqual(3);
    expect(onFailure).toHaveBeenCalledTimes(1);
    expect(onFailure).toHaveBeenCalledWith(
      expect.any(Error),
      'Unsaved Title',
      expect.objectContaining({
        attemptCount: 3,
        maxRetries: 2,
        terminal: true,
      })
    );
  });

  it('invokes onSuccess for a later successful save cycle after an earlier failed attempt', async () => {
    const onSave = vi.fn()
      .mockRejectedValueOnce(new Error('first cycle fails'))
      .mockResolvedValueOnce(undefined)
      .mockResolvedValueOnce(undefined);
    const onSuccess = vi.fn();

    const { result } = renderHook(() => useAutoSave({
      onSave,
      maxRetries: 2,
      throttleMs: 100,
      onSuccess,
    }));

    act(() => {
      result.current('Title A');
    });

    await act(async () => {
      await vi.advanceTimersByTimeAsync(100);
      await Promise.resolve();
      await vi.advanceTimersByTimeAsync(1000);
      await Promise.resolve();
      await vi.runAllTimersAsync();
    });

    act(() => {
      result.current('Title B');
    });

    await act(async () => {
      await vi.advanceTimersByTimeAsync(100);
      await Promise.resolve();
      await vi.runAllTimersAsync();
    });

    expect(onSuccess).toHaveBeenCalledWith('Title B');
  });
});
