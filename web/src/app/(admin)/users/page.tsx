'use client';

import { useState, useEffect } from 'react';
import { adminApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { formatDate } from '@/lib/utils';
import { Users, Clock } from 'lucide-react';
import type { User } from '@/lib/types';

export default function AdminUsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);

  useEffect(() => {
    adminApi.users(page)
      .then((data: unknown) => {
        const res = data as { data: User[] };
        setUsers(res.data || []);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [page]);

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Users</h1>
      {users.length === 0 ? (
        <div className="text-center py-12"><Users className="h-12 w-12 text-gray-300 mx-auto mb-3" /><p className="text-gray-500">No users found</p></div>
      ) : (
        <div className="space-y-3">
          {users.map(user => (
            <Card key={user.id}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-medium">{user.email}</p>
                    <p className="text-sm text-gray-500">Joined {formatDate(user.createdAt)}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={user.role === 'admin' ? 'danger' : user.role === 'merchant' ? 'warning' : 'info'}>{user.role}</Badge>
                    <Badge variant={user.isActive ? 'success' : 'danger'}>{user.isActive ? 'Active' : 'Inactive'}</Badge>
                  </div>
                </div>
                {user.referralCode && <p className="text-xs text-gray-400 mt-1">Referral: {user.referralCode}</p>}
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
