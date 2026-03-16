import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { __apiTestUtils, apiGet } from './api';

describe('api auth turbulence gating', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    __apiTestUtils.resetForTests();
    window.history.pushState({}, '', '/documents/test-doc');
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    __apiTestUtils.resetForTests();
  });

  it('retries transient 401s during reconnect turbulence before succeeding', async () => {
    __apiTestUtils.markAuthenticatedSuccessForTests();

    const fetchMock = vi.fn()
      .mockResolvedValueOnce(new Response(JSON.stringify({ error: { code: 'SESSION_EXPIRED', message: 'retry me' } }), {
        status: 401,
        headers: { 'content-type': 'application/json' },
      }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ error: { code: 'SESSION_EXPIRED', message: 'retry me' } }), {
        status: 401,
        headers: { 'content-type': 'application/json' },
      }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ id: 'doc-1', title: 'Recovered' }), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      }));

    vi.stubGlobal('fetch', fetchMock);

    const responsePromise = apiGet('/api/documents/test-doc');
    await vi.runAllTimersAsync();
    const response = await responsePromise;

    expect(response.status).toBe(200);
    expect(fetchMock).toHaveBeenCalledTimes(3);
  });

  it('falls through to session-expired handling after turbulence retries exhaust', async () => {
    __apiTestUtils.markAuthenticatedSuccessForTests();

    const fetchMock = vi.fn(() => Promise.resolve(new Response(JSON.stringify({
      error: { code: 'SESSION_EXPIRED', message: 'still failing' },
    }), {
      status: 401,
      headers: { 'content-type': 'application/json' },
    })));

    vi.stubGlobal('fetch', fetchMock);

    const settled = await (async () => {
      const responsePromise = apiGet('/api/documents/test-doc').catch(error => error);
      await vi.runAllTimersAsync();
      return responsePromise;
    })();

    expect(settled).toBeInstanceOf(Error);
    expect((settled as Error).message).toBe('Session expired - redirect pending');
    expect(fetchMock.mock.calls.length).toBeGreaterThanOrEqual(3);
  });
});
