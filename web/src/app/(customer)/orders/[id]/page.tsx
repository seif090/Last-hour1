'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { ordersApi, reviewsApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { formatPrice, formatDate, formatTime } from '@/lib/utils';
import { toast } from 'sonner';
import { ArrowLeft, Star, Clock } from 'lucide-react';
import type { Order } from '@/lib/types';

const statusColors: Record<string, 'warning' | 'info' | 'success' | 'danger'> = {
  pending: 'warning',
  confirmed: 'info',
  preparing: 'info',
  ready: 'success',
  picked_up: 'success',
  cancelled: 'danger',
};

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [order, setOrder] = useState<Order | null>(null);
  const [loading, setLoading] = useState(true);
  const [rating, setRating] = useState(0);
  const [comment, setComment] = useState('');
  const [reviewing, setReviewing] = useState(false);

  useEffect(() => {
    ordersApi.get(id)
      .then((data: unknown) => setOrder(data as Order))
      .catch(() => { toast.error('Order not found'); router.push('/orders'); })
      .finally(() => setLoading(false));
  }, [id, router]);

  const handleConfirmPickup = async () => {
    try {
      await ordersApi.confirmPickup(id);
      toast.success('Pickup confirmed!');
      setOrder(prev => prev ? { ...prev, status: 'picked_up' } : null);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Failed to confirm pickup');
    }
  };

  const handleCancel = async () => {
    try {
      await ordersApi.cancel(id, 'Cancelled by customer');
      toast.success('Order cancelled');
      setOrder(prev => prev ? { ...prev, status: 'cancelled' } : null);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Failed to cancel');
    }
  };

  const handleSubmitReview = async () => {
    if (rating === 0) { toast.error('Please select a rating'); return; }
    setReviewing(true);
    try {
      await reviewsApi.create({ orderId: id, rating, comment: comment || undefined });
      toast.success('Review submitted!');
      setRating(0);
      setComment('');
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Failed to submit review');
    } finally {
      setReviewing(false);
    }
  };

  const handleReorder = () => {
    if (order?.offer?.id) router.push(`/offers/${order.offer.id}`);
  };

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;
  if (!order) return null;

  return (
    <div>
      <button onClick={() => router.back()} className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-4 cursor-pointer">
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <Card className="mb-6">
        <CardContent className="p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-xl font-bold">{order.orderNumber}</h1>
              <p className="text-sm text-gray-500">{order.store?.name}</p>
            </div>
            <Badge variant={statusColors[order.status] || 'default'} className="text-sm px-3 py-1">{order.status}</Badge>
          </div>

          <div className="space-y-2 text-sm">
            <div className="flex justify-between"><span className="text-gray-500">Date</span><span>{formatDate(order.createdAt)} at {formatTime(order.createdAt)}</span></div>
            <div className="flex justify-between"><span className="text-gray-500">Quantity</span><span>{order.quantity}</span></div>
            <div className="flex justify-between"><span className="text-gray-500">Unit Price</span><span>{formatPrice(order.unitPrice)}</span></div>
            <div className="flex justify-between"><span className="text-gray-500">Subtotal</span><span>{formatPrice(order.subtotal)}</span></div>
            <div className="flex justify-between"><span className="text-gray-500">Service Fee</span><span>{formatPrice(order.serviceFee)}</span></div>
            {order.discountAmount > 0 && (
              <div className="flex justify-between text-green-600"><span>Discount {order.couponCode ? `(${order.couponCode})` : ''}</span><span>-{formatPrice(order.discountAmount)}</span></div>
            )}
            <div className="flex justify-between font-bold text-lg pt-2 border-t"><span>Total</span><span>{formatPrice(order.totalAmount)}</span></div>
          </div>

          <div className="flex gap-2 mt-6">
            {order.status === 'ready' && <Button onClick={handleConfirmPickup}>Confirm Pickup</Button>}
            {(order.status === 'pending' || order.status === 'confirmed') && <Button variant="danger" onClick={handleCancel}>Cancel Order</Button>}
            {(order.status === 'picked_up' || order.status === 'cancelled') && <Button variant="outline" onClick={handleReorder}>Reorder</Button>}
          </div>
        </CardContent>
      </Card>

      {order.status === 'picked_up' && (
        <Card>
          <CardContent className="p-6">
            <h3 className="font-semibold mb-4">Leave a Review</h3>
            <div className="flex items-center gap-1 mb-3">
              {Array.from({ length: 5 }, (_, i) => (
                <button key={i} type="button" onClick={() => setRating(i + 1)} className="cursor-pointer">
                  <Star className={`h-6 w-6 ${i < rating ? 'text-yellow-500 fill-yellow-500' : 'text-gray-300'}`} />
                </button>
              ))}
            </div>
            <Input placeholder="Comment (optional)" value={comment} onChange={e => setComment(e.target.value)} />
            <Button onClick={handleSubmitReview} loading={reviewing} className="mt-3">Submit Review</Button>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
