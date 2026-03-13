import { beforeEach, describe, expect, it, vi } from 'vitest';
import express from 'express';
import request from 'supertest';

const {
  mockPoolQuery,
  mockClientQuery,
  mockRelease,
  mockConnect,
  mockBroadcastToUser,
  mockBroadcastToWorkspace,
} = vi.hoisted(() => {
  const mockPoolQuery = vi.fn();
  const mockClientQuery = vi.fn();
  const mockRelease = vi.fn();
  const mockConnect = vi.fn(() => Promise.resolve({ query: mockClientQuery, release: mockRelease }));
  const mockBroadcastToUser = vi.fn();
  const mockBroadcastToWorkspace = vi.fn();

  return {
    mockPoolQuery,
    mockClientQuery,
    mockRelease,
    mockConnect,
    mockBroadcastToUser,
    mockBroadcastToWorkspace,
  };
});

vi.mock('../db/client.js', () => ({
  pool: {
    query: mockPoolQuery,
    connect: mockConnect,
  },
}));

vi.mock('../middleware/auth.js', () => ({
  authMiddleware: vi.fn((req, _res, next) => {
    req.userId = 'user-1';
    req.workspaceId = 'workspace-1';
    next();
  }),
}));

vi.mock('../middleware/visibility.js', () => ({
  isWorkspaceAdmin: vi.fn().mockResolvedValue(false),
}));

vi.mock('../collaboration/index.js', () => ({
  handleVisibilityChange: vi.fn(),
  handleDocumentConversion: vi.fn(),
  invalidateDocumentCache: vi.fn(),
  broadcastToUser: mockBroadcastToUser,
  broadcastToWorkspace: mockBroadcastToWorkspace,
}));

vi.mock('../utils/extractHypothesis.js', () => ({
  extractHypothesisFromContent: vi.fn(() => null),
  extractSuccessCriteriaFromContent: vi.fn(() => null),
  extractVisionFromContent: vi.fn(() => null),
  extractGoalsFromContent: vi.fn(() => null),
  checkDocumentCompleteness: vi.fn(() => ({ isComplete: true, missingFields: [] })),
}));

vi.mock('../utils/yjsConverter.js', () => ({
  loadContentFromYjsState: vi.fn(),
}));

import documentsRouter from './documents.js';

function createTestApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/documents', documentsRouter);
  return app;
}

describe('Documents API coverage branches', () => {
  const app = createTestApp();

  beforeEach(() => {
    vi.clearAllMocks();
    mockConnect.mockResolvedValue({ query: mockClientQuery, release: mockRelease });
    mockPoolQuery.mockReset();
    mockClientQuery.mockReset();
    mockRelease.mockReset();
  });

  it('rejects PATCH requests with no fields to update', async () => {
    mockPoolQuery.mockResolvedValueOnce({
      rows: [{
        id: 'doc-1',
        workspace_id: 'workspace-1',
        document_type: 'wiki',
        title: 'Draft spec',
        created_by: 'user-1',
        visibility: 'workspace',
        properties: {},
        can_access: true,
      }],
    } as never);

    const response = await request(app)
      .patch('/api/documents/doc-1')
      .send({});

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ error: 'No fields to update' });
    expect(mockClientQuery).toHaveBeenCalledWith('BEGIN');
  });

  it('replaces a direct program association when program_id is provided', async () => {
    mockPoolQuery
      .mockResolvedValueOnce({
        rows: [{
          id: 'doc-1',
          workspace_id: 'workspace-1',
          document_type: 'wiki',
          title: 'Draft spec',
          created_by: 'user-1',
          visibility: 'workspace',
          properties: {},
          can_access: true,
        }],
      } as never)
      .mockResolvedValueOnce({
        rows: [{ id: '22222222-2222-4222-8222-222222222222', type: 'program', title: 'Beacon', color: '#005ea2' }],
      } as never);

    mockClientQuery
      .mockResolvedValueOnce({ rows: [] } as never) // BEGIN
      .mockResolvedValueOnce({ rows: [] } as never) // DELETE old program assoc
      .mockResolvedValueOnce({ rows: [{ id: '22222222-2222-4222-8222-222222222222' }] } as never) // program exists
      .mockResolvedValueOnce({ rows: [] } as never) // INSERT new assoc
      .mockResolvedValueOnce({
        rows: [{
          id: 'doc-1',
          workspace_id: 'workspace-1',
          document_type: 'wiki',
          title: 'Draft spec',
          created_by: 'user-1',
          visibility: 'workspace',
          properties: {},
          updated_at: '2026-03-12T00:00:00.000Z',
        }],
      } as never)
      .mockResolvedValueOnce({ rows: [] } as never); // COMMIT

    const response = await request(app)
      .patch('/api/documents/doc-1')
      .send({ program_id: '22222222-2222-4222-8222-222222222222' });

    expect(response.status).toBe(200);
    expect(response.body.belongs_to).toEqual([
      { id: '22222222-2222-4222-8222-222222222222', type: 'program', title: 'Beacon', color: '#005ea2' },
    ]);
    expect(mockClientQuery).toHaveBeenCalledWith(
      expect.stringContaining(`DELETE FROM document_associations WHERE document_id = $1 AND relationship_type = 'program'`),
      ['doc-1']
    );
    expect(mockClientQuery).toHaveBeenCalledWith(
      expect.stringContaining(`INSERT INTO document_associations`),
      ['doc-1', '22222222-2222-4222-8222-222222222222']
    );
  });

  it('removes an existing sprint association when a direct sprint_id fails validation', async () => {
    mockPoolQuery
      .mockResolvedValueOnce({
        rows: [{
          id: 'doc-2',
          workspace_id: 'workspace-1',
          document_type: 'issue',
          title: 'Existing issue',
          created_by: 'user-1',
          visibility: 'workspace',
          properties: { state: 'backlog' },
          can_access: true,
        }],
      } as never)
      .mockResolvedValueOnce({ rows: [] } as never);

    mockClientQuery
      .mockResolvedValueOnce({ rows: [] } as never) // BEGIN
      .mockResolvedValueOnce({ rows: [] } as never) // DELETE old sprint assoc
      .mockResolvedValueOnce({ rows: [] } as never) // invalid sprint lookup
      .mockResolvedValueOnce({
        rows: [{
          id: 'doc-2',
          workspace_id: 'workspace-1',
          document_type: 'issue',
          title: 'Existing issue',
          created_by: 'user-1',
          visibility: 'workspace',
          properties: { state: 'backlog' },
          updated_at: '2026-03-12T00:00:00.000Z',
        }],
      } as never)
      .mockResolvedValueOnce({ rows: [] } as never); // COMMIT

    const response = await request(app)
      .patch('/api/documents/doc-2')
      .send({ sprint_id: '11111111-1111-1111-1111-111111111111' });

    expect(response.status).toBe(200);
    expect(response.body.belongs_to).toEqual([]);
    expect(mockClientQuery).toHaveBeenCalledWith(
      expect.stringContaining(`DELETE FROM document_associations WHERE document_id = $1 AND relationship_type = 'sprint'`),
      ['doc-2']
    );
  });

  it('rejects changing document type when the current user is not the creator', async () => {
    mockPoolQuery.mockResolvedValueOnce({
      rows: [{
        id: 'doc-3',
        workspace_id: 'workspace-1',
        document_type: 'wiki',
        title: 'Draft spec',
        created_by: 'someone-else',
        visibility: 'workspace',
        properties: {},
        can_access: true,
      }],
    } as never);

    const response = await request(app)
      .patch('/api/documents/doc-3')
      .send({ document_type: 'project' });

    expect(response.status).toBe(403);
    expect(response.body).toEqual({ error: 'Only the document creator can change its type' });
  });

  it('rejects changing to or from restricted document types', async () => {
    mockPoolQuery.mockResolvedValueOnce({
      rows: [{
        id: 'doc-4',
        workspace_id: 'workspace-1',
        document_type: 'wiki',
        title: 'Draft spec',
        created_by: 'user-1',
        visibility: 'workspace',
        properties: {},
        can_access: true,
      }],
    } as never);

    const response = await request(app)
      .patch('/api/documents/doc-4')
      .send({ document_type: 'person' });

    expect(response.status).toBe(400);
    expect(response.body).toEqual({ error: 'Cannot change to or from program or person document types' });
  });

  it('assigns the next ticket number when converting a creator-owned wiki to an issue', async () => {
    mockPoolQuery
      .mockResolvedValueOnce({
        rows: [{
          id: 'doc-5',
          workspace_id: 'workspace-1',
          document_type: 'wiki',
          title: 'Draft spec',
          created_by: 'user-1',
          visibility: 'workspace',
          properties: {},
          ticket_number: null,
          can_access: true,
        }],
      } as never)
      .mockResolvedValueOnce({ rows: [] } as never);

    mockClientQuery
      .mockResolvedValueOnce({ rows: [] } as never) // BEGIN
      .mockResolvedValueOnce({ rows: [] } as never) // advisory lock
      .mockResolvedValueOnce({ rows: [{ next_number: 17 }] } as never) // next ticket number
      .mockResolvedValueOnce({
        rows: [{
          id: 'doc-5',
          workspace_id: 'workspace-1',
          document_type: 'issue',
          title: 'Draft spec',
          created_by: 'user-1',
          visibility: 'workspace',
          properties: {},
          ticket_number: 17,
          updated_at: '2026-03-12T00:00:00.000Z',
        }],
      } as never)
      .mockResolvedValueOnce({ rows: [] } as never); // COMMIT

    const response = await request(app)
      .patch('/api/documents/doc-5')
      .send({ document_type: 'issue' });

    expect(response.status).toBe(200);
    expect(response.body.document_type).toBe('issue');
    expect(response.body.ticket_number).toBe(17);
    expect(mockClientQuery).toHaveBeenCalledWith(
      'SELECT pg_advisory_xact_lock($1)',
      [expect.any(Number)]
    );
  });
});
