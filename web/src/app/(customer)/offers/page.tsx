'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { offersApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { formatPrice, timeAgo } from '@/lib/utils';
import { Clock, MapPin, Star } from 'lucide-react';
import type { Offer } from '@/lib/types';

export default function OffersPage() {
  const [offers, setOffers] = useState<Offer[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    offersApi.list({ limit: 50 })
      .then((data: unknown) => {
        const res = data as { offers: Offer[] };
        setOffers(res.offers || []);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-primary" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Nearby Offers</h1>
      {offers.length === 0 ? (
        <p className="text-center text-on-surface-variant py-12">No offers available right now.</p>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {offers.map(offer => (
            <Link key={offer.id} href={`/offers/${offer.id}`}>
              <Card className="hover:glow-crimson-sm transition-shadow">
                <CardContent className="p-4">
                  <div className="flex gap-4">
                    <div className="h-20 w-20 flex-shrink-0 rounded-lg bg-primary/15 flex items-center justify-center">
                      {offer.imageUrl ? (
                        <img src={offer.imageUrl} alt={offer.title} className="h-full w-full rounded-lg object-cover" />
                      ) : (
                        <Tag className="h-8 w-8 text-primary" />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="font-semibold truncate">{offer.title}</h3>
                      <p className="text-sm text-on-surface-variant truncate">{offer.store?.name}</p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-lg font-bold text-primary">{formatPrice(offer.discountedPrice)}</span>
                        <span className="text-sm text-on-surface-variant line-through">{formatPrice(offer.originalPrice)}</span>
                      </div>
                      <div className="flex items-center gap-2 mt-1 text-xs text-on-surface-variant">
                        <span>{offer.stockRemaining} left</span>
                        <Badge variant={offer.stockRemaining > 10 ? 'success' : 'danger'}>
                          {offer.stockRemaining > 10 ? 'Available' : 'Few left'}
                        </Badge>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

function Tag(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg {...props} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M12 2H2v10l9.29 9.29c.39.39 1.02.39 1.41 0l6.58-6.58c.39-.39.39-1.02 0-1.41L12 2z" />
      <circle cx="7" cy="7" r="1.5" fill="currentColor" />
    </svg>
  );
}
