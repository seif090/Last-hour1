'use client';

import { useEffect, useRef, useState } from 'react';
import { Clock } from 'lucide-react';

interface MapStore {
  id: string;
  name: string;
  addressLine1: string;
  lat: number;
  lng: number;
  ratingAvg: number;
  cuisineType?: string | null;
  slug?: string;
}

interface MapViewProps {
  stores: MapStore[];
  userLat?: number;
  userLng?: number;
}

export default function MapView({ stores, userLat, userLng }: MapViewProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstance = useRef<unknown>(null);
  const markersLayer = useRef<unknown>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    import('leaflet').then(L => {
      delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)._getIconUrl;
      L.Icon.Default.mergeOptions({
        iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
        iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
        shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
      });

      if (!mapRef.current || mapInstance.current) return;

      const map = L.map(mapRef.current, { zoomControl: true }).setView(
        [userLat || 40.7128, userLng || -74.006],
        13,
      );

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://openstreetmap.org/copyright">OSM</a>',
        maxZoom: 19,
      }).addTo(map);

      const markers = L.layerGroup().addTo(map);
      stores.forEach(s => {
        const marker = L.marker([s.lat, s.lng]).addTo(markers);
        marker.bindPopup(`
          <div style="font-family:sans-serif;min-width:160px">
            <strong>${s.name}</strong><br/>
            <span style="font-size:12px;color:#666">${s.addressLine1}</span><br/>
            <span style="font-size:12px;color:#d97706">${Number(s.ratingAvg).toFixed(1)} ★</span><br/>
            <a href="/stores/${s.id}" style="font-size:12px;color:#2563eb">View store →</a>
          </div>
        `);
      });

      if (userLat && userLng) {
        L.circleMarker([userLat, userLng], {
          radius: 6,
          color: '#2563eb',
          fillColor: '#3b82f6',
          fillOpacity: 0.6,
        }).addTo(map).bindPopup('Your location');
      }

      if (stores.length > 0) {
        const bounds = L.latLngBounds(stores.map(s => [s.lat, s.lng] as [number, number]));
        if (userLat && userLng) bounds.extend([userLat, userLng]);
        map.fitBounds(bounds, { padding: [50, 50], maxZoom: 15 });
      }

      mapInstance.current = map;
      markersLayer.current = markers;
      setReady(true);
    });

    return () => {
      if (mapInstance.current) {
        (mapInstance.current as { remove: () => void }).remove();
        mapInstance.current = null;
      }
    };
  }, [stores, userLat, userLng]);

  if (!ready) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  return <div ref={mapRef} className="h-[400px] w-full rounded-xl border border-gray-200 z-0" />;
}
