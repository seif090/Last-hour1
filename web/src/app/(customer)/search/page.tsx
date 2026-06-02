import type { Metadata } from 'next';
import type { Offer } from '@/lib/types';
import SearchClient from './search-client';

const API = process.env.API_URL || 'http://localhost:3000';

async function fetchSearch(q: string): Promise<Offer[]> {
  try {
    const res = await fetch(`${API}/api/v1/offers/search?q=${encodeURIComponent(q)}`, { next: { revalidate: 30 } });
    if (!res.ok) return [];
    const data = await res.json();
    return (data as { offers: Offer[] }).offers || [];
  } catch {
    return [];
  }
}

export async function generateMetadata({ searchParams }: { searchParams: Promise<{ q?: string }> }): Promise<Metadata> {
  const { q } = await searchParams;
  if (!q) return { title: 'Search Offers - Last Hour' };
  return {
    title: `"${q}" — Search Results - Last Hour`,
    description: `Find the best deals for "${q}" on Last Hour — limited-time offers near you.`,
  };
}

export default async function SearchPage({ searchParams }: { searchParams: Promise<{ q?: string }> }) {
  const { q } = await searchParams;
  const initialResults = q ? await fetchSearch(q) : [];
  return <SearchClient initialQuery={q || ''} initialResults={initialResults} />;
}
