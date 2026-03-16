import { describe, it, expect, vi, beforeEach } from 'vitest';
import { pool } from '../db/client.js';
import { checkMissingAccountability } from '../services/accountability.js';

describe('checkMissingAccountability query count', () => {
  beforeEach(() => {
    vi.restoreAllMocks();
  });

  it('fetches sprint_start_date exactly once', async () => {
    const querySpy = vi.spyOn(pool, 'query');
    querySpy.mockImplementation(async (sql: any) => {
      const text = typeof sql === 'string' ? sql : sql?.text ?? '';
      if (text.includes('sprint_start_date')) {
        return { rows: [{ sprint_start_date: '2025-12-16' }], rowCount: 1 } as any;
      }
      if (text.includes("document_type = 'person'")) {
        return { rows: [{ id: 'person-1' }], rowCount: 1 } as any;
      }
      return { rows: [], rowCount: 0 } as any;
    });

    await checkMissingAccountability('user-1', 'ws-1');

    const sprintStartDateCalls = querySpy.mock.calls.filter(([sql]) => {
      const text = typeof sql === 'string' ? sql : (sql as any)?.text ?? '';
      return text.includes('sprint_start_date');
    });

    expect(sprintStartDateCalls.length).toBe(1);
  });
});
