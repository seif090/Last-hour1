import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import * as Sentry from '@sentry/node';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: any = 'Internal server error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      message = exception.getResponse();
    } else if (exception instanceof Error) {
      this.logger.error(
        `${request.method} ${request.url} — ${exception.message}`,
        exception.stack,
      );
    }

    if (status >= 500) {
      Sentry.withScope((scope) => {
        scope.setTag('method', request.method);
        scope.setExtra('url', request.url);
        scope.setExtra('body', request.body);
        scope.setExtra('requestId', request.requestId);
        Sentry.captureException(exception);
      });
    }

    response.status(status).json({
      success: false,
      error: {
        statusCode: status,
        message: typeof message === 'string' ? message : message.message || message,
        path: request.url,
        timestamp: new Date().toISOString(),
      },
    });
  }
}
