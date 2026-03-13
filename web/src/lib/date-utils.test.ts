import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  formatDate,
  formatDateRange,
  formatRelativeTime,
} from './date-utils';

describe('date utils', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-03-12T18:00:00Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('formats recent and missing dates for dashboard-style display', () => {
    expect(formatDate(null)).toBe('Unknown date');
    expect(formatDate('2026-03-12T17:59:45Z')).toBe('Just now');
    expect(formatDate('2026-03-12T17:15:00Z')).toBe('45m ago');
    expect(formatDate('2026-03-12T14:00:00Z')).toBe('4h ago');
    expect(formatDate('2026-03-10T18:00:00Z')).toBe('2d ago');
    expect(formatDate('2026-03-01T18:00:00Z')).toBe('Mar 1');
  });

  it('formats relative time at both recent and older thresholds', () => {
    expect(formatRelativeTime('2026-03-12T17:59:45Z')).toBe('just now');
    expect(formatRelativeTime('2026-03-12T17:50:00Z')).toBe('10m ago');
    expect(formatRelativeTime('2026-03-12T11:00:00Z')).toBe('7h ago');
    expect(formatRelativeTime('2026-03-09T18:00:00Z')).toBe('3d ago');
    expect(formatRelativeTime('2026-02-20T18:00:00Z')).toBe(
      new Date('2026-02-20T18:00:00Z').toLocaleDateString()
    );
  });

  it('formats same-month and cross-month date ranges', () => {
    expect(formatDateRange('2026-03-09', '2026-03-15')).toBe('Mar 9-15');
    expect(
      formatDateRange(new Date('2026-03-30T12:00:00Z'), new Date('2026-04-05T12:00:00Z'))
    ).toBe('Mar 30 - Apr 5');
  });
});
