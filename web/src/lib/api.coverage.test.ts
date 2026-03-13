import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { __apiTestUtils, api, apiGet } from './api';

function jsonResponse(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

describe('api coverage helpers', () => {
  beforeEach(() => {
    __apiTestUtils.resetForTests();
    vi.stubGlobal('fetch', vi.fn());
    window.history.pushState({}, '', '/documents/test-doc');
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
    __apiTestUtils.resetForTests();
  });

  it('keeps public invite routes on-page when the server returns HTML', async () => {
    window.history.pushState({}, '', '/invite/token-123');
    vi.mocked(fetch).mockResolvedValue(
      new Response('<html>bad gateway</html>', {
        status: 502,
        headers: { 'content-type': 'text/html' },
      })
    );

    const result = await api.invites.validate('token-123');

    expect(result).toEqual({
      success: false,
      error: {
        code: 'NETWORK_ERROR',
        message: 'Server returned non-JSON response',
      },
    });
  });

  it('normalizes string-based API errors for state-changing requests', async () => {
    vi.mocked(fetch)
      .mockResolvedValueOnce(jsonResponse({ token: 'csrf-1' }))
      .mockResolvedValueOnce(jsonResponse({ error: 'Membership blocked' }, 400));

    const result = await api.workspaces.addMember('workspace-1', {
      email: 'person@example.com',
      role: 'member',
    });

    expect(result).toEqual({
      success: false,
      error: {
        code: 'HTTP_400',
        message: 'Membership blocked',
      },
    });
  });

  it('retries with a fresh CSRF token when the server rejects the cached one', async () => {
    const fetchMock = vi.mocked(fetch);
    fetchMock
      .mockResolvedValueOnce(jsonResponse({ token: 'csrf-1' }))
      .mockResolvedValueOnce(jsonResponse({ error: { code: 'CSRF_ERROR', message: 'expired' } }, 403))
      .mockResolvedValueOnce(jsonResponse({ token: 'csrf-2' }))
      .mockResolvedValueOnce(jsonResponse({ invite: { id: 'invite-1' } }));

    const result = await api.workspaces.createInvite('workspace-1', {
      email: 'person@example.com',
      role: 'member',
    });

    expect(result).toEqual({
      success: true,
      data: {
        invite: { id: 'invite-1' },
      },
    });
    const csrfCalls = fetchMock.mock.calls.filter(([url]) =>
      String(url).includes('/api/csrf-token')
    );
    const inviteCalls = fetchMock.mock.calls.filter(([url]) =>
      String(url).includes('/api/workspaces/workspace-1/invites')
    );
    expect(csrfCalls).toHaveLength(2);
    expect(inviteCalls).toHaveLength(2);
    expect(inviteCalls[0]?.[1]).toEqual(expect.objectContaining({
      method: 'POST',
      body: JSON.stringify({
        email: 'person@example.com',
        role: 'member',
      }),
    }));
    expect(inviteCalls[1]?.[1]).toEqual(expect.objectContaining({
      method: 'POST',
      headers: expect.objectContaining({
        'X-CSRF-Token': 'csrf-2',
      }),
    }));
  });

  it('builds member-list query strings and returns normalized success payloads', async () => {
    vi.mocked(fetch).mockResolvedValue(jsonResponse({
      members: [{ id: 'membership-1', email: 'person@example.com' }],
    }));

    const result = await api.workspaces.getMembers('workspace-1', {
      includeArchived: true,
    });

    expect(result).toEqual({
      success: true,
      data: {
        members: [{ id: 'membership-1', email: 'person@example.com' }],
      },
    });
    expect(String(vi.mocked(fetch).mock.calls[0]?.[0])).toContain(
      '/api/workspaces/workspace-1/members?includeArchived=true'
    );
    expect(vi.mocked(fetch).mock.calls[0]?.[1]).toEqual(expect.objectContaining({
      credentials: 'include',
    }));
  });

  it('throws a routing error when apiGet receives HTML with a 200 response', async () => {
    vi.mocked(fetch).mockResolvedValue(
      new Response('<html>index</html>', {
        status: 200,
        headers: { 'content-type': 'text/html' },
      })
    );

    await expect(apiGet('/api/documents/test-doc')).rejects.toThrow(
      'API returned HTML instead of JSON for /api/documents/test-doc. This may indicate a routing or CDN configuration issue.'
    );
  });
});
