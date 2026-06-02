import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
} from '@nestjs/websockets';
import { Logger, UseGuards } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { ConfigService } from '@nestjs/config';
import { WsAuthGuard } from '../auth/guards/ws-auth.guard';

@WebSocketGateway({
  path: '/ws',
  cors: { origin: '*', credentials: true },
  pingInterval: 30000,
  pingTimeout: 10000,
  transports: ['websocket', 'polling'],
})
export class OffersGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(OffersGateway.name);
  private readonly connections = new Map<string, Set<string>>();

  constructor(
    private config: ConfigService,
    private wsAuthGuard: WsAuthGuard,
  ) {}

  afterInit() {
    this.logger.log('WebSocket gateway initialized');
  }

  @UseGuards(WsAuthGuard)
  async handleConnection(client: Socket) {
    this.logger.log(`Client authenticated: ${client.id} (${client.data?.user?.role})`);
    this.connections.set(client.id, new Set());
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
    this.connections.delete(client.id);
  }

  @SubscribeMessage('subscribe')
  handleSubscribe(client: Socket, payload: { channel: string }) {
    const { channel } = payload;

    if (!channel) {
      client.emit('error', { code: 'INVALID_CHANNEL', message: 'Channel is required' });
      return;
    }

    client.join(channel);
    this.connections.get(client.id)?.add(channel);
    this.logger.log(`Client ${client.id} subscribed to ${channel}`);
  }

  @SubscribeMessage('unsubscribe')
  handleUnsubscribe(client: Socket, payload: { channel: string }) {
    const { channel } = payload;
    client.leave(channel);
    this.connections.get(client.id)?.delete(channel);
  }

  @SubscribeMessage('ping')
  handlePing(client: Socket) {
    client.emit('pong', { timestamp: Date.now() });
  }

  // ─── Broadcast Methods (called from services) ────────────────

  broadcastStockUpdate(offerId: string, storeId: string, remaining: number) {
    this.server.to(`offer:store:${storeId}`).emit('stock:update', {
      offer_id: offerId,
      stock_remaining: remaining,
      timestamp: Date.now(),
    });
  }

  broadcastOfferExpired(offerId: string, storeId: string) {
    this.server.to(`offer:store:${storeId}`).emit('offer:expired', {
      offer_id: offerId,
      timestamp: Date.now(),
    });
  }

  broadcastOfferSoldOut(offerId: string, storeId: string) {
    this.server.to(`offer:store:${storeId}`).emit('offer:sold_out', {
      offer_id: offerId,
      timestamp: Date.now(),
    });
  }

  broadcastOrderStatus(orderId: string, customerId: string, status: string, estimatedReadyAt?: Date) {
    this.server.to(`order:${orderId}`).emit('order:status', {
      order_id: orderId,
      status,
      estimated_ready_at: estimatedReadyAt?.toISOString(),
      timestamp: Date.now(),
    });
  }

  broadcastNewOffer(offer: Record<string, unknown>) {
    // Broadcast to all nearby customers based on store location
    // In production: use Redis pub/sub for horizontal scaling
    this.server.emit('offer:created', { offer });
  }
}
