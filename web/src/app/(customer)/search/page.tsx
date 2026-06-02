'use client';

import { useState, FormEvent } from 'react';
import Link from 'next/link';
import { offersApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { formatPrice } from '@/lib/utils';
import { Search, Clock } from 'lucide-react';
import type { Offer } from '@/lib/types';

export default function SearchPage() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Offer[]>([]);
  const [searched, setSearched] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSearch = async (e: FormEvent) => {
    e.preventDefault();
    if (!query.trim()) return;
    setLoading(true);
    setSearched(true);
    try {
      const data = await offersApi.search({ q: query });
      setResults((data as { offers: Offer[] }).offers || []);
    } catch {
      setResults([]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Search Offers</h1>
      <form onSubmit={handleSearch} className="flex gap-2 mb-6">
        <Input value={query} onChange={e => setQuery(e.target.value)} placeholder="Search offers, stores..." className="flex-1" />
        <Button type="submit" loading={loading}><Search className="h-4 w-4" /></Button>
      </form>

      {loading && <div className="flex justify-center py-8"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>}

      {!loading && searched && results.length === 0 && (
        <p className="text-center text-gray-500 py-8">No results for &ldquo;{query}&rdquo;</p>
      )}

      {!loading && results.length > 0 && (
        <div className="grid gap-4 sm:grid-cols-2">
          {results.map(offer => (
            <Link key={offer.id} href={`/offers/${offer.id}`}>
              <Card className="hover:shadow-md transition-shadow">
                <CardContent className="p-4">
                  <div className="flex gap-4">
                    <div className="h-20 w-20 flex-shrink-0 rounded-lg bg-orange-100 flex items-center justify-center">
                      {offer.imageUrl ? <img src={offer.imageUrl} alt={offer.title} className="h-full w-full rounded-lg object-cover" /> : <Tag className="h-8 w-8 text-orange-600" />}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h3 className="font-semibold truncate">{offer.title}</h3>
                      <p className="text-sm text-gray-500 truncate">{offer.store?.name}</p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-lg font-bold text-orange-600">{formatPrice(offer.discountedPrice)}</span>
                        <span className="text-sm text-gray-400 line-through">{formatPrice(offer.originalPrice)}</span>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </Link>
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
