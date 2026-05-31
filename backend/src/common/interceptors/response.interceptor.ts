import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface SuccessResponse<T> {
  success: boolean;
  data: T;
  timestamp: string;
  requestId?: string;
}

@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<T, SuccessResponse<T>> {
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<SuccessResponse<T>> {
    const request = context.switchToHttp().getRequest();

    return next.handle().pipe(
      map((payload) => {
        // If controller already wraps in { success, data }, pass through
        if (payload && typeof payload === 'object' && 'success' in payload) {
          return {
            ...payload,
            timestamp: new Date().toISOString(),
            requestId: request.requestId,
          };
        }

        return {
          success: true,
          data: payload,
          timestamp: new Date().toISOString(),
          requestId: request.requestId,
        };
      }),
    );
  }
}
