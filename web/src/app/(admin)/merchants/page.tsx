'use client';

import { useState, useEffect } from 'react';
import { adminApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Store, Clock } from 'lucide-react';
import type { Merchant } from '@/lib/types';

export default function AdminMerchantsPage() {
  const [merchants, setMerchants] = useState<Merchant[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);

  useEffect(() => {
    adminApi.merchants(page)
      .then((data: unknown) => {
        const res = data as { data: Merchant[] };
        setMerchants(res.data || []);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [page]);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-primary" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Merchants</h1>
      {merchants.length === 0 ? (
        <div className="text-center py-12"><Store className="h-12 w-12 text-on-surface-variant/50 mx-auto mb-3" /><p className="text-on-surface-variant">No merchants found</p></div>
      ) : (
        <div className="space-y-3">
          {merchants.map(merchant => (
            <Card key={merchant.id}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">{merchant.businessName}</p>
                    <p className="text-sm text-on-surface-variant">{merchant.user?.email} · {merchant.businessType}</p>
                  </div>
                  <Badge variant={merchant.isVerified ? 'success' : 'warning'}>{merchant.isVerified ? 'Verified' : 'Pending'}</Badge>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
      <div className="flex justify-center gap-2 mt-6">
        <button onClick={() => setPage(Math.max(1, page - 1))} disabled={page === 1} className="rounded-lg border px-4 py-2 text-sm disabled:opacity-50 cursor-pointer">Previous</button>
        <span className="px-4 py-2 text-sm text-on-surface-variant">Page {page}</span>
        <button onClick={() => setPage(page + 1)} className="rounded-lg border px-4 py-2 text-sm cursor-pointer">Next</button>
      </div>
    </div>
  );
}
