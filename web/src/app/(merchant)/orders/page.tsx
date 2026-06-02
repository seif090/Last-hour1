'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { merchantApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { formatPrice, formatDate, formatTime } from '@/lib/utils';
import { ShoppingBag, Clock } from 'lucide-react';
import { toast } from 'sonner';
import type { Order } from '@/lib/types';

const statusColors: Record<string, 'warning' | 'info' | 'success' | 'danger'> = {
  pending: 'warning',
  confirmed: 'info',
  preparing: 'info',
  ready: 'success',
  picked_up: 'success',
  cancelled: 'danger',
};

export default function MerchantOrdersPage() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('');

  const loadOrders = (status?: string) => {
    setLoading(true);
    merchantApi.listOrders({ status, limit: 50 })
      .then((data: unknown) => {
        const res = data as { orders: Order[] };
        setOrders(res.orders || []);
      })
      .catch(() => toast.error('Failed to load orders'))
      .finally(() => setLoading(false));
  };

  useEffect(() => { loadOrders(); }, []);

  const handleFilter = (status: string) => {
    setStatusFilter(status);
    loadOrders(status || undefined);
  };

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-primary" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Orders</h1>

      <div className="flex flex-wrap gap-2 mb-6">
        {['', 'pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'cancelled'].map(s => (
          <button key={s} onClick={() => handleFilter(s)} className={`rounded-full px-3 py-1 text-xs font-medium transition-colors cursor-pointer ${statusFilter === s ? 'bg-primary text-white' : 'bg-gray-100 text-on-surface-variant hover:bg-gray-200'}`}>
            {s || 'All'}
          </button>
        ))}
      </div>

      {orders.length === 0 ? (
        <div className="text-center py-12">
          <ShoppingBag className="h-12 w-12 text-on-surface-variant/50 mx-auto mb-3" />
          <p className="text-on-surface-variant">No orders found</p>
        </div>
      ) : (
        <div className="space-y-3">
          {orders.map(order => (
            <Link key={order.id} href={`/merchant/orders/${order.id}`}>
              <Card className="hover:glow-crimson-sm transition-shadow">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm font-medium">{order.orderNumber}</span>
                    <Badge variant={statusColors[order.status] || 'default'}>{order.status}</Badge>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-on-surface-variant">{formatDate(order.createdAt)} at {formatTime(order.createdAt)}</span>
                    <span className="font-semibold">{formatPrice(order.totalAmount)}</span>
                  </div>
                  {order.couponCode && <p className="text-xs text-green-600 mt-1">Coupon: {order.couponCode}</p>}
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
