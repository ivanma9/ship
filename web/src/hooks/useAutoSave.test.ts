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

  it('flushes the latest queued value immediately', async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);

    const { result } = renderHook(() => useAutoSave({
      onSave,
      throttleMs: 1000,
    }));

    act(() => {
      result.current('Draft Title');
    });

    await act(async () => {
      await result.current.flush('Final Title');
    });

    expect(onSave).toHaveBeenCalledWith('Final Title');
  });

  it('does not start a trailing save while a prior save is still in flight', async () => {
    let resolveSave: (() => void) | null = null;
    const onSave = vi.fn(() => new Promise<void>((resolve) => {
      resolveSave = resolve;
    }));

    const { result } = renderHook(() => useAutoSave({
      onSave,
      throttleMs: 100,
    }));

    act(() => {
      result.current('Title A');
    });

    await act(async () => {
      await vi.advanceTimersByTimeAsync(100);
    });

    act(() => {
      result.current('Title B');
    });

    await act(async () => {
      await vi.advanceTimersByTimeAsync(100);
    });

    expect(onSave).toHaveBeenCalledTimes(1);

    await act(async () => {
      resolveSave?.();
      await Promise.resolve();
    });

    expect(onSave).toHaveBeenCalledTimes(2);
    expect(onSave.mock.calls[1]).toEqual(['Title B']);
  });

  it('saves a newer pending value after an earlier save exhausts retries', async () => {
    const onSave = vi.fn()
      .mockRejectedValueOnce(new Error('stuck save'))
      .mockRejectedValueOnce(new Error('stuck save'))
      .mockResolvedValueOnce(undefined);

    const { result } = renderHook(() => useAutoSave({
      onSave,
      throttleMs: 100,
      maxRetries: 1,
    }));

    act(() => {
      result.current('Title A');
    });

    await act(async () => {
      await vi.advanceTimersByTimeAsync(100);
      await Promise.resolve();
    });

    act(() => {
      result.current('Title B');
    });

    await act(async () => {
      await vi.advanceTimersByTimeAsync(1000);
      await Promise.resolve();
      await vi.runAllTimersAsync();
    });

    expect(onSave).toHaveBeenCalledTimes(3);
    expect(onSave.mock.calls[2]).toEqual(['Title B']);
  });

  it('prefers a newer pending value over retrying a failed stale value', async () => {
    let rejectSave: ((error: Error) => void) | null = null;
    const onSave = vi.fn()
      .mockImplementationOnce(() => new Promise<void>((_, reject) => {
        rejectSave = reject;
      }))
      .mockResolvedValueOnce(undefined);

    const { result } = renderHook(() => useAutoSave({
      onSave,
      throttleMs: 100,
      maxRetries: 2,
    }));

    act(() => {
      result.current('Title A');
    });

    await act(async () => {
      await vi.advanceTimersByTimeAsync(100);
      await Promise.resolve();
    });

    act(() => {
      result.current('Title B');
    });

    await act(async () => {
      rejectSave?.(new Error('save failed'));
      await Promise.resolve();
      await vi.runAllTimersAsync();
    });

    expect(onSave).toHaveBeenCalledTimes(2);
    expect(onSave.mock.calls[1]).toEqual(['Title B']);
  });
});
