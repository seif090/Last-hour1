'use client';

import { useState, useEffect, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { ordersApi, favoritesApi } from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { formatPrice, formatDate } from '@/lib/utils';
import { toast } from 'sonner';
import { Store as StoreIcon, Heart, ArrowLeft, Clock } from 'lucide-react';
import type { Offer } from '@/lib/types';

function LiveCountdown({ endTime }: { endTime: string }) {
  const [display, setDisplay] = useState('');
  const [ended, setEnded] = useState(false);

  useEffect(() => {
    function tick() {
      const ms = new Date(endTime).getTime() - Date.now();
      if (ms <= 0) { setDisplay('Ended'); setEnded(true); return; }
      const h = Math.floor(ms / 3600000);
      const m = Math.floor((ms % 3600000) / 60000);
      const s = Math.floor((ms % 60000) / 1000);
      setDisplay(h > 0 ? `${h}h ${m}m` : m > 0 ? `${m}m ${s}s` : `${s}s`);
    }
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, [endTime]);

  return (
    <span className={`inline-flex items-center gap-1 text-sm font-bold tabular-nums ${ended ? 'text-on-surface-variant' : 'text-primary'}`}>
      <Clock className="h-4 w-4" /> {display || 'Loading...'}
    </span>
  );
}

export default function OfferDetailClient({ offer }: { offer: Offer }) {
  const router = useRouter();
  const [quantity, setQuantity] = useState(1);
  const [couponCode, setCouponCode] = useState('');
  const [placing, setPlacing] = useState(false);

  const discount = Math.round((1 - offer.discountedPrice / offer.originalPrice) * 100);

  const handlePlaceOrder = async (e: FormEvent) => {
    e.preventDefault();
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
      await favoritesApi.add(offer.id);
      toast.success('Added to favorites');
    } catch {
      toast.error('Already in favorites');
    }
  };

  return (
    <div>
      <button onClick={() => router.back()} className="flex items-center gap-1 text-sm text-on-surface-variant hover:text-on-surface mb-4 cursor-pointer">
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2 space-y-4">
          <Card>
            {offer.imageUrl && (
              <div className="h-48 rounded-t-lg overflow-hidden bg-surface-container-high">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={offer.imageUrl} alt={offer.title} className="w-full h-full object-cover" loading="eager" />
              </div>
            )}
            <CardContent className="p-6">
              <div className="flex items-start justify-between">
                <div>
                  <h1 className="text-2xl font-display font-bold">{offer.title}</h1>
                  <Link href={`/stores/${offer.store.id}`} className="inline-flex items-center gap-1 text-primary hover:underline mt-1">
                    <StoreIcon className="h-4 w-4" /> {offer.store.name}
                  </Link>
                </div>
                <button onClick={handleToggleFavorite} className="text-on-surface-variant hover:text-primary cursor-pointer">
                  <Heart className="h-6 w-6" />
                </button>
              </div>

              <div className="flex items-center gap-3 mt-4">
                <span className="text-3xl font-display font-black text-primary">{formatPrice(offer.discountedPrice)}</span>
                <span className="text-lg text-on-surface-variant line-through">{formatPrice(offer.originalPrice)}</span>
                {discount >= 10 && <Badge variant="danger">-{discount}%</Badge>}
              </div>

              <div className="flex items-center gap-2 mt-3">
                <LiveCountdown endTime={offer.endTime} />
              </div>

              {offer.description && <p className="mt-4 text-on-surface-variant">{offer.description}</p>}

              <div className="flex flex-wrap gap-2 mt-4">
                {offer.product?.category && <Badge>{offer.product.category}</Badge>}
                <Badge variant="info">{offer.stockRemaining}/{offer.stockInitial} left</Badge>
                <Badge variant="warning">Ends {formatDate(offer.endTime)}</Badge>
              </div>
            </CardContent>
          </Card>
        </div>

        <div>
          <Card className="sticky top-20">
            <CardContent className="p-6">
              <h3 className="font-display font-semibold mb-4">Place Order</h3>
              <form onSubmit={handlePlaceOrder} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Quantity</label>
                  <div className="flex items-center gap-3">
                    <button type="button" onClick={() => setQuantity(Math.max(1, quantity - 1))} className="rounded-lg border border-outline px-3 py-1.5 text-lg cursor-pointer hover:bg-surface-container transition-colors">-</button>
                    <span className="text-xl font-semibold w-8 text-center tabular-nums">{quantity}</span>
                    <button type="button" onClick={() => setQuantity(Math.min(offer.maxPerCustomer, quantity + 1))} className="rounded-lg border border-outline px-3 py-1.5 text-lg cursor-pointer hover:bg-surface-container transition-colors">+</button>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-on-surface mb-1">Subtotal</label>
                  <p className="text-xl font-display font-bold">{formatPrice(offer.discountedPrice * quantity)}</p>
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
