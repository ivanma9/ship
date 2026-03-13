import { describe, expect, it } from 'vitest';
import { createRequestError } from './http-error';

describe('createRequestError', () => {
  it('captures WRITE_CONFLICT metadata from JSON responses', async () => {
    const response = new Response(JSON.stringify({
      error: {
        code: 'WRITE_CONFLICT',
        message: 'Conflict detected',
      },
      current_title: 'Server Title',
      current_updated_at: '2026-03-11T19:14:22.123Z',
      attempted_title: 'Local Title',
    }), {
      status: 409,
      headers: {
        'content-type': 'application/json',
      },
    });

    const error = await createRequestError(response, 'Fallback message');

    expect(error.status).toBe(409);
    expect(error.code).toBe('WRITE_CONFLICT');
    expect(error.message).toBe('Conflict detected');
    expect(error.currentTitle).toBe('Server Title');
    expect(error.currentUpdatedAt).toBe('2026-03-11T19:14:22.123Z');
    expect(error.attemptedTitle).toBe('Local Title');
  });
});
