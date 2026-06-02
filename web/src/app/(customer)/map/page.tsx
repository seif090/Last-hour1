import type { Metadata } from 'next';
import MapClient from './map-client';

export const metadata: Metadata = {
  title: 'Stores Near You - Last Hour',
  description: 'Find nearby stores with live offers and real-time deals on Last Hour.',
};

export default function MapPage() {
  return <MapClient />;
}
