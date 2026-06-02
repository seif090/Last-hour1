'use client';

import { useAuth } from '@/contexts/auth-context';
import { useRouter, usePathname } from 'next/navigation';
import { useEffect } from 'react';
import Link from 'next/link';
import { cn } from '@/lib/utils';
import { Clock, Search, MapPin, Heart, ShoppingBag, User, LogOut, Package } from 'lucide-react';

const navItems = [
  { href: '/offers', label: 'Offers', icon: Clock },
  { href: '/search', label: 'Search', icon: Search },
  { href: '/map', label: 'Map', icon: MapPin },
  { href: '/orders', label: 'Orders', icon: Package },
  { href: '/favorites', label: 'Saved', icon: Heart },
  { href: '/profile', label: 'Profile', icon: User },
];

export default function CustomerLayout({ children }: { children: React.ReactNode }) {
  const { user, loading, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (!loading && (!user || user.role !== 'customer')) {
      if (!user) router.replace('/login');
      else if (user.role === 'admin') router.replace('/admin');
      else router.replace('/merchant/dashboard');
    }
  }, [user, loading, router]);

  if (loading || !user) return null;

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="sticky top-0 z-50 border-b bg-white">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-3">
          <Link href="/offers" className="flex items-center gap-2">
            <Clock className="h-6 w-6 text-orange-600" />
            <span className="text-lg font-bold">Last Hour</span>
          </Link>
          <button onClick={() => { logout(); router.push('/login'); }} className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 cursor-pointer">
            <LogOut className="h-4 w-4" /> Logout
          </button>
        </div>
      </header>

      <main className="mx-auto max-w-5xl px-4 py-6 pb-20">{children}</main>

      <nav className="fixed bottom-0 left-0 right-0 z-50 border-t bg-white">
        <div className="mx-auto flex max-w-5xl justify-around">
          {navItems.map(item => {
            const active = pathname.startsWith(item.href);
            return (
              <Link key={item.href} href={item.href} className={cn('flex flex-col items-center gap-0.5 px-3 py-2 text-xs font-medium', active ? 'text-orange-600' : 'text-gray-500 hover:text-gray-700')}>
                <item.icon className="h-5 w-5" />
                {item.label}
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
