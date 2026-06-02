import { notFound } from 'next/navigation';
import type { Metadata } from 'next';
import { Card, CardContent } from '@/components/ui/card';
import BackButton from '@/components/back-button';
import { Star, MapPin, Clock } from 'lucide-react';
import type { Store, Review } from '@/lib/types';

const API = process.env.API_URL || 'http://localhost:3000';

async function fetchStore(id: string): Promise<Store | null> {
  try {
    const res = await fetch(`${API}/api/v1/stores/${id}`, { next: { revalidate: 120 } });
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

async function fetchReviews(id: string): Promise<Review[]> {
  try {
    const res = await fetch(`${API}/api/v1/reviews/store/${id}`, { next: { revalidate: 60 } });
    if (!res.ok) return [];
    const data = await res.json();
    return data.reviews || [];
  } catch {
    return [];
  }
}

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params;
  const store = await fetchStore(id);
  if (!store) return { title: 'Store Not Found - Last Hour' };
  return {
    title: `${store.name} - Last Hour`,
    description: store.description || `Visit ${store.name} at ${store.addressLine1}, ${store.city} for last-minute food deals.`,
    openGraph: {
      title: store.name,
      description: store.description || `Find deals at ${store.name}`,
    },
  };
}

export default async function StoreDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const [store, reviews] = await Promise.all([fetchStore(id), fetchReviews(id)]);
  if (!store) notFound();

  return (
    <div>
      <BackButton />

      <Card className="mb-6">
        <div className="h-40 rounded-t-xl bg-gradient-to-br from-primary/30 via-surface-container to-surface-container" />
        <CardContent className="p-6 -mt-8">
          <div className="flex items-end gap-4">
            <div className="h-16 w-16 rounded-xl bg-surface-container p-1 border border-outline">
              {store.logoUrl ? (
                <img src={store.logoUrl} alt={store.name} className="h-full w-full rounded-lg object-cover" />
              ) : (
                <div className="h-full w-full rounded-lg bg-primary/15 flex items-center justify-center text-primary font-display font-bold text-xl">{store.name[0]}</div>
              )}
            </div>
            <div className="flex-1">
              <h1 className="text-2xl font-display font-bold">{store.name}</h1>
              <div className="flex items-center gap-2 text-sm text-on-surface-variant">
                <Star className="h-4 w-4 text-amber-500 fill-amber-500" />
                <span>{Number(store.ratingAvg).toFixed(1)} ({store.ratingCount})</span>
                {store.cuisineType && <><span>·</span><span>{store.cuisineType}</span></>}
              </div>
            </div>
          </div>
          <div className="mt-4 space-y-1 text-sm text-on-surface-variant">
            <p className="flex items-center gap-2"><MapPin className="h-4 w-4 shrink-0" /> {store.addressLine1}, {store.city}</p>
            {store.opensAt && <p className="flex items-center gap-2"><Clock className="h-4 w-4 shrink-0" /> {store.opensAt} - {store.closesAt}</p>}
          </div>
          {store.description && <p className="mt-4 text-on-surface-variant">{store.description}</p>}
        </CardContent>
      </Card>

      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-display font-semibold">Reviews ({reviews.length})</h2>
      </div>

      {reviews.length === 0 ? (
        <p className="text-on-surface-variant py-8 text-center">No reviews yet.</p>
      ) : (
        <div className="space-y-3">
          {reviews.map(review => (
            <Card key={review.id}>
              <CardContent className="p-4">
                <div className="flex items-center gap-1">
                  {Array.from({ length: 5 }, (_, i) => (
                    <Star key={i} className={`h-4 w-4 ${i < review.rating ? 'text-amber-500 fill-amber-500' : 'text-outline'}`} />
                  ))}
                  <span className="text-xs text-on-surface-variant ml-auto">
                    {new Date(review.createdAt).toLocaleDateString('en-EG', { month: 'short', day: 'numeric' })}
                  </span>
                </div>
                {review.comment && <p className="mt-2 text-sm text-on-surface-variant">{review.comment}</p>}
                {review.imageUrl && (
                  <img src={review.imageUrl} alt="Review" className="mt-2 h-32 w-32 rounded-lg object-cover" loading="lazy" />
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}


