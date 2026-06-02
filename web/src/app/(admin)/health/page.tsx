'use client';

import { useState, useEffect } from 'react';
import { adminApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Activity, Clock } from 'lucide-react';

export default function AdminHealthPage() {
  const [health, setHealth] = useState<{ status: string; uptime: number; timestamp: string } | null>(null);
  const [loading, setLoading] = useState(true);

  const loadHealth = () => {
    adminApi.health()
      .then((data: unknown) => setHealth(data as { status: string; uptime: number; timestamp: string }))
      .catch(() => setHealth(null))
      .finally(() => setLoading(false));
  };

  useEffect(() => { loadHealth(); }, []);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  const uptimeHours = health ? Math.floor(health.uptime / 3600) : 0;
  const uptimeMins = health ? Math.floor((health.uptime % 3600) / 60) : 0;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">System Health</h1>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold">API Status</h3>
              <Badge variant={health?.status === 'ok' ? 'success' : 'danger'}>{health?.status || 'unreachable'}</Badge>
            </div>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between"><span className="text-gray-500">Uptime</span><span>{uptimeHours}h {uptimeMins}m</span></div>
              <div className="flex justify-between"><span className="text-gray-500">Last Check</span><span>{health ? new Date(health.timestamp).toLocaleString() : 'N/A'}</span></div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-3 mb-4">
              <Activity className="h-8 w-8 text-green-600" />
              <div>
                <h3 className="font-semibold">All Systems</h3>
                <p className="text-sm text-gray-500">Checking backend connectivity</p>
              </div>
            </div>
            <button onClick={loadHealth} className="text-sm text-orange-600 hover:text-orange-700 font-medium cursor-pointer">
              Refresh Status
            </button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
