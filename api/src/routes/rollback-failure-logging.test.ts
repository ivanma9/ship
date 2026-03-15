/**
 * Tests that ROLLBACK failures are logged when they occur during error recovery.
 *
 * The production code pattern `client.query('ROLLBACK').catch(() => {})` silently
 * swallows rollback errors, making it impossible to detect when a failed transaction
 * was not properly rolled back (leaving the DB in an inconsistent state).
 *
 * These tests verify that rollback failures are logged via console.error.
 */
import { beforeEach, describe, expect, it, vi } from 'vitest';

// Must mock before importing app
vi.mock('../db/client.js', () => ({
  pool: {
    query: vi.fn(),
    connect: vi.fn(),
  },
}));

import request from 'supertest';
import { createApp } from '../app.js';
import { pool } from '../db/client.js';
import { mockQueryResult, mockEmptyResult } from '../test-utils/mock-query-result.js';

const FAKE_USER_ID = '00000000-0000-0000-0000-000000000001';
const FAKE_WORKSPACE_ID = '00000000-0000-0000-0000-000000000002';
const FAKE_DOC_ID = '00000000-0000-0000-0000-000000000003';
const FAKE_TOKEN_ID = '00000000-0000-0000-0000-000000000004';

/** Minimal valid document row for canAccessDocument */
function makeDocRow(overrides: Record<string, unknown> = {}) {
  return {
    id: FAKE_DOC_ID,
    workspace_id: FAKE_WORKSPACE_ID,
    document_type: 'wiki',
    title: 'Test Doc',
    visibility: 'workspace',
    created_by: FAKE_USER_ID,
    properties: {},
    content: null,
    deleted_at: null,
    created_at: new Date(),
    updated_at: new Date(),
    can_access: true,
    ...overrides,
  };
}

/** Minimal valid API token row */
function makeTokenRow() {
  return {
    id: FAKE_TOKEN_ID,
    user_id: FAKE_USER_ID,
    workspace_id: FAKE_WORKSPACE_ID,
    expires_at: null,
    revoked_at: null,
    is_super_admin: false,
  };
}

describe('ROLLBACK failure logging', () => {
  const app = createApp();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('PATCH /api/documents/:id - update document transaction', () => {
    it('logs rollback failure when ROLLBACK itself throws after a transaction error', async () => {
      const primaryError = new Error('DB constraint violation');
      const rollbackError = new Error('Connection lost during ROLLBACK');

      // Auth: API token lookup
      vi.mocked(pool.query)
        .mockResolvedValueOnce(mockQueryResult([makeTokenRow()]))
        // API token last_used_at update
        .mockResolvedValueOnce(mockEmptyResult())
        // canAccessDocument
        .mockResolvedValueOnce(mockQueryResult([makeDocRow()]));

      const mockClient = {
        query: vi.fn()
          .mockResolvedValueOnce(mockEmptyResult()) // BEGIN
          .mockRejectedValueOnce(primaryError)  // First transactional query fails
          .mockRejectedValueOnce(rollbackError), // ROLLBACK also fails
        release: vi.fn(),
      };

      vi.mocked(pool.connect).mockResolvedValueOnce(mockClient as any);

      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      const res = await request(app)
        .patch(`/api/documents/${FAKE_DOC_ID}`)
        .set('Authorization', 'Bearer test-api-token')
        .send({ title: 'Updated Title' });

      expect(res.status).toBe(500);

      // The primary error must be logged
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('Update document error'),
        primaryError
      );

      // The rollback error must ALSO be logged (not silently swallowed)
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('ROLLBACK failed'),
        rollbackError
      );

      consoleSpy.mockRestore();
    });

    it('does not log a rollback error when ROLLBACK succeeds', async () => {
      const primaryError = new Error('DB constraint violation');

      vi.mocked(pool.query)
        .mockResolvedValueOnce(mockQueryResult([makeTokenRow()]))
        .mockResolvedValueOnce(mockEmptyResult())
        .mockResolvedValueOnce(mockQueryResult([makeDocRow()]));

      const mockClient = {
        query: vi.fn()
          .mockResolvedValueOnce(mockEmptyResult()) // BEGIN
          .mockRejectedValueOnce(primaryError)  // First transactional query fails
          .mockResolvedValueOnce(mockEmptyResult()), // ROLLBACK succeeds
        release: vi.fn(),
      };

      vi.mocked(pool.connect).mockResolvedValueOnce(mockClient as any);

      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      const res = await request(app)
        .patch(`/api/documents/${FAKE_DOC_ID}`)
        .set('Authorization', 'Bearer test-api-token')
        .send({ title: 'Updated Title' });

      expect(res.status).toBe(500);

      // Primary error logged
      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('Update document error'),
        primaryError
      );

      // No rollback error logged
      const rollbackErrorCalls = consoleSpy.mock.calls.filter(args =>
        typeof args[0] === 'string' && args[0].includes('ROLLBACK failed')
      );
      expect(rollbackErrorCalls).toHaveLength(0);

      consoleSpy.mockRestore();
    });
  });

  describe('PATCH /api/issues/:id - update issue transaction', () => {
    it('logs rollback failure when ROLLBACK itself throws after a transaction error', async () => {
      const primaryError = new Error('DB constraint violation in issue update');
      const rollbackError = new Error('Connection lost during issue ROLLBACK');

      const issueRow = {
        id: FAKE_DOC_ID,
        workspace_id: FAKE_WORKSPACE_ID,
        document_type: 'issue',
        title: 'Test Issue',
        visibility: 'workspace',
        created_by: FAKE_USER_ID,
        properties: { state: 'todo', priority: 'medium' },
        ticket_number: 42,
        created_at: new Date(),
        updated_at: new Date(),
        deleted_at: null,
      };

      // pool.query calls (not inside transaction):
      // 1. API token validation
      // 2. API token last_used_at update
      // 3. isWorkspaceAdmin (getVisibilityContext)
      vi.mocked(pool.query)
        .mockResolvedValueOnce(mockQueryResult([makeTokenRow()]))
        .mockResolvedValueOnce(mockEmptyResult())
        .mockResolvedValueOnce(mockQueryResult([{ role: 'member' }]));

      // client.query calls:
      // 1. SELECT issue (line 719, before BEGIN)
      // 2. BEGIN
      // 3. First transactional query → primaryError
      // 4. ROLLBACK → rollbackError
      const mockClient = {
        query: vi.fn()
          .mockResolvedValueOnce(mockQueryResult([issueRow])) // SELECT issue (pre-tx)
          .mockResolvedValueOnce(mockEmptyResult()) // BEGIN
          .mockRejectedValueOnce(primaryError)  // First transactional query fails
          .mockRejectedValueOnce(rollbackError), // ROLLBACK also fails
        release: vi.fn(),
      };

      vi.mocked(pool.connect).mockResolvedValueOnce(mockClient as any);

      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      const res = await request(app)
        .patch(`/api/issues/${FAKE_DOC_ID}`)
        .set('Authorization', 'Bearer test-api-token')
        .send({ title: 'Updated Issue' });

      expect(res.status).toBe(500);

      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('Update issue error'),
        primaryError
      );

      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining('ROLLBACK failed'),
        rollbackError
      );

      consoleSpy.mockRestore();
    });
  });
});
