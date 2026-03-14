/**
 * Returns session cookie options that work correctly in both local development
 * (same-origin, SameSite=strict) and production (cross-origin, SameSite=none + Secure).
 */
export function sessionCookieOptions(): {
  httpOnly: boolean;
  secure: boolean;
  sameSite: 'none' | 'strict';
  path: string;
} {
  const isProd = process.env.NODE_ENV === 'production';
  return {
    httpOnly: true,
    secure: isProd,
    sameSite: isProd ? 'none' : 'strict',
    path: '/',
  };
}
