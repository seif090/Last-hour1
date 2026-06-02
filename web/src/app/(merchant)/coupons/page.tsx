'use client';

import { useState, useEffect, FormEvent } from 'react';
import { merchantApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { formatPrice } from '@/lib/utils';
import { TicketPercent, Clock, Plus } from 'lucide-react';
import { toast } from 'sonner';
import type { Coupon } from '@/lib/types';

export default function MerchantCouponsPage() {
  const [coupons, setCoupons] = useState<Coupon[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [code, setCode] = useState('');
  const [discountType, setDiscountType] = useState<'percentage' | 'fixed'>('percentage');
  const [discountValue, setDiscountValue] = useState('');
  const [storeId, setStoreId] = useState('');
  const [description, setDescription] = useState('');
  const [saving, setSaving] = useState(false);

  const loadCoupons = () => {
    merchantApi.coupons.list()
      .then((data: unknown) => setCoupons(data as Coupon[]))
      .catch(() => toast.error('Failed to load coupons'))
      .finally(() => setLoading(false));
  };

  useEffect(() => { loadCoupons(); }, []);

  const handleCreate = async (e: FormEvent) => {
    e.preventDefault();
    if (!code || !discountValue || !storeId) { toast.error('Fill required fields'); return; }
    setSaving(true);
    try {
      await merchantApi.coupons.create({
        storeId, code, discountType, discountValue: Number(discountValue),
        description: description || undefined,
      });
      toast.success('Coupon created');
      setShowForm(false);
      setCode(''); setDiscountValue(''); setDescription('');
      loadCoupons();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Failed to create coupon');
    } finally {
      setSaving(false);
    }
  };

  const handleToggle = async (id: string) => {
    try {
      await merchantApi.coupons.toggle(id);
      setCoupons(prev => prev.map(c => c.id === id ? { ...c, isActive: !c.isActive } : c));
      toast.success('Coupon toggled');
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Failed to toggle');
    }
  };

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Coupons</h1>
        <Button onClick={() => setShowForm(!showForm)}><Plus className="h-4 w-4 mr-1" /> New Coupon</Button>
      </div>

      {showForm && (
        <Card className="mb-6">
          <CardContent className="p-4">
            <form onSubmit={handleCreate} className="space-y-3">
              <Input label="Store ID" value={storeId} onChange={e => setStoreId(e.target.value)} placeholder="Store ID" required />
              <Input label="Code" value={code} onChange={e => setCode(e.target.value)} placeholder="SUMMER20" required />
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                <select value={discountType} onChange={e => setDiscountType(e.target.value as 'percentage' | 'fixed')} className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
                  <option value="percentage">Percentage</option>
                  <option value="fixed">Fixed Amount</option>
                </select>
              </div>
              <Input label={discountType === 'percentage' ? 'Discount %' : 'Discount Amount'} type="number" value={discountValue} onChange={e => setDiscountValue(e.target.value)} required />
              <Input label="Description (optional)" value={description} onChange={e => setDescription(e.target.value)} />
              <Button type="submit" loading={saving}>Create Coupon</Button>
            </form>
          </CardContent>
        </Card>
      )}

      {coupons.length === 0 ? (
        <div className="text-center py-12">
          <TicketPercent className="h-12 w-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">No coupons yet</p>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {coupons.map(coupon => (
            <Card key={coupon.id}>
              <CardContent className="p-4">
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <h3 className="font-mono font-bold">{coupon.code}</h3>
                    {coupon.description && <p className="text-sm text-gray-500">{coupon.description}</p>}
                  </div>
                  <button onClick={() => handleToggle(coupon.id)} className="cursor-pointer">
                    <Badge variant={coupon.isActive ? 'success' : 'danger'}>{coupon.isActive ? 'Active' : 'Inactive'}</Badge>
                  </button>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <span className="font-medium text-orange-600">
                    {coupon.discountType === 'percentage' ? `${coupon.discountValue}%` : formatPrice(coupon.discountValue)}
                  </span>
                  {coupon.minOrderAmount && <span className="text-gray-400">Min: {formatPrice(coupon.minOrderAmount)}</span>}
                </div>
                <div className="mt-2 text-xs text-gray-400">
                  Used {coupon.currentUses}/{coupon.maxUses}
                  <div className="mt-1 h-1.5 w-full rounded-full bg-gray-100">
                    <div className="h-1.5 rounded-full bg-orange-500" style={{ width: `${Math.min(100, (coupon.currentUses / coupon.maxUses) * 100)}%` }} />
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
