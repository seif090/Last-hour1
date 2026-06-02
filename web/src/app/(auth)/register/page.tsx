'use client';

import { useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { toast } from 'sonner';
import { Clock } from 'lucide-react';

export default function RegisterPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<'customer' | 'merchant'>('customer');
  const [referralCode, setReferralCode] = useState('');
  const [loading, setLoading] = useState(false);
  const { register } = useAuth();
  const router = useRouter();

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (password.length < 8) { toast.error('Password must be at least 8 characters'); return; }
    setLoading(true);
    try {
      await register(email, password, role, referralCode || undefined);
      toast.success('Account created!');
      router.push('/');
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Registration failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-surface px-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="flex items-center justify-center gap-2 mb-2">
            <Clock className="h-8 w-8 text-primary" />
            <h1 className="text-2xl font-bold">Last Hour</h1>
          </div>
          <p className="text-center text-sm text-on-surface-variant">Create your account</p>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <Input id="email" label="Email" type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="you@example.com" required />
            <Input id="password" label="Password" type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="At least 8 characters" required minLength={8} />
            <div>
              <label className="block text-sm font-medium text-on-surface mb-1">Account Type</label>
              <div className="flex gap-3">
                {(['customer', 'merchant'] as const).map(r => (
                  <button type="button" key={r} onClick={() => setRole(r)} className={`flex-1 rounded-lg border px-4 py-2 text-sm font-medium transition-colors cursor-pointer ${role === r ? 'border-orange-500 bg-primary/10 text-orange-700' : 'border-gray-300 bg-surface-container text-on-surface hover:bg-surface-container'}`}>
                    {r === 'customer' ? 'Customer' : 'Merchant'}
                  </button>
                ))}
              </div>
            </div>
            <Input id="referral" label="Referral Code (optional)" value={referralCode} onChange={e => setReferralCode(e.target.value)} placeholder="LH-XXXXXX" />
            <Button type="submit" loading={loading} className="w-full">Create Account</Button>
          </form>
          <p className="mt-4 text-center text-sm text-on-surface-variant">
            Already have an account?{' '}
            <Link href="/login" className="font-medium text-primary hover:text-orange-700">Sign In</Link>
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
