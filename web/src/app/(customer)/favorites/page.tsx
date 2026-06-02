'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { favoritesApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { formatPrice } from '@/lib/utils';
import { Heart, Clock } from 'lucide-react';
import { toast } from 'sonner';

interface FavoriteItem {
  id: string;
  offerId: string;
  offer: {
    id: string;
    title: string;
    discountedPrice: number;
    originalPrice: number;
    stockRemaining: number;
    imageUrl?: string;
    store: { id: string; name: string; slug: string };
  };
}

export default function FavoritesPage() {
  const [items, setItems] = useState<FavoriteItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    favoritesApi.list()
      .then((data: unknown) => setItems(data as FavoriteItem[]))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const handleRemove = async (offerId: string) => {
    try {
      await favoritesApi.remove(offerId);
      setItems(prev => prev.filter(i => i.offerId !== offerId));
      toast.success('Removed from favorites');
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Failed to remove');
    }
  };

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Saved Offers</h1>
      {items.length === 0 ? (
        <div className="text-center py-12">
          <Heart className="h-12 w-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">No saved offers yet</p>
          <Link href="/offers" className="text-orange-600 hover:text-orange-700 text-sm font-medium">Browse offers</Link>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {items.map(item => (
            <Card key={item.id}>
              <CardContent className="p-4">
                <div className="flex gap-4">
                  <div className="h-20 w-20 flex-shrink-0 rounded-lg bg-orange-100 flex items-center justify-center">
                    {item.offer.imageUrl ? <img src={item.offer.imageUrl} alt={item.offer.title} className="h-full w-full rounded-lg object-cover" /> : <Tag className="h-8 w-8 text-orange-600" />}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-semibold truncate">{item.offer.title}</h3>
                    <p className="text-sm text-gray-500 truncate">{item.offer.store?.name}</p>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="text-lg font-bold text-orange-600">{formatPrice(item.offer.discountedPrice)}</span>
                      <span className="text-sm text-gray-400 line-through">{formatPrice(item.offer.originalPrice)}</span>
                    </div>
                    <div className="flex items-center gap-2 mt-2">
                      <Link href={`/offers/${item.offerId}`}><Button size="sm">View</Button></Link>
                      <Button size="sm" variant="ghost" onClick={() => handleRemove(item.offerId)}><Heart className="h-4 w-4 text-red-500 fill-red-500" /></Button>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
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
