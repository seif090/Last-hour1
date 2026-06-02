'use client';

import { useState, useEffect } from 'react';
import { adminApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { formatPrice } from '@/lib/utils';
import { TicketPercent, Clock } from 'lucide-react';
import type { Coupon } from '@/lib/types';

export default function AdminCouponsPage() {
  const [coupons, setCoupons] = useState<Coupon[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);

  useEffect(() => {
    adminApi.coupons(page)
      .then((data: unknown) => {
        const res = data as { data: Coupon[] };
        setCoupons(res.data || []);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [page]);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">All Coupons</h1>
      {coupons.length === 0 ? (
        <div className="text-center py-12"><TicketPercent className="h-12 w-12 text-gray-300 mx-auto mb-3" /><p className="text-gray-500">No coupons found</p></div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {coupons.map(coupon => (
            <Card key={coupon.id}>
              <CardContent className="p-4">
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="font-mono font-bold">{coupon.code}</h3>
                    {coupon.description && <p className="text-sm text-gray-500">{coupon.description}</p>}
                    {coupon.store && <p className="text-xs text-gray-400 mt-1">Store: {coupon.store.name}</p>}
                  </div>
                  <Badge variant={coupon.isActive ? 'success' : 'danger'}>{coupon.isActive ? 'Active' : 'Inactive'}</Badge>
                </div>
                <div className="flex items-center gap-2 mt-2 text-sm">
                  <span className="font-medium text-orange-600">
                    {coupon.discountType === 'percentage' ? `${coupon.discountValue}%` : formatPrice(coupon.discountValue)}
                  </span>
                  <span className="text-gray-400">· Used {coupon.currentUses}/{coupon.maxUses}</span>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
      <div className="flex justify-center gap-2 mt-6">
        <button onClick={() => setPage(Math.max(1, page - 1))} disabled={page === 1} className="rounded-lg border px-4 py-2 text-sm disabled:opacity-50 cursor-pointer">Previous</button>
        <span className="px-4 py-2 text-sm text-gray-500">Page {page}</span>
        <button onClick={() => setPage(page + 1)} className="rounded-lg border px-4 py-2 text-sm cursor-pointer">Next</button>
      </div>
    </div>
  );
}
