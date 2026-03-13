import { useRef, useCallback, useEffect } from 'react';

export interface AutoSaveFailureContext {
  attemptCount: number;
  maxRetries: number;
  terminal: boolean;
}

interface UseAutoSaveOptions {
  onSave: (value: string) => Promise<void>;
  throttleMs?: number; // Default 500ms
  maxRetries?: number; // Default 3
  onSuccess?: (value: string) => void;
  onFailure?: (error: unknown, value: string, context: AutoSaveFailureContext) => void;
}

export type AutoSaveHandler = ((value: string) => void) & {
  flush: (value?: string) => Promise<void>;
};

export function useAutoSave({
  onSave,
  throttleMs = 500,
  maxRetries = 3,
  onSuccess,
  onFailure,
}: UseAutoSaveOptions) {
  const lastSaveTimeRef = useRef(0);
  const pendingValueRef = useRef<string | null>(null);
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const saveSequenceRef = useRef(0);
  const isSavingRef = useRef(false);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
    };
  }, []);

  const getRetryDelayMs = useCallback((retryCount: number) => {
    return Math.min(1000 * (2 ** retryCount), 8000);
  }, []);

  const save = useCallback(async (value: string, sequence: number, retryCount = 0) => {
    // Ignore if a newer save was initiated
    if (sequence < saveSequenceRef.current) return;

    isSavingRef.current = true;
    try {
      await onSave(value);
      if (sequence < saveSequenceRef.current) {
        return;
      }
      lastSaveTimeRef.current = Date.now();
      onSuccess?.(value);

      // If value changed during save, trigger another save
      if (pendingValueRef.current !== null && pendingValueRef.current !== value) {
        const pending = pendingValueRef.current;
        pendingValueRef.current = null;
        saveSequenceRef.current++;
        await save(pending, saveSequenceRef.current);
      }
    } catch (err) {
      if (sequence < saveSequenceRef.current) {
        return;
      }
      if (pendingValueRef.current !== null && pendingValueRef.current !== value) {
        const pending = pendingValueRef.current;
        pendingValueRef.current = null;
        saveSequenceRef.current++;
        await save(pending, saveSequenceRef.current);
        return;
      }
      const attemptCount = retryCount + 1;
      if (retryCount < maxRetries) {
        await new Promise(r => setTimeout(r, getRetryDelayMs(retryCount)));
        await save(value, sequence, retryCount + 1);
      } else {
        console.error('Auto-save failed after retries:', err);
        onFailure?.(err, value, {
          attemptCount,
          maxRetries,
          terminal: true,
        });

        if (pendingValueRef.current !== null && pendingValueRef.current !== value) {
          const pending = pendingValueRef.current;
          pendingValueRef.current = null;
          saveSequenceRef.current++;
          await save(pending, saveSequenceRef.current);
        }
      }
    } finally {
      isSavingRef.current = false;
    }
  }, [getRetryDelayMs, maxRetries, onFailure, onSave, onSuccess]);

  const flushSave = useCallback(async (value?: string) => {
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
      timeoutRef.current = null;
    }

    const nextValue = value ?? pendingValueRef.current;
    if (nextValue === null) {
      return;
    }

    if (isSavingRef.current) {
      pendingValueRef.current = nextValue;
      return;
    }

    pendingValueRef.current = null;
    saveSequenceRef.current++;
    await save(nextValue, saveSequenceRef.current);
  }, [save]);

  const throttledSave = useCallback((value: string) => {
    const now = Date.now();
    const timeSinceLastSave = now - lastSaveTimeRef.current;

    // Clear any pending trailing save
    if (timeoutRef.current) clearTimeout(timeoutRef.current);

    // If currently saving, queue this value
    if (isSavingRef.current) {
      pendingValueRef.current = value;
      return;
    }

    // Throttle: if enough time has passed, save immediately
    if (timeSinceLastSave >= throttleMs) {
      saveSequenceRef.current++;
      save(value, saveSequenceRef.current);
    }

    // Always schedule a trailing save
    timeoutRef.current = setTimeout(() => {
      if (isSavingRef.current) {
        pendingValueRef.current = value;
        return;
      }
      saveSequenceRef.current++;
      save(value, saveSequenceRef.current);
    }, throttleMs);
  }, [save, throttleMs]);

  const autoSave = throttledSave as AutoSaveHandler;
  autoSave.flush = flushSave;

  return autoSave;
}
