'use client';

import { useState, useEffect, FormEvent } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { offersApi, ordersApi, favoritesApi } from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { formatPrice, formatDate } from '@/lib/utils';
import { toast } from 'sonner';
import { Clock, Store, Heart, ArrowLeft } from 'lucide-react';
import type { Offer } from '@/lib/types';

export default function OfferDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [offer, setOffer] = useState<Offer | null>(null);
  const [quantity, setQuantity] = useState(1);
  const [couponCode, setCouponCode] = useState('');
  const [loading, setLoading] = useState(true);
  const [placing, setPlacing] = useState(false);

  useEffect(() => {
    offersApi.get(id)
      .then((data: unknown) => setOffer(data as Offer))
      .catch(() => { toast.error('Offer not found'); router.push('/offers'); })
      .finally(() => setLoading(false));
  }, [id, router]);

  const handlePlaceOrder = async (e: FormEvent) => {
    e.preventDefault();
    if (!offer) return;
    if (quantity > offer.maxPerCustomer) { toast.error(`Max ${offer.maxPerCustomer} per customer`); return; }
    setPlacing(true);
    try {
      await ordersApi.place({ offerId: offer.id, quantity, payment: { provider: 'stripe' }, couponCode: couponCode || undefined });
      toast.success('Order placed!');
      router.push('/orders');
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Failed to place order');
    } finally {
      setPlacing(false);
    }
  };

  const handleToggleFavorite = async () => {
    try {
      await favoritesApi.add(id);
      toast.success('Added to favorites');
    } catch {
      toast.error('Already in favorites');
    }
  };

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;
  if (!offer) return null;

  const discount = Math.round((1 - offer.discountedPrice / offer.originalPrice) * 100);

  return (
    <div>
      <button onClick={() => router.back()} className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-4 cursor-pointer">
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2 space-y-4">
          <Card>
            <CardContent className="p-6">
              <div className="flex items-start justify-between">
                <div>
                  <h1 className="text-2xl font-bold">{offer.title}</h1>
                  <Link href={`/stores/${offer.store.id}`} className="flex items-center gap-1 text-orange-600 hover:text-orange-700 mt-1">
                    <Store className="h-4 w-4" /> {offer.store.name}
                  </Link>
                </div>
                <button onClick={handleToggleFavorite} className="text-gray-400 hover:text-red-500 cursor-pointer">
                  <Heart className="h-6 w-6" />
                </button>
              </div>

              <div className="flex items-center gap-3 mt-4">
                <span className="text-3xl font-bold text-orange-600">{formatPrice(offer.discountedPrice)}</span>
                <span className="text-lg text-gray-400 line-through">{formatPrice(offer.originalPrice)}</span>
                <Badge variant="danger">-{discount}%</Badge>
              </div>

              {offer.description && <p className="mt-4 text-gray-600">{offer.description}</p>}

              <div className="flex flex-wrap gap-2 mt-4">
                <Badge>{offer.product?.category}</Badge>
                <Badge variant="info">{offer.stockRemaining} of {offer.stockInitial} left</Badge>
                <Badge variant="warning">Expires {formatDate(offer.endTime)}</Badge>
              </div>
            </CardContent>
          </Card>
        </div>

        <div>
          <Card className="sticky top-20">
            <CardContent className="p-6">
              <h3 className="font-semibold mb-4">Place Order</h3>
              <form onSubmit={handlePlaceOrder} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Quantity</label>
                  <div className="flex items-center gap-3">
                    <button type="button" onClick={() => setQuantity(Math.max(1, quantity - 1))} className="rounded-lg border px-3 py-1.5 text-lg cursor-pointer hover:bg-gray-50">-</button>
                    <span className="text-xl font-semibold w-8 text-center">{quantity}</span>
                    <button type="button" onClick={() => setQuantity(Math.min(offer.maxPerCustomer, quantity + 1))} className="rounded-lg border px-3 py-1.5 text-lg cursor-pointer hover:bg-gray-50">+</button>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Subtotal</label>
                  <p className="text-xl font-bold">{formatPrice(offer.discountedPrice * quantity)}</p>
                </div>

                <Input label="Coupon Code (optional)" value={couponCode} onChange={e => setCouponCode(e.target.value)} placeholder="Enter code" />

                <Button type="submit" loading={placing} className="w-full">Place Order</Button>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
