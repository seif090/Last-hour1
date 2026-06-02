'use client';

import { useState, useEffect } from 'react';
import { offersApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { formatPrice, formatDate } from '@/lib/utils';
import { Tag, Clock } from 'lucide-react';
import type { Offer } from '@/lib/types';

export default function AdminOffersPage() {
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

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">All Offers</h1>
      {offers.length === 0 ? (
        <div className="text-center py-12"><Tag className="h-12 w-12 text-gray-300 mx-auto mb-3" /><p className="text-gray-500">No offers found</p></div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {offers.map(offer => (
            <Card key={offer.id}>
              <CardContent className="p-4">
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <h3 className="font-semibold">{offer.title}</h3>
                    <p className="text-sm text-gray-500">{offer.store?.name}</p>
                  </div>
                  <Badge variant={offer.status === 'active' ? 'success' : 'default'}>{offer.status}</Badge>
                </div>
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-lg font-bold text-orange-600">{formatPrice(offer.discountedPrice)}</span>
                  <span className="text-sm text-gray-400 line-through">{formatPrice(offer.originalPrice)}</span>
                </div>
                <div className="text-xs text-gray-400">
                  Stock: {offer.stockRemaining}/{offer.stockInitial} · Ends {formatDate(offer.endTime)}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
