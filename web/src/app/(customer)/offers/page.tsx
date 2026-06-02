'use client';

import { useState, useEffect } from 'react';
import { offersApi } from '@/lib/api';
import OfferCard from '@/components/offer-card';
import { SearchX } from 'lucide-react';
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

  if (loading) return (
    <div className="grid gap-4 sm:grid-cols-2">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="rounded-lg border border-outline bg-surface-container overflow-hidden animate-pulse">
          <div className="h-32 bg-surface-container-high" />
          <div className="p-3 space-y-2">
            <div className="h-4 w-3/4 rounded bg-surface-dim" />
            <div className="h-3 w-1/2 rounded bg-surface-dim" />
            <div className="h-1.5 w-full rounded bg-surface-dim" />
            <div className="h-3 w-1/3 rounded bg-surface-dim" />
          </div>
        </div>
      ))}
    </div>
  );

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-display font-bold">Nearby Offers</h1>
        <span className="text-sm text-on-surface-variant">{offers.length} available</span>
      </div>

      {offers.length === 0 ? (
        <div className="flex flex-col items-center gap-3 py-16 text-on-surface-variant">
          <SearchX className="h-12 w-12" />
          <p className="text-lg font-display font-semibold">No offers right now</p>
          <p className="text-sm">Check back later for fresh deals</p>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {offers.map(offer => (
            <OfferCard key={offer.id} offer={offer} />
          ))}
        </div>
      )}
    </div>
  );
}
