'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { storesApi, reviewsApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { formatPrice, timeAgo } from '@/lib/utils';
import { ArrowLeft, Star, MapPin, Clock } from 'lucide-react';
import type { Store, Review } from '@/lib/types';

export default function StoreDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [store, setStore] = useState<Store | null>(null);
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      storesApi.get(id),
      reviewsApi.store(id).catch(() => ({ reviews: [], meta: {} })),
    ])
      .then(([storeData, reviewsData]) => {
        setStore(storeData as Store);
        setReviews((reviewsData as { reviews: Review[] }).reviews || []);
      })
      .catch(() => router.push('/offers'))
      .finally(() => setLoading(false));
  }, [id, router]);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;
  if (!store) return null;

  return (
    <div>
      <button onClick={() => router.back()} className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-4 cursor-pointer">
        <ArrowLeft className="h-4 w-4" /> Back
      </button>

      <Card className="mb-6">
        <div className="h-40 rounded-t-xl bg-gradient-to-r from-orange-400 to-orange-600" />
        <CardContent className="p-6 -mt-8">
          <div className="flex items-end gap-4">
            <div className="h-16 w-16 rounded-xl bg-white p-1 shadow">
              {store.logoUrl ? <img src={store.logoUrl} alt={store.name} className="h-full w-full rounded-lg object-cover" /> : <div className="h-full w-full rounded-lg bg-orange-100 flex items-center justify-center text-orange-600 font-bold text-xl">{store.name[0]}</div>}
            </div>
            <div className="flex-1">
              <h1 className="text-2xl font-bold">{store.name}</h1>
              <div className="flex items-center gap-2 text-sm text-gray-500">
                <Star className="h-4 w-4 text-yellow-500 fill-yellow-500" />
                <span>{Number(store.ratingAvg).toFixed(1)} ({store.ratingCount})</span>
                {store.cuisineType && <><span>·</span><span>{store.cuisineType}</span></>}
              </div>
            </div>
          </div>
          <div className="mt-4 space-y-1 text-sm text-gray-600">
            <p className="flex items-center gap-2"><MapPin className="h-4 w-4" /> {store.addressLine1}, {store.city}</p>
            {store.opensAt && <p className="flex items-center gap-2"><Clock className="h-4 w-4" /> {store.opensAt} - {store.closesAt}</p>}
          </div>
          {store.description && <p className="mt-4 text-gray-600">{store.description}</p>}
        </CardContent>
      </Card>

      <h2 className="text-lg font-semibold mb-4">Reviews ({reviews.length})</h2>
      {reviews.length === 0 ? (
        <p className="text-gray-500">No reviews yet.</p>
      ) : (
        <div className="space-y-3">
          {reviews.map(review => (
            <Card key={review.id}>
              <CardContent className="p-4">
                <div className="flex items-center gap-1">
                  {Array.from({ length: 5 }, (_, i) => (
                    <Star key={i} className={`h-4 w-4 ${i < review.rating ? 'text-yellow-500 fill-yellow-500' : 'text-gray-300'}`} />
                  ))}
                  <span className="text-xs text-gray-400 ml-2">{timeAgo(review.createdAt)}</span>
                </div>
                {review.comment && <p className="mt-2 text-sm text-gray-600">{review.comment}</p>}
                {review.imageUrl && <img src={review.imageUrl} alt="Review" className="mt-2 h-32 w-32 rounded-lg object-cover" />}
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
