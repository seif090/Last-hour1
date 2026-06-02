'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { ordersApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { formatPrice, formatDate, formatTime } from '@/lib/utils';
import { toast } from 'sonner';
import { ArrowLeft, Clock } from 'lucide-react';
import type { Order } from '@/lib/types';

export default function MerchantOrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [order, setOrder] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    ordersApi.get(id)
      .then((data: unknown) => setOrder(data as Order))
      .catch(() => { toast.error('Order not found'); router.push('/merchant/orders'); })
      .finally(() => setLoading(false));
  }, [id, router]);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-primary" /></div>;
  if (!order) return null;

  return (
    <div>
      <button onClick={() => router.back()} className="flex items-center gap-1 text-sm text-on-surface-variant hover:text-on-surface mb-4 cursor-pointer">
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <Card>
        <CardContent className="p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-xl font-bold">{order.orderNumber}</h1>
              <p className="text-sm text-on-surface-variant">{order.store?.name}</p>
            </div>
            <Badge className="text-sm px-3 py-1">{order.status}</Badge>
          </div>

          <div className="space-y-2 text-sm">
            <div className="flex justify-between"><span className="text-on-surface-variant">Date</span><span>{formatDate(order.createdAt)} at {formatTime(order.createdAt)}</span></div>
            <div className="flex justify-between"><span className="text-on-surface-variant">Quantity</span><span>{order.quantity}</span></div>
            <div className="flex justify-between"><span className="text-on-surface-variant">Unit Price</span><span>{formatPrice(order.unitPrice)}</span></div>
            <div className="flex justify-between"><span className="text-on-surface-variant">Subtotal</span><span>{formatPrice(order.subtotal)}</span></div>
            <div className="flex justify-between"><span className="text-on-surface-variant">Service Fee</span><span>{formatPrice(order.serviceFee)}</span></div>
            {order.discountAmount > 0 && (
              <div className="flex justify-between text-green-600"><span>Discount {order.couponCode ? `(${order.couponCode})` : ''}</span><span>-{formatPrice(order.discountAmount)}</span></div>
            )}
            <div className="flex justify-between font-bold text-lg pt-2 border-t"><span>Total</span><span>{formatPrice(order.totalAmount)}</span></div>
          </div>

          {order.items && order.items.length > 0 && (
            <div className="mt-6">
              <h3 className="font-semibold mb-2">Items</h3>
              {order.items.map(item => (
                <div key={item.id} className="flex justify-between text-sm py-1">
                  <span>{item.productName} × {item.quantity}</span>
                  <span>{formatPrice(item.subtotal)}</span>
                </div>
              ))}
            </div>
          )}

          {order.payment && (
            <div className="mt-6">
              <h3 className="font-semibold mb-2">Payment</h3>
              <div className="text-sm space-y-1">
                <div className="flex justify-between"><span className="text-on-surface-variant">Provider</span><span>{order.payment.provider}</span></div>
                <div className="flex justify-between"><span className="text-on-surface-variant">Status</span><Badge variant={order.payment.status === 'captured' ? 'success' : 'warning'}>{order.payment.status}</Badge></div>
                <div className="flex justify-between"><span className="text-on-surface-variant">Amount</span><span>{formatPrice(order.payment.amount)}</span></div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
