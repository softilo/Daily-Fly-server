import { describe, expect, it, vi } from 'vitest';
import { of } from 'rxjs';
import { PublicCacheInterceptor } from './public-cache.interceptor.js';

describe('PublicCacheInterceptor', () => {
  const interceptor = new PublicCacheInterceptor();

  function runWithRequest(req: Record<string, unknown>) {
    const setHeader = vi.fn();
    const context = {
      switchToHttp: () => ({
        getRequest: () => req,
        getResponse: () => ({ setHeader }),
      }),
    } as any;

    interceptor.intercept(context, { handle: () => of('ok') });
    return setHeader;
  }

  it('sets edge cache headers for anonymous public requests', () => {
    const setHeader = runWithRequest({ headers: {}, cookies: {} });
    expect(setHeader).toHaveBeenCalledWith(
      'Cache-Control',
      'public, max-age=0, s-maxage=60, stale-while-revalidate=300',
    );
  });

  it('disables caching when Authorization header or access_token cookie is present', () => {
    const setHeaderBearer = runWithRequest({
      headers: { authorization: 'Bearer token' },
      cookies: {},
    });
    expect(setHeaderBearer).toHaveBeenCalledWith(
      'Cache-Control',
      'private, no-store',
    );

    const setHeaderCookie = runWithRequest({
      headers: {},
      cookies: { access_token: 'cookie-token' },
    });
    expect(setHeaderCookie).toHaveBeenCalledWith(
      'Cache-Control',
      'private, no-store',
    );
  });
});
