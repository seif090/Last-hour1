'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { offersApi } from '@/lib/api';
import OfferCard from '@/components/offer-card';
import { ArrowRight, Clock, Tag, Zap } from 'lucide-react';
import type { Offer } from '@/lib/types';

export default function CustomerHome() {
  const [offers, setOffers] = useState<Offer[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    offersApi.list({ limit: 12 })
      .then((data: unknown) => {
        const res = data as { offers: Offer[] };
        setOffers(res.offers || []);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const featured = offers.filter(o => o.status === 'active').slice(0, 4);

  return (
    <div className="space-y-10 pb-8">
      {/* Hero */}
      <section className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-surface-container via-surface-container to-primary/10 border border-outline p-6 sm:p-8">
        <div className="relative z-10 space-y-4">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary/15 text-primary text-xs font-bold tracking-wider uppercase">
            <Zap className="h-3.5 w-3.5" />
            Last Minute Deals
          </div>
          <h1 className="text-3xl sm:text-4xl font-display font-black text-on-surface leading-tight">
            Surplus food,<br />
            <span className="text-primary">half the price</span>
          </h1>
          <p className="text-on-surface-variant max-w-md text-sm sm:text-base">
            Discover hidden gems from local restaurants selling their surplus at a fraction of the cost. Every meal saved fights waste.
          </p>
          <div className="flex flex-wrap gap-3">
            <Link href="/offers" className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-primary text-on-primary font-bold text-sm hover:brightness-110 transition-all">
              Browse Offers <ArrowRight className="h-4 w-4" />
            </Link>
            <Link href="/map" className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl border border-outline text-on-surface font-semibold text-sm hover:bg-surface-container-high transition-all">
              View Map
            </Link>
          </div>
        </div>
        <div className="absolute -bottom-6 -right-6 w-40 h-40 rounded-full bg-primary/10 blur-3xl" />
      </section>

      {/* Stats strip */}
      <div className="grid grid-cols-3 gap-4">
        {[{ icon: Tag, label: 'Active Offers', value: offers.filter(o => o.status === 'active').length },
          { icon: Clock, label: 'Avg Discount', value: '40%' },
          { icon: Zap, label: 'Saved Today', value: `${offers.length > 0 ? Math.floor(offers.reduce((s, o) => s + (o.originalPrice - o.discountedPrice), 0) / (offers.length || 1)) : 0} EGP` }
        ].map((stat, i) => (
          <div key={i} className="rounded-xl border border-outline bg-surface-container p-4 text-center space-y-1">
            <stat.icon className="h-5 w-5 mx-auto text-primary" />
            <p className="text-2xl font-display font-black text-on-surface">{stat.value}</p>
            <p className="text-xs text-on-surface-variant">{stat.label}</p>
          </div>
        ))}
      </div>

      {/* Featured offers */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-display font-bold text-on-surface">Featured Deals</h2>
          <Link href="/offers" className="text-sm text-primary font-semibold hover:underline inline-flex items-center gap-1">
            See all <ArrowRight className="h-3.5 w-3.5" />
          </Link>
        </div>

        {loading ? (
          <div className="grid gap-4 sm:grid-cols-2">
            {Array.from({ length: 4 }).map((_, i) => (
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
        ) : offers.length === 0 ? (
          <div className="text-center py-10 text-on-surface-variant">
            <p className="font-display font-semibold">No offers yet</p>
            <p className="text-sm">Check back soon for fresh deals near you</p>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2">
            {featured.map(offer => (
              <OfferCard key={offer.id} offer={offer} />
            ))}
          </div>
        )}
      </section>

      {/* CTA */}
      {offers.length > 0 && (
        <section className="rounded-2xl border border-outline bg-surface-container p-6 text-center space-y-3">
          <h2 className="text-xl font-display font-bold text-on-surface">Hungry for more?</h2>
          <p className="text-sm text-on-surface-variant max-w-sm mx-auto">
            Turn on location to find the best deals closest to you. Every day, new merchants join the fight against food waste.
          </p>
          <Link href="/map" className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-primary text-on-primary font-bold text-sm hover:brightness-110 transition-all">
            <Zap className="h-4 w-4" /> Explore Nearby
          </Link>
        </section>
      )}
    </div>
  );
}
