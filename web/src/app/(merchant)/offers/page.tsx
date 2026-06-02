'use client';

import { useState, useEffect } from 'react';
import { merchantApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { formatPrice, formatDate } from '@/lib/utils';
import { Tag, Clock, Plus } from 'lucide-react';
import { toast } from 'sonner';
interface MerchantOffer {
  id: string;
  title: string;
  description?: string;
  discountedPrice: number;
  originalPrice: number;
  stockRemaining: number;
  stockInitial: number;
  status: string;
  endTime: string;
  store: { id: string; name: string };
  product?: { id: string; name: string; category: string };
}

export default function MerchantOffersPage() {
  const [offers, setOffers] = useState<MerchantOffer[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    merchantApi.offers.list()
      .then((data: unknown) => {
        const res = data as { offers: MerchantOffer[] };
        setOffers(res.offers || []);
      })
      .catch(() => toast.error('Failed to load offers'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">My Offers</h1>
        <Button><Plus className="h-4 w-4 mr-1" /> New Offer</Button>
      </div>

      {offers.length === 0 ? (
        <div className="text-center py-12">
          <Tag className="h-12 w-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">No offers yet</p>
        </div>
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
                  <Badge variant={offer.status === 'active' ? 'success' : offer.status === 'draft' ? 'warning' : 'default'}>{offer.status}</Badge>
                </div>
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-lg font-bold text-orange-600">{formatPrice(offer.discountedPrice)}</span>
                  <span className="text-sm text-gray-400 line-through">{formatPrice(offer.originalPrice)}</span>
                </div>
                <div className="flex items-center gap-3 text-xs text-gray-400">
                  <span>{offer.stockRemaining}/{offer.stockInitial} left</span>
                  <span>Ends {formatDate(offer.endTime)}</span>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
