export interface RequestError extends Error {
  status: number;
  code?: string;
  retryAfterSeconds?: number;
  currentTitle?: string;
  currentUpdatedAt?: string;
  attemptedTitle?: string;
}

export async function createRequestError(response: Response, fallbackMessage: string): Promise<RequestError> {
  let message = fallbackMessage;
  let code: string | undefined;

  const retryAfterHeader = response.headers.get('retry-after');
  const retryAfterSeconds = retryAfterHeader ? Number.parseInt(retryAfterHeader, 10) : undefined;

  if (response.headers.get('content-type')?.includes('application/json')) {
    try {
      const body = await response.json() as {
        message?: unknown;
        error?: unknown;
        success?: unknown;
      };

      if (typeof body.message === 'string') {
        message = body.message;
      }

      if (typeof body.error === 'string') {
        message = body.error;
      } else if (body.error && typeof body.error === 'object') {
        const nested = body.error as { message?: unknown; code?: unknown };
        if (typeof nested.message === 'string') {
          message = nested.message;
        }
        if (typeof nested.code === 'string') {
          code = nested.code;
        }
      }

      const conflictBody = body as {
        current_title?: unknown;
        current_updated_at?: unknown;
        attempted_title?: unknown;
      };

      const currentTitle = typeof conflictBody.current_title === 'string'
        ? conflictBody.current_title
        : undefined;
      const currentUpdatedAt = typeof conflictBody.current_updated_at === 'string'
        ? conflictBody.current_updated_at
        : undefined;
      const attemptedTitle = typeof conflictBody.attempted_title === 'string'
        ? conflictBody.attempted_title
        : undefined;

      const error = new Error(message) as RequestError;
      error.status = response.status;
      error.code = code;
      if (Number.isFinite(retryAfterSeconds)) {
        error.retryAfterSeconds = retryAfterSeconds;
      }
      error.currentTitle = currentTitle;
      error.currentUpdatedAt = currentUpdatedAt;
      error.attemptedTitle = attemptedTitle;
      return error;
    } catch {
      // Ignore parsing errors and keep fallback message.
    }
  }

  const error = new Error(message) as RequestError;
  error.status = response.status;
  error.code = code;
  if (Number.isFinite(retryAfterSeconds)) {
    error.retryAfterSeconds = retryAfterSeconds;
  }
  return error;
}
