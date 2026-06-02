'use client';

import { useState, useEffect } from 'react';
import { addressesApi } from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { MapPin, Plus, Clock } from 'lucide-react';
import type { Address } from '@/lib/types';

export default function AddressesPage() {
  const [addresses, setAddresses] = useState<Address[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [label, setLabel] = useState('');
  const [addressLine1, setAddressLine1] = useState('');
  const [city, setCity] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    addressesApi.list()
      .then((data: unknown) => setAddresses(data as Address[]))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const handleAdd = async () => {
    if (!label || !addressLine1 || !city) { toast.error('Please fill all fields'); return; }
    setSaving(true);
    try {
      await addressesApi.create({ label, addressLine1, city });
      toast.success('Address added');
      setShowForm(false);
      setLabel(''); setAddressLine1(''); setCity('');
      const data = await addressesApi.list();
      setAddresses(data as Address[]);
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Failed to add address');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await addressesApi.delete(id);
      setAddresses(prev => prev.filter(a => a.id !== id));
      toast.success('Address deleted');
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Failed to delete');
    }
  };

  if (loading) return <div className="flex justify-center py-12"><Clock className="h-8 w-8 animate-spin text-orange-600" /></div>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Addresses</h1>
        <Button size="sm" onClick={() => setShowForm(!showForm)}><Plus className="h-4 w-4 mr-1" /> Add</Button>
      </div>

      {showForm && (
        <Card className="mb-6">
          <CardContent className="p-4 space-y-3">
            <Input label="Label" value={label} onChange={e => setLabel(e.target.value)} placeholder="Home, Work, etc." />
            <Input label="Address" value={addressLine1} onChange={e => setAddressLine1(e.target.value)} placeholder="Street, building, etc." />
            <Input label="City" value={city} onChange={e => setCity(e.target.value)} placeholder="Cairo" />
            <Button onClick={handleAdd} loading={saving}>Save Address</Button>
          </CardContent>
        </Card>
      )}

      {addresses.length === 0 ? (
        <div className="text-center py-12">
          <MapPin className="h-12 w-12 text-on-surface-variant/50 mx-auto mb-3" />
          <p className="text-on-surface-variant">No addresses saved</p>
        </div>
      ) : (
        <div className="space-y-3">
          {addresses.map(addr => (
            <Card key={addr.id}>
              <CardContent className="p-4">
                <div className="flex items-start justify-between">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-medium">{addr.label}</span>
                      {addr.isDefault && <Badge variant="info">Default</Badge>}
                    </div>
                    <p className="text-sm text-on-surface-variant mt-1">{addr.addressLine1}{addr.addressLine2 ? `, ${addr.addressLine2}` : ''}</p>
                    <p className="text-sm text-on-surface-variant">{addr.city}{addr.district ? `, ${addr.district}` : ''}</p>
                  </div>
                  <Button variant="ghost" size="sm" onClick={() => handleDelete(addr.id)} className="text-red-500">Delete</Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
