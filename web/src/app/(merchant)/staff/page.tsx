'use client';

import { useState, useEffect, FormEvent } from 'react';
import { merchantApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Users, Clock, Plus, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import type { StaffMember } from '@/lib/types';

export default function StaffPage() {
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [role, setRole] = useState<'admin' | 'manager' | 'staff'>('staff');
  const [saving, setSaving] = useState(false);

  const loadStaff = () => {
    merchantApi.staff.list()
      .then((data: unknown) => setStaff(data as StaffMember[]))
      .catch(() => toast.error('Failed to load staff'))
      .finally(() => setLoading(false));
  };

  useEffect(() => { loadStaff(); }, []);

  const handleInvite = async (e: FormEvent) => {
    e.preventDefault();
    if (!email || !name) { toast.error('Fill required fields'); return; }
    setSaving(true);
    try {
      await merchantApi.staff.invite({ email, name, role });
      toast.success('Staff invited');
      setShowForm(false);
      setEmail(''); setName('');
      loadStaff();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Failed to invite');
    } finally {
      setSaving(false);
    }
  };

  const handleRemove = async (id: string) => {
    try {
      await merchantApi.staff.remove(id);
      setStaff(prev => prev.filter(s => s.id !== id));
      toast.success('Staff removed');
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Failed to remove');
    }
  };

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-primary" /></div>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Staff</h1>
        <Button onClick={() => setShowForm(!showForm)}><Plus className="h-4 w-4 mr-1" /> Invite</Button>
      </div>

      {showForm && (
        <Card className="mb-6">
          <CardContent className="p-4">
            <form onSubmit={handleInvite} className="space-y-3">
              <Input label="Email" type="email" value={email} onChange={e => setEmail(e.target.value)} required />
              <Input label="Name" value={name} onChange={e => setName(e.target.value)} required />
              <div>
                <label className="block text-sm font-medium text-on-surface mb-1">Role</label>
                <select value={role} onChange={e => setRole(e.target.value as 'admin' | 'manager' | 'staff')} className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
                  <option value="staff">Staff</option>
                  <option value="manager">Manager</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              <Button type="submit" loading={saving}>Send Invite</Button>
            </form>
          </CardContent>
        </Card>
      )}

      {staff.length === 0 ? (
        <div className="text-center py-12">
          <Users className="h-12 w-12 text-on-surface-variant/50 mx-auto mb-3" />
          <p className="text-on-surface-variant">No staff members yet</p>
        </div>
      ) : (
        <div className="space-y-3">
          {staff.map(member => (
            <Card key={member.id}>
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="font-semibold">{member.name}</h3>
                    <p className="text-sm text-on-surface-variant">{member.email}</p>
                    <div className="flex items-center gap-2 mt-1">
                      <Badge variant={member.role === 'admin' ? 'danger' : member.role === 'manager' ? 'warning' : 'info'}>{member.role}</Badge>
                      <Badge variant={member.isActive ? 'success' : 'danger'}>{member.isActive ? 'Active' : 'Inactive'}</Badge>
                    </div>
                  </div>
                  <Button variant="ghost" size="sm" onClick={() => handleRemove(member.id)} className="text-red-500">
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
