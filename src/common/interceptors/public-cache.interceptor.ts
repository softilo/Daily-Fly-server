import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import type { Observable } from 'rxjs';

/**
 * Enables edge CDN caching on public catalog GET endpoints for anonymous visitors
 * while keeping authenticated staff requests uncached so admin mutations appear immediately.
 */
@Injectable()
export class PublicCacheInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const http = context.switchToHttp();
    const req = http.getRequest<Request>();
    const res = http.getResponse<Response>();

    const hasAuth =
      Boolean(req.headers.authorization) ||
      Boolean(req.cookies?.['access_token']);

    res.setHeader(
      'Cache-Control',
      hasAuth
        ? 'private, no-store'
        : 'public, max-age=0, s-maxage=60, stale-while-revalidate=300',
    );

    return next.handle();
  }
}
