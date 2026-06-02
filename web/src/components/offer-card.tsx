'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { cn, formatPrice } from '@/lib/utils';
import { Heart, MapPin, Clock } from 'lucide-react';
import type { Offer } from '@/lib/types';

function Countdown({ endTime, className }: { endTime: string; className?: string }) {
  const [rem, setRem] = useState('');
  const [urgent, setUrgent] = useState(false);

  useEffect(() => {
    function tick() {
      const ms = new Date(endTime).getTime() - Date.now();
      if (ms <= 0) { setRem('Ended'); setUrgent(false); return; }
      setUrgent(ms < 60000);
      const h = Math.floor(ms / 3600000);
      const m = Math.floor((ms % 3600000) / 60000);
      const s = Math.floor((ms % 60000) / 1000);
      if (h > 0) setRem(`${h}h ${m}m`);
      else if (m > 0) setRem(`${m}m ${s}s`);
      else setRem(`${s}s`);
    }
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, [endTime]);

  return (
    <span className={cn('inline-flex items-center gap-1 text-xs font-bold tabular-nums', urgent ? 'text-primary' : 'text-on-surface-variant', className)}>
      <Clock className="h-3 w-3" /> {rem}
    </span>
  );
}

function InventoryBar({ current, max }: { current: number; max: number }) {
  const pct = max > 0 ? Math.round((current / max) * 100) : 0;
  const low = pct < 10;
  return (
    <div className="h-1.5 w-full rounded-full bg-surface-dim overflow-hidden">
      <div
        className={cn('h-full rounded-full transition-all duration-500', low ? 'bg-primary shimmer' : 'bg-primary/70')}
        style={{ width: `${Math.min(pct, 100)}%` }}
      />
    </div>
  );
}

interface OfferCardProps {
  offer: Offer;
  isFavorited?: boolean;
  onToggleFavorite?: (id: string) => void;
}

export default function OfferCard({ offer, isFavorited, onToggleFavorite }: OfferCardProps) {
  const discount = offer.originalPrice > 0
    ? Math.round((1 - offer.discountedPrice / offer.originalPrice) * 100)
    : 0;
  const active = offer.status === 'active';

  return (
    <Link href={`/offers/${offer.id}`} className="group">
      <div className="rounded-lg border border-outline bg-surface-container overflow-hidden transition-all duration-200 hover:glow-crimson-sm">
        <div className="relative h-32 bg-surface-container-high flex items-center justify-center overflow-hidden">
          {offer.imageUrl && (
            /* eslint-disable-next-line @next/next/no-img-element */
            <img src={offer.imageUrl} alt="" className="absolute inset-0 w-full h-full object-cover" loading="lazy" />
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-surface-container/80 to-transparent" />

          <div className="absolute top-2 left-2 flex gap-1">
            {active && (
              <span className="px-2 py-0.5 text-[10px] font-bold tracking-wider uppercase rounded-full bg-primary/15 text-primary flex items-center gap-1">
                <span className="relative flex h-1.5 w-1.5">
                  <span className="absolute inline-flex h-full w-full rounded-full bg-primary opacity-75 animate-ping" />
                  <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-primary" />
                </span>
                Live
              </span>
            )}
            {discount >= 20 && <span className="px-2 py-0.5 text-[10px] font-bold tracking-wider uppercase rounded-full bg-error/20 text-error">{discount}% OFF</span>}
          </div>

          <div className="absolute bottom-2 left-2 flex items-baseline gap-1.5">
            <span className="text-xl font-display font-black text-on-surface">{formatPrice(offer.discountedPrice)}</span>
            {offer.originalPrice > offer.discountedPrice && (
              <span className="text-xs text-on-surface-variant line-through">{formatPrice(offer.originalPrice)}</span>
            )}
          </div>
        </div>

        <div className="p-3 space-y-2">
          <h3 className="font-display font-bold text-sm text-on-surface truncate">{offer.title}</h3>

          <div className="flex items-center gap-2 text-xs text-on-surface-variant">
            <MapPin className="h-3 w-3 shrink-0" />
            <span className="truncate">{offer.store?.name}</span>
          </div>

          <div className="flex items-center justify-between gap-2">
            <InventoryBar current={offer.stockRemaining} max={offer.stockInitial} />
            <span className={cn('text-[10px] font-bold tabular-nums shrink-0', offer.stockRemaining < 10 ? 'text-primary' : 'text-on-surface-variant')}>
              {offer.stockRemaining}/{offer.stockInitial}
            </span>
          </div>

          <div className="flex items-center justify-between">
            <Countdown endTime={offer.endTime} />
            <button
              onClick={e => { e.preventDefault(); e.stopPropagation(); onToggleFavorite?.(offer.id); }}
              className="cursor-pointer"
            >
              <Heart className={cn('h-4 w-4 transition-colors', isFavorited ? 'text-primary fill-primary' : 'text-on-surface-variant hover:text-primary')} />
            </button>
          </div>
        </div>
      </div>
    </Link>
  );
}
