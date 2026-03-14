// In development, Vite proxy handles /api routes (see vite.config.ts)
// In production, use VITE_API_URL or relative URLs
const API_URL = import.meta.env.VITE_API_URL ?? '';

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

// CSRF token cache for state-changing requests
let csrfToken: string | null = null;
const SESSION_REDIRECT_GRACE_MS = 1500;
const AUTH_RETRY_DELAY_MS = 300;
const AUTH_TURBULENCE_LOOKBACK_MS = 30_000;
const AUTH_TURBULENCE_WINDOW_MS = 4_000;
const AUTH_TURBULENCE_MAX_RETRIES = 3;
let pendingSessionRedirect: ReturnType<typeof setTimeout> | null = null;
let pendingSessionRedirectTarget: string | null = null;
let lastAuthenticatedSuccessAt = 0;
let authTurbulenceStartedAt: number | null = null;

// Helper: Check if response has JSON content type
function isJsonResponse(response: Response): boolean {
  const contentType = response.headers.get('content-type');
  return contentType?.includes('application/json') ?? false;
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function isPublicRoute(): boolean {
  return window.location.pathname.startsWith('/invite');
}

function shouldUseAuthTurbulence(endpoint: string): boolean {
  if (!navigator.onLine || isPublicRoute() || endpoint === '/api/auth/login') {
    return false;
  }

  if (authTurbulenceStartedAt !== null) {
    return true;
  }

  return Date.now() - lastAuthenticatedSuccessAt <= AUTH_TURBULENCE_LOOKBACK_MS;
}

function clearAuthTurbulence(): void {
  authTurbulenceStartedAt = null;
}

function recordAuthenticatedSuccess(): void {
  lastAuthenticatedSuccessAt = Date.now();
  clearAuthTurbulence();
  clearPendingSessionRedirect();
}

function isRecoverableAuthFailureResponse(response: Response): boolean {
  return response.status === 401 || (response.status === 403 && !isJsonResponse(response));
}

async function recoverAuthFailureResponse(
  endpoint: string,
  executeRequest: () => Promise<Response>,
  response: Response
): Promise<Response> {
  if (!isRecoverableAuthFailureResponse(response) || !shouldUseAuthTurbulence(endpoint)) {
    return response;
  }

  // UNAUTHORIZED means no session exists — retrying will never succeed, skip turbulence retries
  if (response.status === 401) {
    const code = await getResponseErrorCode(response);
    if (code === 'UNAUTHORIZED') {
      return response;
    }
  }

  if (authTurbulenceStartedAt === null) {
    authTurbulenceStartedAt = Date.now();
    console.warn(`[api] Deferring auth redirect during reconnect turbulence for ${endpoint}`);
  }

  let retryCount = 0;
  let currentResponse = response;

  while (
    retryCount < AUTH_TURBULENCE_MAX_RETRIES &&
    authTurbulenceStartedAt !== null &&
    Date.now() - authTurbulenceStartedAt < AUTH_TURBULENCE_WINDOW_MS
  ) {
    await sleep(AUTH_RETRY_DELAY_MS * (retryCount + 1));
    retryCount += 1;
    currentResponse = await executeRequest();

    if (!isRecoverableAuthFailureResponse(currentResponse)) {
      return currentResponse;
    }
  }

  return currentResponse;
}

/**
 * Read the error code from a 401/403 response without consuming the body.
 * Uses Response.clone() so the caller can still read the original response.
 */
async function getResponseErrorCode(res: Response): Promise<string | null> {
  try {
    const body = await res.clone().json();
    return (body?.error?.code as string) ?? null;
  } catch {
    return null;
  }
}

function clearPendingSessionRedirect(): void {
  if (pendingSessionRedirect) {
    clearTimeout(pendingSessionRedirect);
    pendingSessionRedirect = null;
    pendingSessionRedirectTarget = null;
  }
}

function normalizeApiResponse<T>(response: Response, payload: unknown): ApiResponse<T> {
  const defaultCode = response.status === 429 ? 'RATE_LIMITED' : `HTTP_${response.status}`;

  if (payload && typeof payload === 'object') {
    const body = payload as Record<string, unknown>;

    if (typeof body.success === 'boolean') {
      return body as unknown as ApiResponse<T>;
    }

    if (!response.ok) {
      if (typeof body.error === 'string') {
        return {
          success: false,
          error: { code: defaultCode, message: body.error },
        };
      }

      if (body.error && typeof body.error === 'object') {
        const nestedError = body.error as { code?: unknown; message?: unknown };
        return {
          success: false,
          error: {
            code: typeof nestedError.code === 'string' ? nestedError.code : defaultCode,
            message: typeof nestedError.message === 'string' ? nestedError.message : 'Request failed',
          },
        };
      }

      if (typeof body.message === 'string') {
        return {
          success: false,
          error: { code: defaultCode, message: body.message },
        };
      }

      return {
        success: false,
        error: { code: defaultCode, message: 'Request failed' },
      };
    }

    return {
      success: true,
      data: payload as T,
    };
  }

  if (!response.ok) {
    return {
      success: false,
      error: { code: defaultCode, message: 'Request failed' },
    };
  }

  return {
    success: true,
    data: payload as T,
  };
}

/**
 * Handle session expiration - redirect to login with expired=true flag
 *
 * IMPORTANT: Only call this for actual session expiration (SESSION_EXPIRED error code),
 * NOT for missing sessions (UNAUTHORIZED). Fresh visitors with no session should get
 * a clean redirect via ProtectedRoute without the "session expired" message.
 *
 * The expired=true flag triggers the yellow "session expired" modal on the login page.
 * Fresh visitors shouldn't see this - it would be confusing UX.
 *
 * Returns `never` because it always redirects or throws.
 */
function handleSessionExpired(): never {
  // Don't redirect to login when offline - let TanStack Query handle retries
  if (!navigator.onLine) {
    throw new Error('Network offline - request failed');
  }
  // Don't redirect on public routes like /invite - they work without authentication
  if (isPublicRoute()) {
    throw new Error('Session check failed - continuing on public route');
  }
  if (window.location.pathname !== '/login') {
    if (!pendingSessionRedirect) {
      const returnTo = encodeURIComponent(
        window.location.pathname + window.location.search + window.location.hash
      );
      pendingSessionRedirectTarget = `/login?expired=true&returnTo=${returnTo}`;
      pendingSessionRedirect = setTimeout(() => {
        const target = pendingSessionRedirectTarget;
        pendingSessionRedirect = null;
        pendingSessionRedirectTarget = null;
        if (target && navigator.onLine && window.location.pathname !== '/login') {
          window.location.href = target;
        }
      }, SESSION_REDIRECT_GRACE_MS);
    }
  }
  // Throw to satisfy TypeScript's `never` type (redirect is async and deferred).
  throw new Error('Session expired - redirect pending');
}

async function ensureCsrfToken(): Promise<string> {
  if (!csrfToken) {
    const executeRequest = () => fetch(`${API_URL}/api/csrf-token`, {
      credentials: 'include',
    });
    let response = await executeRequest();
    if (response.status === 401 || response.status === 403) {
      await sleep(AUTH_RETRY_DELAY_MS);
      response = await executeRequest();
    }
    response = await recoverAuthFailureResponse('/api/csrf-token', executeRequest, response);
    if (!response.ok || !isJsonResponse(response)) {
      // Session likely expired - redirect to login
      if (response.status === 401 || response.status === 403) {
        handleSessionExpired(); // never returns
      }
      throw new Error('Failed to get CSRF token');
    }
    const data = await response.json();
    csrfToken = data.token;
    recordAuthenticatedSuccess();
  }
  return csrfToken!;
}

// Clear CSRF token on logout or session change
export function clearCsrfToken(): void {
  csrfToken = null;
}

// Simple helpers that return Response objects (for contexts that need res.ok checks)
async function fetchWithCsrf(
  endpoint: string,
  method: 'POST' | 'PATCH' | 'DELETE',
  body?: object
): Promise<Response> {
  const token = await ensureCsrfToken();
  const executeRequest = (csrf: string) => fetch(`${API_URL}${endpoint}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrf,
    },
    credentials: 'include',
    body: body ? JSON.stringify(body) : undefined,
  });
  let res = await executeRequest(token);
  if (res.status === 401) {
    await sleep(AUTH_RETRY_DELAY_MS);
    res = await executeRequest(token);
  }
  res = await recoverAuthFailureResponse(endpoint, () => executeRequest(token), res);

  if (res.status === 401) {
    const code = await getResponseErrorCode(res);
    if (code !== 'UNAUTHORIZED') {
      handleSessionExpired(); // never returns
    }
    // UNAUTHORIZED: return as-is so callers can handle cleanly
  }

  const isJson = isJsonResponse(res);

  // CloudFront intercepts 403s and returns HTML - detect and redirect to login
  if (res.status === 403 && !isJson) {
    handleSessionExpired(); // never returns
  }

  // If CSRF token invalid (403 with JSON), retry once
  if (res.status === 403 && isJson) {
    clearCsrfToken();
    const newToken = await ensureCsrfToken();
    const retryResponse = await executeRequest(newToken);
    if (retryResponse.status === 401) {
      const retryCode = await getResponseErrorCode(retryResponse);
      if (retryCode !== 'UNAUTHORIZED') {
        handleSessionExpired(); // never returns
      }
    }
    if (retryResponse.ok) {
      recordAuthenticatedSuccess();
    }
    return retryResponse;
  }

  if (res.ok) {
    recordAuthenticatedSuccess();
  }
  return res;
}

export async function apiGet(endpoint: string): Promise<Response> {
  const executeRequest = () => fetch(`${API_URL}${endpoint}`, {
    credentials: 'include',
  });
  let res = await executeRequest();
  if (res.status === 401) {
    await sleep(AUTH_RETRY_DELAY_MS);
    res = await executeRequest();
  }
  res = await recoverAuthFailureResponse(endpoint, executeRequest, res);

  // Handle session expiration - redirect to login.
  // Don't treat UNAUTHORIZED (no session) as expiry — that's a fresh login with no prior session.
  if (res.status === 401) {
    const code = await getResponseErrorCode(res);
    if (code !== 'UNAUTHORIZED') {
      handleSessionExpired(); // never returns
    }
    // UNAUTHORIZED: return as-is; ProtectedRoute will redirect cleanly without "expired" message
  }

  // Check for non-JSON response (CloudFront HTML interception)
  // This can happen when:
  // 1. CDN serves HTML error page for non-existent routes
  // 2. Session expired and CloudFront returns login page
  // 3. Route misconfiguration serving index.html for API routes
  if (!isJsonResponse(res)) {
    // Non-200 + non-JSON = likely session issue (CloudFront 403 interception)
    if (res.status !== 200) {
      handleSessionExpired(); // never returns
    }
    // 200 + non-JSON = likely routing/CDN misconfiguration
    // Don't redirect to login (not a session issue), throw error for React Query to handle
    throw new Error(`API returned HTML instead of JSON for ${endpoint}. This may indicate a routing or CDN configuration issue.`);
  }

  if (res.ok) {
    recordAuthenticatedSuccess();
  }

  return res;
}

export async function apiPost(endpoint: string, body?: object): Promise<Response> {
  return fetchWithCsrf(endpoint, 'POST', body);
}

export async function apiPatch(endpoint: string, body: object): Promise<Response> {
  return fetchWithCsrf(endpoint, 'PATCH', body);
}

export async function apiDelete(endpoint: string, body?: object): Promise<Response> {
  return fetchWithCsrf(endpoint, 'DELETE', body);
}

async function request<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<ApiResponse<T>> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  // Add CSRF token for state-changing requests
  const method = options.method?.toUpperCase() || 'GET';
  if (['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
    const token = await ensureCsrfToken();
    headers['X-CSRF-Token'] = token;
  }

  const executeRequest = () => fetch(`${API_URL}${endpoint}`, {
    ...options,
    credentials: 'include',
    headers,
  });
  let response = await executeRequest();

  // Retry once on 401 for non-login endpoints to avoid reconnect redirect churn.
  if (response.status === 401 && endpoint !== '/api/auth/login') {
    await sleep(AUTH_RETRY_DELAY_MS);
    response = await executeRequest();
  }
  const turbulenceEligible = shouldUseAuthTurbulence(endpoint);
  response = await recoverAuthFailureResponse(endpoint, executeRequest, response);

  // CloudFront may intercept errors and return HTML - detect and redirect
  if (!isJsonResponse(response)) {
    // On public routes like /invite, return error response instead of redirecting
    if (window.location.pathname.startsWith('/invite')) {
      return {
        success: false,
        error: { code: 'NETWORK_ERROR', message: 'Server returned non-JSON response' },
      } as ApiResponse<T>;
    }
    handleSessionExpired(); // never returns
  }

  const payload = await response.json();
  const data = normalizeApiResponse<T>(response, payload);

  // Handle session expiration - redirect to login with expired=true
  // Only for SESSION_EXPIRED (actual expiration), not UNAUTHORIZED (no session existed)
  // Skip for public routes like /invite where 401 is expected for unauthenticated users
  if (response.status === 401) {
    const isSessionExpired = data.error?.code === 'SESSION_EXPIRED';
    // Don't treat UNAUTHORIZED as session expiry even in turbulence window —
    // a fresh login followed by an API call that legitimately returns UNAUTHORIZED
    // must not show "session timed out" to the user.
    const isUnauthorized = data.error?.code === 'UNAUTHORIZED';

    if ((isSessionExpired || (turbulenceEligible && !isUnauthorized)) &&
        !window.location.pathname.startsWith('/invite')) {
      handleSessionExpired(); // never returns - shows "session expired" message
    }
    // UNAUTHORIZED (no session) just returns error - ProtectedRoute will redirect without expired message
    return data;
  }

  // If CSRF token is invalid, clear and retry once
  if (response.status === 403 && data.error?.code === 'CSRF_ERROR') {
    clearCsrfToken();
    const newToken = await ensureCsrfToken();
    headers['X-CSRF-Token'] = newToken;
    const retryResponse = await fetch(`${API_URL}${endpoint}`, {
      ...options,
      credentials: 'include',
      headers,
    });
    if (!isJsonResponse(retryResponse)) {
      handleSessionExpired(); // never returns
    }
    const retryPayload = await retryResponse.json();
    const retryData = normalizeApiResponse<T>(retryResponse, retryPayload);
    if (retryResponse.ok) {
      recordAuthenticatedSuccess();
    }
    return retryData;
  }

  if (response.ok) {
    recordAuthenticatedSuccess();
  }

  return data;
}

export const __apiTestUtils = {
  resetForTests(): void {
    clearCsrfToken();
    clearPendingSessionRedirect();
    clearAuthTurbulence();
    lastAuthenticatedSuccessAt = 0;
  },
  markAuthenticatedSuccessForTests(): void {
    recordAuthenticatedSuccess();
  },
};

// Types for workspace management
export interface Workspace {
  id: string;
  name: string;
  archivedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface WorkspaceMembership {
  id: string;
  workspaceId: string;
  userId: string;
  role: 'admin' | 'member';
  personDocumentId: string | null;
  createdAt: string;
}

export interface WorkspaceInvite {
  id: string;
  workspaceId: string;
  email: string;
  x509SubjectDn: string | null;
  token: string;
  role: 'admin' | 'member';
  expiresAt: string;
  createdAt: string;
}

export interface AuditLog {
  id: string;
  workspaceId: string | null;
  actorUserId: string;
  actorName: string;
  actorEmail: string;
  impersonatingUserId: string | null;
  action: string;
  resourceType: string | null;
  resourceId: string | null;
  details: Record<string, unknown> | null;
  ipAddress: string | null;
  userAgent: string | null;
  createdAt: string;
}

export interface ApiToken {
  id: string;
  name: string;
  token_prefix: string;
  last_used_at: string | null;
  expires_at: string | null;
  is_active: boolean;
  revoked_at: string | null;
  created_at: string;
}

export interface ApiTokenCreateResponse extends ApiToken {
  token: string; // Full token - only returned on creation
  warning: string;
}

export interface WorkspaceMember {
  id: string;
  userId: string;
  email: string;
  name: string;
  role: 'admin' | 'member' | null;
  personDocumentId: string | null;
  joinedAt: string | null;
  isArchived?: boolean;
}

export interface UserInfo {
  id: string;
  email: string;
  name: string;
  isSuperAdmin: boolean;
}

// Accountability item returned by auth endpoints
export interface AccountabilityItem {
  id: string;
  title: string;
  accountability_type: 'standup' | 'weekly_plan' | 'weekly_review' | 'week_start' | 'week_issues' | 'project_plan' | 'project_retro';
  accountability_target_id: string;
  due_date: string | null;
  is_system_generated: boolean;
}

export interface LoginResponse {
  user: UserInfo;
  currentWorkspace: Workspace;
  workspaces: Array<Workspace & { role: 'admin' | 'member' }>;
  pendingAccountabilityItems?: AccountabilityItem[];
}

export interface MeResponse {
  user: UserInfo;
  currentWorkspace: Workspace | null;
  workspaces: Array<Workspace & { role: 'admin' | 'member' }>;
  impersonating?: {
    userId: string;
    userName: string;
  };
  pendingAccountabilityItems?: AccountabilityItem[];
}

export const api = {
  auth: {
    login: (email: string, password: string) =>
      request<LoginResponse>('/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      }),
    logout: () => {
      clearCsrfToken(); // Clear token on logout
      return request('/api/auth/logout', {
        method: 'POST',
      });
    },
    me: () => request<MeResponse>('/api/auth/me'),
  },

  workspaces: {
    // User-facing workspace operations
    list: () =>
      request<Array<Workspace & { role: 'admin' | 'member' }>>('/api/workspaces'),

    getCurrent: () =>
      request<Workspace>('/api/workspaces/current'),

    switch: (workspaceId: string) =>
      request<{ workspace: Workspace }>(`/api/workspaces/${workspaceId}/switch`, {
        method: 'POST',
      }),

    // Member management (workspace admin)
    getMembers: (workspaceId: string, options?: { includeArchived?: boolean }) => {
      const params = new URLSearchParams();
      if (options?.includeArchived) params.set('includeArchived', 'true');
      const query = params.toString();
      return request<{ members: WorkspaceMember[] }>(`/api/workspaces/${workspaceId}/members${query ? `?${query}` : ''}`);
    },

    addMember: (workspaceId: string, data: { userId?: string; email?: string; role: 'admin' | 'member' }) =>
      request<WorkspaceMembership>(`/api/workspaces/${workspaceId}/members`, {
        method: 'POST',
        body: JSON.stringify(data),
      }),

    updateMember: (workspaceId: string, userId: string, data: { role: 'admin' | 'member' }) =>
      request<WorkspaceMembership>(`/api/workspaces/${workspaceId}/members/${userId}`, {
        method: 'PATCH',
        body: JSON.stringify(data),
      }),

    removeMember: (workspaceId: string, userId: string) =>
      request(`/api/workspaces/${workspaceId}/members/${userId}`, {
        method: 'DELETE',
      }),

    restoreMember: (workspaceId: string, userId: string) =>
      request(`/api/workspaces/${workspaceId}/members/${userId}/restore`, {
        method: 'POST',
      }),

    // Invite management (workspace admin)
    getInvites: (workspaceId: string) =>
      request<{ invites: WorkspaceInvite[] }>(`/api/workspaces/${workspaceId}/invites`),

    createInvite: (workspaceId: string, data: { email: string; x509SubjectDn?: string; role?: 'admin' | 'member' }) =>
      request<{ invite: WorkspaceInvite }>(`/api/workspaces/${workspaceId}/invites`, {
        method: 'POST',
        body: JSON.stringify(data),
      }),

    revokeInvite: (workspaceId: string, inviteId: string) =>
      request(`/api/workspaces/${workspaceId}/invites/${inviteId}`, {
        method: 'DELETE',
      }),

    // Audit logs (workspace admin)
    getAuditLogs: (workspaceId: string, params?: { limit?: number; offset?: number }) =>
      request<{ logs: AuditLog[] }>(
        `/api/workspaces/${workspaceId}/audit-logs${params ? `?${new URLSearchParams(params as Record<string, string>)}` : ''}`
      ),
  },

  admin: {
    // Super-admin workspace management
    listWorkspaces: (includeArchived = false) =>
      request<{ workspaces: Array<Workspace & { memberCount: number }> }>(`/api/admin/workspaces?archived=${includeArchived}`),

    createWorkspace: (data: { name: string }) =>
      request<{ workspace: Workspace }>('/api/admin/workspaces', {
        method: 'POST',
        body: JSON.stringify(data),
      }),

    updateWorkspace: (workspaceId: string, data: { name?: string }) =>
      request<Workspace>(`/api/admin/workspaces/${workspaceId}`, {
        method: 'PATCH',
        body: JSON.stringify(data),
      }),

    archiveWorkspace: (workspaceId: string) =>
      request<Workspace>(`/api/admin/workspaces/${workspaceId}/archive`, {
        method: 'POST',
      }),

    // Super-admin workspace detail and member management
    getWorkspace: (workspaceId: string) =>
      request<{ workspace: Workspace & { sprintStartDate: string | null } }>(`/api/admin/workspaces/${workspaceId}`),

    getWorkspaceMembers: (workspaceId: string) =>
      request<{ members: Array<{ userId: string; email: string; name: string; role: 'admin' | 'member' }> }>(`/api/admin/workspaces/${workspaceId}/members`),

    getWorkspaceInvites: (workspaceId: string) =>
      request<{ invites: Array<{ id: string; email: string; x509SubjectDn: string | null; role: 'admin' | 'member'; token: string; createdAt: string }> }>(`/api/admin/workspaces/${workspaceId}/invites`),

    createWorkspaceInvite: (workspaceId: string, data: { email: string; x509SubjectDn?: string; role?: 'admin' | 'member' }) =>
      request<{ invite: { id: string; email: string; x509SubjectDn: string | null; role: 'admin' | 'member'; token: string; createdAt: string } }>(`/api/admin/workspaces/${workspaceId}/invites`, {
        method: 'POST',
        body: JSON.stringify(data),
      }),

    revokeWorkspaceInvite: (workspaceId: string, inviteId: string) =>
      request(`/api/admin/workspaces/${workspaceId}/invites/${inviteId}`, {
        method: 'DELETE',
      }),

    updateWorkspaceMember: (workspaceId: string, userId: string, data: { role: 'admin' | 'member' }) =>
      request<{ role: 'admin' | 'member' }>(`/api/admin/workspaces/${workspaceId}/members/${userId}`, {
        method: 'PATCH',
        body: JSON.stringify(data),
      }),

    removeWorkspaceMember: (workspaceId: string, userId: string) =>
      request(`/api/admin/workspaces/${workspaceId}/members/${userId}`, {
        method: 'DELETE',
      }),

    addWorkspaceMember: (workspaceId: string, data: { userId: string; role?: 'admin' | 'member' }) =>
      request<{ member: { userId: string; email: string; name: string; role: 'admin' | 'member' } }>(`/api/admin/workspaces/${workspaceId}/members`, {
        method: 'POST',
        body: JSON.stringify(data),
      }),

    // User search (for adding existing users to workspace)
    searchUsers: (query: string, workspaceId?: string) =>
      request<{ users: Array<{ id: string; email: string; name: string }> }>(
        `/api/admin/users/search?q=${encodeURIComponent(query)}${workspaceId ? `&workspaceId=${workspaceId}` : ''}`
      ),

    // Super-admin user management
    listUsers: () =>
      request<{ users: Array<UserInfo & { workspaces: Array<{ id: string; name: string; role: 'admin' | 'member' }> }> }>('/api/admin/users'),

    toggleSuperAdmin: (userId: string, isSuperAdmin: boolean) =>
      request<UserInfo>(`/api/admin/users/${userId}/super-admin`, {
        method: 'PATCH',
        body: JSON.stringify({ isSuperAdmin }),
      }),

    // Audit logs (super-admin)
    getAuditLogs: (params?: { workspaceId?: string; userId?: string; action?: string; limit?: number; offset?: number }) =>
      request<{ logs: AuditLog[] }>(`/api/admin/audit-logs${params ? `?${new URLSearchParams(params as Record<string, string>)}` : ''}`),

    exportAuditLogs: (params?: { workspaceId?: string; userId?: string; action?: string; from?: string; to?: string }) =>
      `${API_URL}/api/admin/audit-logs/export${params ? `?${new URLSearchParams(params as Record<string, string>)}` : ''}`,

    // Impersonation
    startImpersonation: (userId: string) =>
      request<{ originalUserId: string; impersonating: { userId: string; userName: string } }>(`/api/admin/impersonate/${userId}`, {
        method: 'POST',
      }),

    endImpersonation: () =>
      request('/api/admin/impersonate', {
        method: 'DELETE',
      }),
  },

  invites: {
    // Public invite operations
    validate: (token: string) =>
      request<{ email: string; workspaceName: string; invitedBy: string; role: 'admin' | 'member'; userExists: boolean; alreadyMember?: boolean }>(`/api/invites/${token}`),

    accept: (token: string, data?: { password?: string; name?: string }) =>
      request<LoginResponse>(`/api/invites/${token}/accept`, {
        method: 'POST',
        body: JSON.stringify(data || {}),
      }),
  },

  apiTokens: {
    list: () =>
      request<ApiToken[]>('/api/api-tokens'),

    create: (data: { name: string; expires_in_days?: number }) =>
      request<ApiTokenCreateResponse>('/api/api-tokens', {
        method: 'POST',
        body: JSON.stringify(data),
      }),

    revoke: (tokenId: string) =>
      request('/api/api-tokens/' + tokenId, {
        method: 'DELETE',
      }),
  },
};
