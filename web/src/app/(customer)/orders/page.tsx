'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { ordersApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { formatPrice, formatDate, formatTime } from '@/lib/utils';
import { Clock, Package } from 'lucide-react';
import type { Order } from '@/lib/types';

const statusColors: Record<string, 'warning' | 'info' | 'success' | 'danger'> = {
  pending: 'warning',
  confirmed: 'info',
  preparing: 'info',
  ready: 'success',
  picked_up: 'success',
  cancelled: 'danger',
};

export default function OrdersPage() {
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

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">My Orders</h1>
      {orders.length === 0 ? (
        <div className="text-center py-12">
          <Package className="h-12 w-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">No orders yet</p>
          <Link href="/offers" className="text-orange-600 hover:text-orange-700 text-sm font-medium">Browse offers</Link>
        </div>
      ) : (
        <div className="space-y-3">
          {orders.map(order => (
            <Link key={order.id} href={`/orders/${order.id}`}>
              <Card className="hover:shadow-md transition-shadow">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm font-medium">{order.orderNumber}</span>
                    <Badge variant={statusColors[order.status] || 'default'}>{order.status}</Badge>
                  </div>
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-gray-600">{order.store?.name}</p>
                      <p className="text-xs text-gray-400">{formatDate(order.createdAt)} at {formatTime(order.createdAt)}</p>
                    </div>
                    <span className="font-semibold">{formatPrice(order.totalAmount)}</span>
                  </div>
                  {order.discountAmount > 0 && (
                    <p className="text-xs text-green-600 mt-1">Coupon: -{formatPrice(order.discountAmount)}</p>
                  )}
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
