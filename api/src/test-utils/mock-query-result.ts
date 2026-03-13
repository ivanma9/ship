import type { FieldDef } from 'pg';

/**
 * Creates a pg.QueryResult-shaped object for use in Vitest mocks.
 * Returns `any` so it satisfies all overloads of pool.query mock.
 *
 * Usage:
 *   vi.mocked(pool.query).mockResolvedValueOnce(mockQueryResult([{ id: '1' }]));
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function mockQueryResult<T extends Record<string, unknown>>(
  rows: T[],
  overrides: Partial<{ rowCount: number; command: string }> = {}
// eslint-disable-next-line @typescript-eslint/no-explicit-any
): any {
  return {
    rows,
    rowCount: overrides.rowCount ?? rows.length,
    command: overrides.command ?? 'SELECT',
    oid: 0,
    fields: [] as FieldDef[],
  };
}

/**
 * Shorthand for an empty result set.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function mockEmptyResult(): any {
  return mockQueryResult([]);
}
