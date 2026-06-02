'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { ordersApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { formatPrice, formatDate, formatTime } from '@/lib/utils';
import { ShoppingBag, Clock } from 'lucide-react';
import type { Order } from '@/lib/types';

const statusColors: Record<string, 'warning' | 'info' | 'success' | 'danger'> = {
  pending: 'warning', confirmed: 'info', preparing: 'info', ready: 'success', picked_up: 'success', cancelled: 'danger',
};

export default function AdminOrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    ordersApi.list({ limit: 50 })
      .then((data: unknown) => {
        const res = data as { orders: Order[] };
        setOrders(res.orders || []);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-primary" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">All Orders</h1>
      {orders.length === 0 ? (
        <div className="text-center py-12"><ShoppingBag className="h-12 w-12 text-on-surface-variant/50 mx-auto mb-3" /><p className="text-on-surface-variant">No orders found</p></div>
      ) : (
        <div className="space-y-3">
          {orders.map(order => (
            <Card key={order.id}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium">{order.orderNumber}</span>
                  <Badge variant={statusColors[order.status] || 'default'}>{order.status}</Badge>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <div>
                    <span className="text-on-surface-variant">{order.store?.name}</span>
                    <span className="text-on-surface-variant ml-2">{formatDate(order.createdAt)} at {formatTime(order.createdAt)}</span>
                  </div>
                  <span className="font-semibold">{formatPrice(order.totalAmount)}</span>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
