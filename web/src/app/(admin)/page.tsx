'use client';

import { useState, useEffect } from 'react';
import { adminApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { formatPrice } from '@/lib/utils';
import { Users, Store, ShoppingBag, DollarSign, Tag, Clock, Activity } from 'lucide-react';
import type { AdminStats } from '@/lib/types';

export default function AdminDashboardPage() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminApi.stats()
      .then((data: unknown) => setStats(data as AdminStats))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-primary" /></div>;
  if (!stats) return <p className="text-on-surface-variant">Failed to load stats.</p>;

  const cards = [
    { label: 'Users', value: stats.totalUsers, icon: Users, color: 'text-blue-600' },
    { label: 'Merchants', value: stats.totalMerchants, icon: Store, color: 'text-primary' },
    { label: 'Stores', value: stats.totalStores, icon: Store, color: 'text-green-600' },
    { label: 'Orders', value: stats.totalOrders, icon: ShoppingBag, color: 'text-purple-600' },
    { label: 'Revenue', value: formatPrice(stats.totalRevenue), icon: DollarSign, color: 'text-green-600' },
    { label: 'Active Offers', value: stats.activeOffers, icon: Tag, color: 'text-primary' },
    { label: "Today's Orders", value: stats.todayOrders, icon: Activity, color: 'text-blue-600' },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Admin Dashboard</h1>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {cards.map(card => (
          <Card key={card.label}>
            <CardContent className="p-4">
              <div className="flex items-center gap-3">
                <card.icon className={`h-8 w-8 ${card.color}`} />
                <div>
                  <p className="text-2xl font-bold">{card.value}</p>
                  <p className="text-sm text-on-surface-variant">{card.label}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
