'use client';

import { useState, useEffect } from 'react';
import { adminApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { formatPrice, formatDate } from '@/lib/utils';
import { GitCompareArrows, Clock, Award, Users } from 'lucide-react';
import type { Referral } from '@/lib/types';

export default function AdminReferralsPage() {
  const [referrals, setReferrals] = useState<Referral[]>([]);
  const [stats, setStats] = useState<{ totalRewarded: number; pendingCount: number } | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      adminApi.referrals(),
      adminApi.referralStats().catch(() => null),
    ])
      .then(([refsData, statsData]) => {
        setReferrals((refsData as { data: Referral[] }).data || []);
        setStats(statsData as { totalRewarded: number; pendingCount: number } | null);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Referrals</h1>

      {stats && (
        <div className="grid gap-4 mb-6 sm:grid-cols-2">
          <Card><CardContent className="p-4"><div className="flex items-center gap-3"><Award className="h-8 w-8 text-green-600" /><div><p className="text-2xl font-bold">{formatPrice(stats.totalRewarded)}</p><p className="text-sm text-gray-500">Total Rewarded</p></div></div></CardContent></Card>
          <Card><CardContent className="p-4"><div className="flex items-center gap-3"><Users className="h-8 w-8 text-orange-600" /><div><p className="text-2xl font-bold">{stats.pendingCount}</p><p className="text-sm text-gray-500">Pending Rewards</p></div></div></CardContent></Card>
        </div>
      )}

      {referrals.length === 0 ? (
        <div className="text-center py-12"><GitCompareArrows className="h-12 w-12 text-gray-300 mx-auto mb-3" /><p className="text-gray-500">No referrals found</p></div>
      ) : (
        <div className="space-y-3">
          {referrals.map(ref => (
            <Card key={ref.id}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm">
                      <span className="font-medium">{ref.referrer?.email || ref.referrerId}</span>
                      <span className="text-gray-400 mx-2">→</span>
                      <span className="font-medium">{ref.referee?.email || ref.refereeId}</span>
                    </p>
                    <p className="text-xs text-gray-500">{formatDate(ref.createdAt)}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={ref.status === 'rewarded' ? 'success' : ref.status === 'pending' ? 'warning' : 'danger'}>{ref.status}</Badge>
                    {ref.rewardAmount && <span className="text-sm font-medium text-green-600">+{formatPrice(ref.rewardAmount)}</span>}
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
