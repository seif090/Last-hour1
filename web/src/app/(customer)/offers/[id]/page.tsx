import { notFound } from 'next/navigation';
import type { Metadata } from 'next';
import type { Offer } from '@/lib/types';
import OfferDetailClient from './offer-detail-client';

const API = process.env.API_URL || 'http://localhost:3000';

async function fetchOffer(id: string): Promise<Offer | null> {
  try {
    const res = await fetch(`${API}/api/v1/offers/${id}`, { next: { revalidate: 60 } });
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }): Promise<Metadata> {
  const { id } = await params;
  const offer = await fetchOffer(id);
  if (!offer) return { title: 'Offer Not Found' };
  return {
    title: `${offer.title} - Last Hour`,
    description: offer.description || `Get ${offer.title} at ${offer.discountedPrice} EGP — limited time offer!`,
    openGraph: {
      title: offer.title,
      description: offer.description || `Save on ${offer.title}`,
      images: offer.imageUrl ? [offer.imageUrl] : [],
    },
  };
}

export default async function OfferDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const offer = await fetchOffer(id);
  if (!offer) notFound();

  return <OfferDetailClient offer={offer} />;
}
