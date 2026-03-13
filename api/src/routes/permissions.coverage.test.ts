import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import request from 'supertest';
import crypto from 'crypto';
import { createApp } from '../app.js';
import { pool } from '../db/client.js';

describe('Permissions and workspace coverage', () => {
  const app = createApp();
  const testRunId = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;

  const primaryWorkspaceName = `Permissions Primary ${testRunId}`;
  const archivedWorkspaceName = `Permissions Archived ${testRunId}`;
  const superAdminEmail = `perm-super-${testRunId}@ship.local`;
  const memberEmail = `perm-member-${testRunId}@ship.local`;
  const extraUserEmail = `perm-extra-${testRunId}@ship.local`;
  const archivedUserEmail = `perm-archived-${testRunId}@ship.local`;

  let primaryWorkspaceId: string;
  let archivedWorkspaceId: string;
  let superAdminUserId: string;
  let memberUserId: string;
  let extraUserId: string;
  let archivedUserId: string;
  let superAdminCookie: string;
  let superAdminCsrfToken: string;
  let memberCookie: string;
  let memberCsrfToken: string;

  async function createAnonymousCsrfContext(): Promise<{ cookie: string; token: string }> {
    const csrfResponse = await request(app).get('/api/csrf-token');
    return {
      cookie: csrfResponse.headers['set-cookie']?.[0]?.split(';')[0] || '',
      token: csrfResponse.body.token,
    };
  }

  beforeAll(async () => {
    const workspaceResult = await pool.query(
      `INSERT INTO workspaces (name) VALUES ($1), ($2) RETURNING id, name`,
      [primaryWorkspaceName, archivedWorkspaceName]
    );
    primaryWorkspaceId = workspaceResult.rows.find((row) => row.name === primaryWorkspaceName)!.id;
    archivedWorkspaceId = workspaceResult.rows.find((row) => row.name === archivedWorkspaceName)!.id;

    await pool.query(
      `UPDATE workspaces SET archived_at = NOW() WHERE id = $1`,
      [archivedWorkspaceId]
    );

    const userResult = await pool.query(
      `INSERT INTO users (email, password_hash, name, is_super_admin)
       VALUES
         ($1, 'test-hash', 'Permissions Super', true),
         ($2, 'test-hash', 'Permissions Member', false),
         ($3, 'test-hash', 'Permissions Extra', false),
         ($4, 'test-hash', 'Permissions Archived', false)
       RETURNING id, email`,
      [superAdminEmail, memberEmail, extraUserEmail, archivedUserEmail]
    );

    superAdminUserId = userResult.rows.find((row) => row.email === superAdminEmail)!.id;
    memberUserId = userResult.rows.find((row) => row.email === memberEmail)!.id;
    extraUserId = userResult.rows.find((row) => row.email === extraUserEmail)!.id;
    archivedUserId = userResult.rows.find((row) => row.email === archivedUserEmail)!.id;

    await pool.query(
      `INSERT INTO workspace_memberships (workspace_id, user_id, role)
       VALUES
         ($1, $2, 'admin'),
         ($1, $3, 'member')`,
      [primaryWorkspaceId, superAdminUserId, memberUserId]
    );

    const superSessionId = crypto.randomBytes(32).toString('hex');
    await pool.query(
      `INSERT INTO sessions (id, user_id, workspace_id, expires_at)
       VALUES ($1, $2, $3, now() + interval '1 hour')`,
      [superSessionId, superAdminUserId, primaryWorkspaceId]
    );
    superAdminCookie = `session_id=${superSessionId}`;

    const memberSessionId = crypto.randomBytes(32).toString('hex');
    await pool.query(
      `INSERT INTO sessions (id, user_id, workspace_id, expires_at)
       VALUES ($1, $2, $3, now() + interval '1 hour')`,
      [memberSessionId, memberUserId, primaryWorkspaceId]
    );
    memberCookie = `session_id=${memberSessionId}`;

    const superCsrfRes = await request(app).get('/api/csrf-token').set('Cookie', superAdminCookie);
    superAdminCsrfToken = superCsrfRes.body.token;
    const superConnectSidCookie = superCsrfRes.headers['set-cookie']?.[0]?.split(';')[0] || '';
    if (superConnectSidCookie) {
      superAdminCookie = `${superAdminCookie}; ${superConnectSidCookie}`;
    }

    const memberCsrfRes = await request(app).get('/api/csrf-token').set('Cookie', memberCookie);
    memberCsrfToken = memberCsrfRes.body.token;
    const memberConnectSidCookie = memberCsrfRes.headers['set-cookie']?.[0]?.split(';')[0] || '';
    if (memberConnectSidCookie) {
      memberCookie = `${memberCookie}; ${memberConnectSidCookie}`;
    }
  });

  beforeEach(async () => {
    await pool.query(`DELETE FROM workspace_invites WHERE workspace_id = $1`, [primaryWorkspaceId]);
    await pool.query(
      `DELETE FROM documents
       WHERE workspace_id = $1
         AND document_type = 'person'`,
      [primaryWorkspaceId]
    );
    await pool.query(
      `DELETE FROM workspace_memberships
       WHERE workspace_id = $1 AND user_id IN ($2, $3)`,
      [primaryWorkspaceId, extraUserId, archivedUserId]
    );
    await pool.query(`DELETE FROM audit_logs WHERE workspace_id = $1`, [primaryWorkspaceId]);
  });

  afterAll(async () => {
    await pool.query(
      `DELETE FROM sessions WHERE user_id IN ($1, $2, $3, $4)`,
      [superAdminUserId, memberUserId, extraUserId, archivedUserId]
    );
    await pool.query(`DELETE FROM workspace_invites WHERE workspace_id IN ($1, $2)`, [primaryWorkspaceId, archivedWorkspaceId]);
    await pool.query(`DELETE FROM documents WHERE workspace_id IN ($1, $2)`, [primaryWorkspaceId, archivedWorkspaceId]);
    await pool.query(
      `DELETE FROM workspace_memberships WHERE user_id IN ($1, $2, $3, $4)`,
      [superAdminUserId, memberUserId, extraUserId, archivedUserId]
    );
    await pool.query(`DELETE FROM users WHERE id IN ($1, $2, $3, $4)`, [superAdminUserId, memberUserId, extraUserId, archivedUserId]);
    await pool.query(`DELETE FROM workspaces WHERE id IN ($1, $2)`, [primaryWorkspaceId, archivedWorkspaceId]);
  });

  describe('workspace switching and current workspace branches', () => {
    it('returns 404 when switching to a missing workspace', async () => {
      const response = await request(app)
        .post('/api/workspaces/11111111-1111-4111-8111-111111111111/switch')
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken);

      expect(response.status).toBe(404);
      expect(response.body.error.message).toBe('Workspace not found');
    });

    it('returns 403 when switching to an archived workspace', async () => {
      const response = await request(app)
        .post(`/api/workspaces/${archivedWorkspaceId}/switch`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken);

      expect(response.status).toBe(403);
      expect(response.body.error.message).toBe('Cannot switch to archived workspace');
    });
  });

  describe('member management branches', () => {
    it('rejects adding a missing user as a member', async () => {
      const response = await request(app)
        .post(`/api/workspaces/${primaryWorkspaceId}/members`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ userId: '11111111-1111-4111-8111-111111111111' });

      expect(response.status).toBe(404);
      expect(response.body.error.message).toBe('User not found');
    });

    it('rejects adding an existing member twice', async () => {
      const response = await request(app)
        .post(`/api/workspaces/${primaryWorkspaceId}/members`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ userId: memberUserId });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('User is already a member of this workspace');
    });

    it('rejects invalid role updates', async () => {
      const response = await request(app)
        .patch(`/api/workspaces/${primaryWorkspaceId}/members/${memberUserId}`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ role: 'owner' });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('Valid role (admin or member) is required');
    });

    it('rejects demoting the last admin', async () => {
      const response = await request(app)
        .patch(`/api/workspaces/${primaryWorkspaceId}/members/${superAdminUserId}`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ role: 'member' });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('Cannot demote the last admin. Workspace must have at least one admin.');
    });

    it('returns 404 when updating a missing membership', async () => {
      const response = await request(app)
        .patch(`/api/workspaces/${primaryWorkspaceId}/members/${extraUserId}`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ role: 'admin' });

      expect(response.status).toBe(404);
      expect(response.body.error.message).toBe('Membership not found');
    });

    it('returns 404 when deleting a missing membership', async () => {
      const response = await request(app)
        .delete(`/api/workspaces/${primaryWorkspaceId}/members/${extraUserId}`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken);

      expect(response.status).toBe(404);
      expect(response.body.error.message).toBe('Membership not found');
    });

    it('rejects removing the last admin', async () => {
      const response = await request(app)
        .delete(`/api/workspaces/${primaryWorkspaceId}/members/${superAdminUserId}`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken);

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('Cannot remove the last admin. Workspace must have at least one admin.');
    });

    it('returns 404 when restoring a user without a person document', async () => {
      const response = await request(app)
        .post(`/api/workspaces/${primaryWorkspaceId}/members/${archivedUserId}/restore`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken);

      expect(response.status).toBe(404);
      expect(response.body.error.message).toBe('Person document not found');
    });

    it('returns 400 when restoring a user who is not archived', async () => {
      await pool.query(
        `INSERT INTO documents (workspace_id, document_type, title, properties, created_by)
         VALUES ($1, 'person', 'Active Person', $2, $3)`,
        [primaryWorkspaceId, JSON.stringify({ user_id: archivedUserId, email: archivedUserEmail }), superAdminUserId]
      );

      const response = await request(app)
        .post(`/api/workspaces/${primaryWorkspaceId}/members/${archivedUserId}/restore`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken);

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('User is not archived');
    });

    it('restores an archived user and recreates a missing membership', async () => {
      await pool.query(
        `INSERT INTO documents (workspace_id, document_type, title, properties, created_by, archived_at)
         VALUES ($1, 'person', 'Archived Person', $2, $3, NOW())`,
        [primaryWorkspaceId, JSON.stringify({ user_id: archivedUserId, email: archivedUserEmail }), superAdminUserId]
      );

      const response = await request(app)
        .post(`/api/workspaces/${primaryWorkspaceId}/members/${archivedUserId}/restore`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken);

      expect(response.status).toBe(200);

      const membershipResult = await pool.query(
        `SELECT role FROM workspace_memberships WHERE workspace_id = $1 AND user_id = $2`,
        [primaryWorkspaceId, archivedUserId]
      );
      expect(membershipResult.rows[0]?.role).toBe('member');

      const personResult = await pool.query(
        `SELECT archived_at FROM documents
         WHERE workspace_id = $1 AND document_type = 'person' AND properties->>'user_id' = $2`,
        [primaryWorkspaceId, archivedUserId]
      );
      expect(personResult.rows[0]?.archived_at).toBeNull();
    });
  });

  describe('workspace invite creation branches', () => {
    it('requires email when creating an invite', async () => {
      const response = await request(app)
        .post(`/api/workspaces/${primaryWorkspaceId}/invites`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ role: 'member' });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('Email is required');
    });

    it('rejects invites for users who are already members', async () => {
      const response = await request(app)
        .post(`/api/workspaces/${primaryWorkspaceId}/invites`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ email: memberEmail, role: 'member' });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('User is already a member of this workspace');
    });

    it('rejects duplicate pending invites for the same identity', async () => {
      await request(app)
        .post(`/api/workspaces/${primaryWorkspaceId}/invites`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ email: `pending-${testRunId}@ship.local`, role: 'member' });

      const response = await request(app)
        .post(`/api/workspaces/${primaryWorkspaceId}/invites`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ email: `pending-${testRunId}@ship.local`, role: 'member' });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('An invite is already pending for this identity');
    });

    it('directly adds an existing non-member user and marks prior invites as used', async () => {
      const email = extraUserEmail;
      const pendingInviteResult = await pool.query(
        `INSERT INTO workspace_invites (workspace_id, email, role, invited_by_user_id, token, expires_at)
         VALUES ($1, $2, 'member', $3, $4, now() + interval '7 days')
         RETURNING id`,
        [primaryWorkspaceId, email, superAdminUserId, `preexisting-${testRunId}`]
      );
      const pendingInviteId = pendingInviteResult.rows[0].id;

      await pool.query(
        `INSERT INTO documents (workspace_id, document_type, title, properties, created_by)
         VALUES ($1, 'person', 'Pending Extra', $2, $3)`,
        [primaryWorkspaceId, JSON.stringify({ pending: true, invite_id: pendingInviteId, email }), superAdminUserId]
      );

      const response = await request(app)
        .post(`/api/workspaces/${primaryWorkspaceId}/invites`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ email, role: 'admin', x509SubjectDn: null });

      expect(response.status).toBe(201);
      expect(response.body.data.member).toMatchObject({
        id: extraUserId,
        email,
        role: 'admin',
      });
      expect(response.body.data.message).toBe('User added as member (existing account)');

      const membershipResult = await pool.query(
        `SELECT role FROM workspace_memberships WHERE workspace_id = $1 AND user_id = $2`,
        [primaryWorkspaceId, extraUserId]
      );
      expect(membershipResult.rows[0]?.role).toBe('admin');

      const inviteResult = await pool.query(
        `SELECT used_at FROM workspace_invites WHERE id = $1`,
        [pendingInviteId]
      );
      expect(inviteResult.rows[0]?.used_at).not.toBeNull();

      const personResult = await pool.query(
        `SELECT properties FROM documents
         WHERE workspace_id = $1 AND document_type = 'person' AND LOWER(properties->>'email') = LOWER($2)`,
        [primaryWorkspaceId, email]
      );
      expect(personResult.rows[0]?.properties.user_id).toBe(extraUserId);
      expect(personResult.rows[0]?.properties.pending).toBeUndefined();
    });

    it('returns 404 when revoking a missing invite', async () => {
      const response = await request(app)
        .delete(`/api/workspaces/${primaryWorkspaceId}/invites/11111111-1111-4111-8111-111111111111`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken);

      expect(response.status).toBe(404);
      expect(response.body.error.message).toBe('Invite not found');
    });
  });

  describe('public invite validation and acceptance branches', () => {
    it('marks invites used when the invited user is already a member', async () => {
      const token = `already-member-${testRunId}`;
      const inviteResult = await pool.query(
        `INSERT INTO workspace_invites (workspace_id, email, role, invited_by_user_id, token, expires_at)
         VALUES ($1, $2, 'member', $3, $4, now() + interval '7 days')
         RETURNING id`,
        [primaryWorkspaceId, memberEmail, superAdminUserId, token]
      );

      const response = await request(app).get(`/api/invites/${token}`);

      expect(response.status).toBe(200);
      expect(response.body.data.userExists).toBe(true);
      expect(response.body.data.alreadyMember).toBe(true);

      const usedInvite = await pool.query(
        `SELECT used_at FROM workspace_invites WHERE id = $1`,
        [inviteResult.rows[0].id]
      );
      expect(usedInvite.rows[0]?.used_at).not.toBeNull();
    });

    it('rejects accepting an invalid invite token', async () => {
      const anonymousCsrf = await createAnonymousCsrfContext();
      const response = await request(app)
        .post('/api/invites/not-a-real-token/accept')
        .set('Cookie', anonymousCsrf.cookie)
        .set('x-csrf-token', anonymousCsrf.token)
        .send({ password: 'valid-pass', name: 'Ghost' });

      expect(response.status).toBe(404);
      expect(response.body.error.message).toBe('Invalid invite link');
    });

    it('rejects accepting an expired invite token', async () => {
      const token = `expired-accept-${testRunId}`;
      await pool.query(
        `INSERT INTO workspace_invites (workspace_id, email, role, invited_by_user_id, token, expires_at)
         VALUES ($1, $2, 'member', $3, $4, now() - interval '1 day')`,
        [primaryWorkspaceId, `expired-${testRunId}@ship.local`, superAdminUserId, token]
      );

      const anonymousCsrf = await createAnonymousCsrfContext();
      const response = await request(app)
        .post(`/api/invites/${token}/accept`)
        .set('Cookie', anonymousCsrf.cookie)
        .set('x-csrf-token', anonymousCsrf.token)
        .send({ password: 'valid-pass', name: 'Expired User' });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('This invite has expired');
    });

    it('rejects existing members who try to accept an invite again', async () => {
      const token = `member-accept-${testRunId}`;
      const inviteResult = await pool.query(
        `INSERT INTO workspace_invites (workspace_id, email, role, invited_by_user_id, token, expires_at)
         VALUES ($1, $2, 'member', $3, $4, now() + interval '7 days')
         RETURNING id`,
        [primaryWorkspaceId, memberEmail, superAdminUserId, token]
      );

      const anonymousCsrf = await createAnonymousCsrfContext();
      const response = await request(app)
        .post(`/api/invites/${token}/accept`)
        .set('Cookie', anonymousCsrf.cookie)
        .set('x-csrf-token', anonymousCsrf.token)
        .send({ password: 'valid-pass', name: 'Existing Member' });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('You are already a member of this workspace. Please log in instead.');

      const usedInvite = await pool.query(
        `SELECT used_at FROM workspace_invites WHERE id = $1`,
        [inviteResult.rows[0].id]
      );
      expect(usedInvite.rows[0]?.used_at).not.toBeNull();
    });

    it('rejects short passwords for new invite acceptance', async () => {
      const token = `short-password-${testRunId}`;
      await pool.query(
        `INSERT INTO workspace_invites (workspace_id, email, role, invited_by_user_id, token, expires_at)
         VALUES ($1, $2, 'member', $3, $4, now() + interval '7 days')`,
        [primaryWorkspaceId, `short-pass-${testRunId}@ship.local`, superAdminUserId, token]
      );

      const anonymousCsrf = await createAnonymousCsrfContext();
      const response = await request(app)
        .post(`/api/invites/${token}/accept`)
        .set('Cookie', anonymousCsrf.cookie)
        .set('x-csrf-token', anonymousCsrf.token)
        .send({ password: 'short', name: 'Short Password' });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('Password must be at least 8 characters');
    });
  });

  describe('admin route validation branches', () => {
    it('rejects empty workspace creation names', async () => {
      const response = await request(app)
        .post('/api/admin/workspaces')
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ name: '   ' });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('Workspace name is required');
    });

    it('rejects workspace updates with no fields', async () => {
      const response = await request(app)
        .patch(`/api/admin/workspaces/${primaryWorkspaceId}`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({});

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('At least one field (name or sprintStartDate) is required');
    });

    it('rejects invalid sprintStartDate formats on workspace update', async () => {
      const response = await request(app)
        .patch(`/api/admin/workspaces/${primaryWorkspaceId}`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ sprintStartDate: '03/12/2026' });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('sprintStartDate must be in YYYY-MM-DD format');
    });

    it('returns 404 when updating a missing workspace', async () => {
      const response = await request(app)
        .patch('/api/admin/workspaces/11111111-1111-4111-8111-111111111111')
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ name: 'Missing Workspace' });

      expect(response.status).toBe(404);
      expect(response.body.error.message).toBe('Workspace not found');
    });

    it('returns 404 when archiving a missing workspace', async () => {
      const response = await request(app)
        .post('/api/admin/workspaces/11111111-1111-4111-8111-111111111111/archive')
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken);

      expect(response.status).toBe(404);
      expect(response.body.error.message).toBe('Workspace not found or already archived');
    });

    it('returns an empty list for too-short admin user searches', async () => {
      const response = await request(app)
        .get('/api/admin/users/search?q=a')
        .set('Cookie', superAdminCookie);

      expect(response.status).toBe(200);
      expect(response.body.data.users).toEqual([]);
    });

    it('rejects invalid super-admin toggle payloads', async () => {
      const invalidPayload = await request(app)
        .patch(`/api/admin/users/${memberUserId}/super-admin`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ isSuperAdmin: 'yes' });

      expect(invalidPayload.status).toBe(400);
      expect(invalidPayload.body.error.message).toBe('isSuperAdmin must be a boolean');
    });

    it('prevents a super-admin from removing their own super-admin status', async () => {
      const response = await request(app)
        .patch(`/api/admin/users/${superAdminUserId}/super-admin`)
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ isSuperAdmin: false });

      expect(response.status).toBe(400);
      expect(response.body.error.message).toBe('Cannot remove your own super-admin status');
    });

    it('returns 404 when toggling super-admin on a missing user', async () => {
      const response = await request(app)
        .patch('/api/admin/users/11111111-1111-4111-8111-111111111111/super-admin')
        .set('Cookie', superAdminCookie)
        .set('x-csrf-token', superAdminCsrfToken)
        .send({ isSuperAdmin: true });

      expect(response.status).toBe(404);
      expect(response.body.error.message).toBe('User not found');
    });
  });
});
