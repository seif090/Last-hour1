import { CanActivate, ExecutionContext, Injectable, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { WsException } from '@nestjs/websockets';
import { Socket } from 'socket.io';

@Injectable()
export class WsAuthGuard implements CanActivate {
  private readonly logger = new Logger(WsAuthGuard.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const client: Socket = context.switchToWs().getClient();
    const token = this.extractToken(client);

    if (!token) {
      client.emit('error', { code: 'AUTH_REQUIRED', message: 'Authentication required' });
      client.disconnect();
      throw new WsException('Authentication required');
    }

    try {
      const payload = await this.jwtService.verifyAsync(token, {
        secret: this.config.get('JWT_SECRET'),
        issuer: this.config.get('JWT_ISSUER', 'lasthour.app'),
      });

      client.data.user = {
        id: payload.sub,
        email: payload.email,
        role: payload.role,
      };

      return true;
    } catch (err: any) {
      this.logger.warn(`WebSocket auth failed: ${err.message}`);
      client.emit('error', { code: 'INVALID_TOKEN', message: 'Invalid or expired token' });
      client.disconnect();
      throw new WsException('Invalid or expired token');
    }
  }

  private extractToken(client: Socket): string | null {
    // Check query param first (common for WebSocket connections)
    const queryToken = client.handshake.query?.token as string;
    if (queryToken) return queryToken;

    // Check auth header
    const authHeader = client.handshake.headers?.authorization as string;
    if (authHeader?.startsWith('Bearer ')) {
      return authHeader.slice(7);
    }

    return null;
  }
}
