import { Request } from 'express';

/**
 * Request type for route handlers behind authMiddleware.
 * Auth middleware guarantees workspaceId and userId are set.
 * Use this instead of Request to avoid non-null assertions.
 */
export interface AuthenticatedRequest extends Request {
  workspaceId: string;
  userId: string;
}
