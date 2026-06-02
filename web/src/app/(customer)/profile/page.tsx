'use client';

import { useState, FormEvent } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { useRouter } from 'next/navigation';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { merchantApi } from '@/lib/api';
import { toast } from 'sonner';
import { User, Mail, Phone, Award, LogOut, Store, X } from 'lucide-react';

export default function ProfilePage() {
  const { user, logout, refresh } = useAuth();
  const router = useRouter();
  const [showMerchantForm, setShowMerchantForm] = useState(false);
  const [businessName, setBusinessName] = useState('');
  const [businessType, setBusinessType] = useState('restaurant');
  const [description, setDescription] = useState('');
  const [taxId, setTaxId] = useState('');
  const [saving, setSaving] = useState(false);

  const handleLogout = () => {
    logout();
    router.push('/login');
    toast.success('Logged out');
  };

  const handleMerchantRegister = async (e: FormEvent) => {
    e.preventDefault();
    if (!businessName) { toast.error('Business name is required'); return; }
    setSaving(true);
    try {
      await merchantApi.register({ businessName, businessType, description: description || undefined, taxId: taxId || undefined });
      toast.success('Registered as merchant!');
      setShowMerchantForm(false);
      await refresh();
      setTimeout(() => router.push('/merchant/dashboard'), 500);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Registration failed');
    } finally {
      setSaving(false);
    }
  };

  if (!user) return null;

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Profile</h1>

      <Card className="mb-6">
        <CardContent className="p-6">
          <div className="flex items-center gap-4 mb-6">
            <div className="h-16 w-16 rounded-full bg-primary/15 flex items-center justify-center">
              {user.avatarUrl ? (
                <img src={user.avatarUrl} alt="" className="h-full w-full rounded-full object-cover" />
              ) : (
                <User className="h-8 w-8 text-primary" />
              )}
            </div>
            <div>
              <h2 className="text-xl font-semibold">{user.email}</h2>
              <Badge variant="info" className="mt-1">{user.role}</Badge>
            </div>
          </div>

          <div className="space-y-3 text-sm">
            <div className="flex items-center gap-3 text-on-surface-variant">
              <Mail className="h-4 w-4" /> {user.email}
            </div>
            {user.phone && (
              <div className="flex items-center gap-3 text-on-surface-variant">
                <Phone className="h-4 w-4" /> {user.phone}
              </div>
            )}
            {user.referralCode && (
              <div className="flex items-center gap-3 text-on-surface-variant">
                <Award className="h-4 w-4" /> Code: {user.referralCode}
              </div>
            )}
          </div>

          <div className="mt-6 space-y-2">
            <Button variant="outline" className="w-full justify-start" onClick={() => router.push('/profile/addresses')}>
              My Addresses
            </Button>
            {user.role === 'customer' && (
              <Button variant="outline" className="w-full justify-start" onClick={() => setShowMerchantForm(!showMerchantForm)}>
                <Store className="h-4 w-4 mr-2" /> Register as Merchant
              </Button>
            )}
            <Button variant="danger" className="w-full justify-start" onClick={handleLogout}>
              <LogOut className="h-4 w-4 mr-2" /> Logout
            </Button>
          </div>
        </CardContent>
      </Card>

      {showMerchantForm && (
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold">Register as Merchant</h3>
              <button onClick={() => setShowMerchantForm(false)} className="cursor-pointer"><X className="h-5 w-5 text-on-surface-variant" /></button>
            </div>
            <form onSubmit={handleMerchantRegister} className="space-y-3">
              <Input label="Business Name" value={businessName} onChange={e => setBusinessName(e.target.value)} required />
              <div>
                <label className="block text-sm font-medium text-on-surface mb-1">Business Type</label>
                <select value={businessType} onChange={e => setBusinessType(e.target.value)} className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
                  <option value="restaurant">Restaurant</option>
                  <option value="bakery">Bakery</option>
                  <option value="supermarket">Supermarket</option>
                  <option value="cafe">Cafe</option>
                  <option value="other">Other</option>
                </select>
              </div>
              <Input label="Description (optional)" value={description} onChange={e => setDescription(e.target.value)} />
              <Input label="Tax ID (optional)" value={taxId} onChange={e => setTaxId(e.target.value)} />
              <Button type="submit" loading={saving} className="w-full">Register</Button>
            </form>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
