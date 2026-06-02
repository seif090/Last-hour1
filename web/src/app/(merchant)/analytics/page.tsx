'use client';

import { useState, useEffect } from 'react';
import { merchantApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { formatPrice } from '@/lib/utils';
import { BarChart3, TrendingUp, ShoppingBag, DollarSign, Clock } from 'lucide-react';
import type { MerchantAnalytics } from '@/lib/types';

export default function AnalyticsPage() {
  const [analytics, setAnalytics] = useState<MerchantAnalytics | null>(null);
  const [days, setDays] = useState(7);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    merchantApi.analytics(days)
      .then((data: unknown) => setAnalytics(data as MerchantAnalytics))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [days]);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-primary" /></div>;
  if (!analytics) return <p className="text-on-surface-variant">Failed to load analytics.</p>;

  const avgOrderValue = analytics.totalOrders > 0 ? analytics.totalRevenue / analytics.totalOrders : 0;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Analytics</h1>
        <select value={days} onChange={e => setDays(Number(e.target.value))} className="rounded-lg border border-gray-300 px-3 py-1.5 text-sm">
          <option value={7}>Last 7 days</option>
          <option value={14}>Last 14 days</option>
          <option value={30}>Last 30 days</option>
          <option value={90}>Last 90 days</option>
        </select>
      </div>

      <div className="grid gap-4 mb-8 sm:grid-cols-2 lg:grid-cols-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3"><ShoppingBag className="h-8 w-8 text-primary" /><div><p className="text-2xl font-bold">{analytics.totalOrders}</p><p className="text-sm text-on-surface-variant">Total Orders</p></div></div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3"><DollarSign className="h-8 w-8 text-green-600" /><div><p className="text-2xl font-bold">{formatPrice(analytics.totalRevenue)}</p><p className="text-sm text-on-surface-variant">Total Revenue</p></div></div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3"><TrendingUp className="h-8 w-8 text-blue-600" /><div><p className="text-2xl font-bold">{formatPrice(avgOrderValue)}</p><p className="text-sm text-on-surface-variant">Avg Order Value</p></div></div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3"><BarChart3 className="h-8 w-8 text-purple-600" /><div><p className="text-2xl font-bold">{analytics.daily.length}</p><p className="text-sm text-on-surface-variant">Active Days</p></div></div></CardContent></Card>
      </div>

      <h2 className="text-lg font-semibold mb-4">Daily Breakdown</h2>
      <div className="space-y-2">
        {analytics.daily.map(day => (
          <Card key={day.date}>
            <CardContent className="p-3">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium">{new Date(day.date).toLocaleDateString('en-EG', { weekday: 'short', month: 'short', day: 'numeric' })}</span>
                <div className="flex items-center gap-4 text-sm">
                  <span className="text-on-surface-variant">{day.orders} orders</span>
                  <span className="font-semibold">{formatPrice(day.revenue)}</span>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
