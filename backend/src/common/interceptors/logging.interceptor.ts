import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';
import { Request, Response } from 'express';
import * as crypto from 'crypto';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const ctx = context.switchToHttp();
    const request = ctx.getRequest<Request>();
    const response = ctx.getResponse<Response>();
    const { method, url } = request;

    const requestId = request['requestId'] || crypto.randomUUID();
    const startTime = Date.now();

    return next.handle().pipe(
      tap(() => {
        const duration = Date.now() - startTime;
        const statusCode = response.statusCode;

        if (statusCode >= 500) {
          this.logger.error(`${method} ${url} ${statusCode} ${duration}ms [${requestId}]`);
        } else if (statusCode >= 400) {
          this.logger.warn(`${method} ${url} ${statusCode} ${duration}ms [${requestId}]`);
        } else {
          this.logger.log(`${method} ${url} ${statusCode} ${duration}ms [${requestId}]`);
        }
      }),
      catchError((err) => {
        const duration = Date.now() - startTime;
        this.logger.error(
          `${method} ${url} ${err.status || 500} ${duration}ms [${requestId}] — ${err.message}`,
        );
        throw err;
      }),
    );
  }
}
