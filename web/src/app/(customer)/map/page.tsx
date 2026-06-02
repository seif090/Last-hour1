'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import dynamic from 'next/dynamic';
import { storesApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { MapPin, Clock } from 'lucide-react';
import type { Store } from '@/lib/types';

const MapView = dynamic(() => import('@/components/map-view'), { ssr: false, loading: () => (
  <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>
)});

export default function MapPage() {
  const [stores, setStores] = useState<(Store & { lat: number; lng: number })[]>([]);
  const [loading, setLoading] = useState(true);
  const [pos, setPos] = useState<{ lat: number; lng: number } | null>(null);

  useEffect(() => {
    let cancelled = false;
    navigator.geolocation.getCurrentPosition(
      coords => {
        const { latitude, longitude } = coords.coords;
        setPos({ lat: latitude, lng: longitude });
        storesApi.nearby({ lat: latitude, lng: longitude, radiusM: 5000 })
          .then((data: unknown) => {
            if (!cancelled) {
              const res = data as { stores: (Store & { lat: number; lng: number })[] };
              setStores(res.stores || []);
              setLoading(false);
            }
          })
          .catch(() => { if (!cancelled) setLoading(false); });
      },
      () => setLoading(false),
    );
    return () => { cancelled = true; };
  }, []);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Stores Near You</h1>

      {pos && stores.length > 0 && (
        <div className="mb-6">
          <MapView stores={stores} userLat={pos.lat} userLng={pos.lng} />
        </div>
      )}

      {stores.length === 0 ? (
        <div className="text-center py-12">
          <MapPin className="h-12 w-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">Enable location to see nearby stores</p>
        </div>
      ) : (
        <>
          <p className="text-sm text-gray-500 mb-3">{stores.length} store{stores.length !== 1 ? 's' : ''} found within 5km</p>
          <div className="grid gap-4 sm:grid-cols-2">
            {stores.map(store => (
              <Link key={store.id} href={`/stores/${store.id}`}>
                <Card className="hover:shadow-md transition-shadow">
                  <CardContent className="p-4">
                    <div className="flex items-center gap-3">
                      <div className="h-12 w-12 rounded-lg bg-orange-100 flex items-center justify-center text-orange-600 font-bold">
                        {store.name[0]}
                      </div>
                      <div className="flex-1 min-w-0">
                        <h3 className="font-semibold truncate">{store.name}</h3>
                        <p className="text-sm text-gray-500 truncate">{store.addressLine1}</p>
                        <div className="flex items-center gap-2 mt-1 text-xs text-gray-400">
                          {store.cuisineType && <Badge variant="info">{store.cuisineType}</Badge>}
                          <span>{Number(store.ratingAvg).toFixed(1)} ★</span>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </Link>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
