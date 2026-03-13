import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('../db/client.js', () => ({
  pool: {
    query: vi.fn(),
  },
}));

import { pool } from '../db/client.js';
import {
  TRACKED_FIELDS,
  addBelongsToAssociation,
  getBelongsToAssociations,
  getBelongsToAssociationsBatch,
  getProgramAssociation,
  getProjectAssociation,
  getSprintAssociation,
  getTimestampUpdates,
  getUserInfo,
  getUserInfoBatch,
  logDocumentChange,
  removeAssociationsByType,
  removeBelongsToAssociation,
  syncBelongsToAssociations,
  updateProgramAssociation,
  updateProjectAssociation,
  updateSprintAssociation,
} from './document-crud.js';

describe('document-crud utils', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('tracks the expected audit fields', () => {
    expect(TRACKED_FIELDS).toEqual([
      'title',
      'state',
      'priority',
      'assignee_id',
      'estimate',
      'belongs_to',
    ]);
  });

  describe('logDocumentChange', () => {
    it('uses the provided queryRunner and defaults automatedBy to null', async () => {
      const queryRunner = { query: vi.fn().mockResolvedValue({ rows: [] }) };

      await logDocumentChange('doc-1', 'state', 'todo', 'done', 'user-1', undefined, queryRunner);

      expect(queryRunner.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO document_history'),
        ['doc-1', 'state', 'todo', 'done', 'user-1', null]
      );
      expect(pool.query).not.toHaveBeenCalled();
    });
  });

  describe('getTimestampUpdates', () => {
    it('sets started_at the first time work begins', () => {
      expect(getTimestampUpdates('todo', 'in_progress')).toEqual({
        started_at: 'COALESCE(started_at, NOW())',
      });
    });

    it('sets reopened_at when work resumes from done', () => {
      expect(getTimestampUpdates('done', 'in_progress')).toEqual({
        reopened_at: 'NOW()',
      });
    });

    it('sets reopened_at when work resumes from cancelled', () => {
      expect(getTimestampUpdates('cancelled', 'in_progress')).toEqual({
        reopened_at: 'NOW()',
      });
    });

    it('sets completed_at when moving into done', () => {
      expect(getTimestampUpdates('in_progress', 'done')).toEqual({
        completed_at: 'COALESCE(completed_at, NOW())',
      });
    });

    it('sets cancelled_at when moving into cancelled', () => {
      expect(getTimestampUpdates('todo', 'cancelled')).toEqual({
        cancelled_at: 'NOW()',
      });
    });

    it('returns no updates when state does not trigger timestamps', () => {
      expect(getTimestampUpdates('done', 'done')).toEqual({});
      expect(getTimestampUpdates(null, 'backlog')).toEqual({});
    });
  });

  describe('association lookup helpers', () => {
    it('maps belongs_to associations and normalizes empty title/color values', async () => {
      vi.mocked(pool.query).mockResolvedValueOnce({
        rows: [
          { id: 'project-1', type: 'project', title: 'Ship Core', color: '#005ea2' },
          { id: 'sprint-1', type: 'sprint', title: '', color: null },
        ],
      } as never);

      await expect(getBelongsToAssociations('doc-1')).resolves.toEqual([
        { id: 'project-1', type: 'project', title: 'Ship Core', color: '#005ea2' },
        { id: 'sprint-1', type: 'sprint', title: undefined, color: undefined },
      ]);
    });

    it('returns an empty map for batch association lookup with no ids', async () => {
      await expect(getBelongsToAssociationsBatch([])).resolves.toEqual(new Map());
      expect(pool.query).not.toHaveBeenCalled();
    });

    it('groups batch associations by document id', async () => {
      vi.mocked(pool.query).mockResolvedValueOnce({
        rows: [
          { document_id: 'doc-1', id: 'program-1', type: 'program', title: 'Atlas', color: '#1b1b1b' },
          { document_id: 'doc-1', id: 'project-1', type: 'project', title: 'Ship UI', color: null },
          { document_id: 'doc-2', id: 'sprint-9', type: 'sprint', title: 'Week 9', color: '#2e2e2e' },
        ],
      } as never);

      const result = await getBelongsToAssociationsBatch(['doc-1', 'doc-2']);

      expect(result.get('doc-1')).toEqual([
        { id: 'program-1', type: 'program', title: 'Atlas', color: '#1b1b1b' },
        { id: 'project-1', type: 'project', title: 'Ship UI', color: undefined },
      ]);
      expect(result.get('doc-2')).toEqual([
        { id: 'sprint-9', type: 'sprint', title: 'Week 9', color: '#2e2e2e' },
      ]);
    });

    it('returns null for missing program, project, and sprint associations', async () => {
      vi.mocked(pool.query).mockResolvedValue({ rows: [] } as never);

      await expect(getProgramAssociation('doc-1')).resolves.toBeNull();
      await expect(getProjectAssociation('doc-1')).resolves.toBeNull();
      await expect(getSprintAssociation('doc-1')).resolves.toBeNull();
    });
  });

  describe('association mutation helpers', () => {
    it('syncs associations by deleting existing rows and inserting new ones', async () => {
      vi.mocked(pool.query).mockResolvedValue({ rows: [] } as never);

      await syncBelongsToAssociations('doc-1', [
        { id: 'project-1', type: 'project' },
        { id: 'sprint-1', type: 'sprint' },
      ]);

      expect(pool.query).toHaveBeenNthCalledWith(
        1,
        'DELETE FROM document_associations WHERE document_id = $1',
        ['doc-1']
      );
      expect(pool.query).toHaveBeenNthCalledWith(
        2,
        expect.stringContaining('INSERT INTO document_associations'),
        ['doc-1', 'project-1', 'project']
      );
      expect(pool.query).toHaveBeenNthCalledWith(
        3,
        expect.stringContaining('INSERT INTO document_associations'),
        ['doc-1', 'sprint-1', 'sprint']
      );
    });

    it('can clear associations without reinserting anything', async () => {
      vi.mocked(pool.query).mockResolvedValue({ rows: [] } as never);

      await syncBelongsToAssociations('doc-1', []);

      expect(pool.query).toHaveBeenCalledTimes(1);
      expect(pool.query).toHaveBeenCalledWith(
        'DELETE FROM document_associations WHERE document_id = $1',
        ['doc-1']
      );
    });

    it('adds and removes a single association', async () => {
      vi.mocked(pool.query).mockResolvedValue({ rows: [] } as never);

      await addBelongsToAssociation('doc-1', 'program-1', 'program');
      await removeBelongsToAssociation('doc-1', 'program-1', 'program');
      await removeAssociationsByType('doc-1', 'program');

      expect(pool.query).toHaveBeenNthCalledWith(
        1,
        expect.stringContaining('ON CONFLICT (document_id, related_id, relationship_type) DO NOTHING'),
        ['doc-1', 'program-1', 'program']
      );
      expect(pool.query).toHaveBeenNthCalledWith(
        2,
        expect.stringContaining('DELETE FROM document_associations'),
        ['doc-1', 'program-1', 'program']
      );
      expect(pool.query).toHaveBeenNthCalledWith(
        3,
        expect.stringContaining('WHERE document_id = $1 AND relationship_type = $2'),
        ['doc-1', 'program']
      );
    });

    it('replaces program, project, and sprint associations and skips insert on null', async () => {
      vi.mocked(pool.query).mockResolvedValue({ rows: [] } as never);

      await updateProgramAssociation('doc-1', 'program-1');
      await updateProjectAssociation('doc-1', null);
      await updateSprintAssociation('doc-1', 'sprint-1');

      expect(pool.query).toHaveBeenNthCalledWith(
        1,
        expect.stringContaining('WHERE document_id = $1 AND relationship_type = $2'),
        ['doc-1', 'program']
      );
      expect(pool.query).toHaveBeenNthCalledWith(
        2,
        expect.stringContaining('ON CONFLICT (document_id, related_id, relationship_type) DO NOTHING'),
        ['doc-1', 'program-1', 'program']
      );
      expect(pool.query).toHaveBeenNthCalledWith(
        3,
        expect.stringContaining('WHERE document_id = $1 AND relationship_type = $2'),
        ['doc-1', 'project']
      );
      expect(pool.query).toHaveBeenNthCalledWith(
        4,
        expect.stringContaining('WHERE document_id = $1 AND relationship_type = $2'),
        ['doc-1', 'sprint']
      );
      expect(pool.query).toHaveBeenNthCalledWith(
        5,
        expect.stringContaining('ON CONFLICT (document_id, related_id, relationship_type) DO NOTHING'),
        ['doc-1', 'sprint-1', 'sprint']
      );
    });
  });

  describe('user lookup helpers', () => {
    it('returns null for missing user ids and unknown users', async () => {
      expect(await getUserInfo(null)).toBeNull();

      vi.mocked(pool.query).mockResolvedValueOnce({ rows: [] } as never);
      expect(await getUserInfo('user-1')).toBeNull();
    });

    it('returns a normalized user object when the user exists', async () => {
      vi.mocked(pool.query).mockResolvedValueOnce({
        rows: [{ id: 'user-1', name: 'Taylor', email: 'taylor@example.com' }],
      } as never);

      await expect(getUserInfo('user-1')).resolves.toEqual({
        id: 'user-1',
        name: 'Taylor',
        email: 'taylor@example.com',
      });
    });

    it('deduplicates batch user ids and returns a keyed map', async () => {
      vi.mocked(pool.query).mockResolvedValueOnce({
        rows: [
          { id: 'user-1', name: 'Taylor', email: 'taylor@example.com' },
          { id: 'user-2', name: 'Jordan', email: 'jordan@example.com' },
        ],
      } as never);

      const result = await getUserInfoBatch(['user-1', 'user-2', 'user-1', '']);

      expect(pool.query).toHaveBeenCalledWith(
        'SELECT id, name, email FROM users WHERE id = ANY($1)',
        [['user-1', 'user-2']]
      );
      expect(result.get('user-1')).toEqual({
        id: 'user-1',
        name: 'Taylor',
        email: 'taylor@example.com',
      });
      expect(result.get('user-2')).toEqual({
        id: 'user-2',
        name: 'Jordan',
        email: 'jordan@example.com',
      });
    });

    it('returns an empty map when batch lookup receives no usable ids', async () => {
      await expect(getUserInfoBatch(['', ''])).resolves.toEqual(new Map());
      expect(pool.query).not.toHaveBeenCalled();
    });
  });
});
