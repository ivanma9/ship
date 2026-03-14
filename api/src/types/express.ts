import { Request, RequestHandler, Response, NextFunction } from 'express';

/**
 * Request type for route handlers behind authMiddleware.
 * Auth middleware guarantees workspaceId and userId are set.
 * Use this instead of Request to avoid non-null assertions.
 */
export interface AuthenticatedRequest extends Request {
  workspaceId: string;
  userId: string;
}

/**
 * Cast an AuthenticatedRequest handler to a plain RequestHandler.
 * Required because Express's RequestHandler uses the global Request type
 * (workspaceId?: string) while AuthenticatedRequest narrows it to string.
 * The auth middleware guarantees workspaceId is set before the handler runs.
 */
export function authHandler(
  handler: (req: AuthenticatedRequest, res: Response, next: NextFunction) => Promise<void> | void
): RequestHandler {
  return (req, res, next) => handler(req as AuthenticatedRequest, res, next);
}
