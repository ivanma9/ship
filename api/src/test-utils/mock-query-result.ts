import type { QueryResult, FieldDef } from 'pg';

/**
 * Creates a properly-typed pg.QueryResult for use in Vitest mocks.
 * Eliminates `as any` casts in test files.
 *
 * Usage:
 *   vi.mocked(pool.query).mockResolvedValueOnce(mockQueryResult([{ id: '1' }]));
 */
export function mockQueryResult<T extends Record<string, unknown>>(
  rows: T[],
  overrides: Partial<QueryResult<T>> = {}
): QueryResult<T> {
  return {
    rows,
    rowCount: rows.length,
    command: 'SELECT',
    oid: 0,
    fields: [] as FieldDef[],
    ...overrides,
  };
}

/**
 * Shorthand for an empty result set.
 */
export function mockEmptyResult(): QueryResult<Record<string, unknown>> {
  return mockQueryResult([]);
}
