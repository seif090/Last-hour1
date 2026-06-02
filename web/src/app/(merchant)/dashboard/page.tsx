'use client';

import { useState, useEffect } from 'react';
import { merchantApi } from '@/lib/api';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { formatPrice } from '@/lib/utils';
import { LayoutDashboard, Store, ShoppingBag, Tag, Clock } from 'lucide-react';

interface DashboardData {
  stores: Array<{
    id: string;
    name: string;
    slug: string;
    isActive: boolean;
    _count: { orders: number; products: number };
    offers: Array<{ id: string; title: string; stockRemaining: number; endTime: string }>;
  }>;
}

export default function MerchantDashboardPage() {
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    merchantApi.dashboard()
      .then((d: unknown) => setData(d as DashboardData))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;
  if (!data) return <p className="text-gray-500">Failed to load dashboard.</p>;

  const totalOrders = data.stores.reduce((s, st) => s + st._count.orders, 0);
  const totalProducts = data.stores.reduce((s, st) => s + st._count.products, 0);
  const activeOffers = data.stores.reduce((s, st) => s + st.offers.length, 0);

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Merchant Dashboard</h1>

      <div className="grid gap-4 mb-8 sm:grid-cols-2 lg:grid-cols-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3"><Store className="h-8 w-8 text-orange-600" /><div><p className="text-2xl font-bold">{data.stores.length}</p><p className="text-sm text-gray-500">Stores</p></div></div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3"><ShoppingBag className="h-8 w-8 text-blue-600" /><div><p className="text-2xl font-bold">{totalOrders}</p><p className="text-sm text-gray-500">Orders</p></div></div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3"><Tag className="h-8 w-8 text-green-600" /><div><p className="text-2xl font-bold">{activeOffers}</p><p className="text-sm text-gray-500">Active Offers</p></div></div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3"><LayoutDashboard className="h-8 w-8 text-purple-600" /><div><p className="text-2xl font-bold">{totalProducts}</p><p className="text-sm text-gray-500">Products</p></div></div></CardContent></Card>
      </div>

      <h2 className="text-lg font-semibold mb-4">Your Stores</h2>
      <div className="grid gap-4 sm:grid-cols-2">
        {data.stores.map(store => (
          <Card key={store.id}>
            <CardHeader>
              <div className="flex items-center justify-between">
                <h3 className="font-semibold">{store.name}</h3>
                <Badge variant={store.isActive ? 'success' : 'danger'}>{store.isActive ? 'Active' : 'Inactive'}</Badge>
              </div>
            </CardHeader>
            <CardContent>
              <div className="flex gap-4 text-sm text-gray-500 mb-3">
                <span>{store._count.orders} orders</span>
                <span>{store._count.products} products</span>
                <span>{store.offers.length} active offers</span>
              </div>
              {store.offers.length > 0 && (
                <div className="space-y-1">
                  <p className="text-xs font-medium text-gray-400">ACTIVE OFFERS</p>
                  {store.offers.map(o => (
                    <div key={o.id} className="flex items-center justify-between text-sm">
                      <span className="truncate">{o.title}</span>
                      <span className="text-gray-500">{o.stockRemaining} left</span>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
