'use client';

import { useAuth } from '@/contexts/auth-context';
import { useRouter, usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { cn } from '@/lib/utils';
import { LayoutDashboard, Tag, Package, ShoppingBag, TicketPercent, Users, BarChart3, LogOut, Menu, X, Clock } from 'lucide-react';

const sidebarItems = [
  { href: '/merchant/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/merchant/offers', label: 'Offers', icon: Tag },
  { href: '/merchant/products', label: 'Products', icon: Package },
  { href: '/merchant/orders', label: 'Orders', icon: ShoppingBag },
  { href: '/merchant/coupons', label: 'Coupons', icon: TicketPercent },
  { href: '/merchant/staff', label: 'Staff', icon: Users },
  { href: '/merchant/analytics', label: 'Analytics', icon: BarChart3 },
];

export default function MerchantLayout({ children }: { children: React.ReactNode }) {
  const { user, loading, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    if (!loading && (!user || user.role !== 'merchant')) {
      if (!user) router.replace('/login');
      else if (user.role === 'admin') router.replace('/admin');
      else router.replace('/offers');
    }
  }, [user, loading, router]);

  if (loading || !user) return null;

  return (
    <div className="flex min-h-screen bg-gray-50">
      <aside className={cn('fixed inset-y-0 left-0 z-50 w-64 transform border-r bg-white transition-transform lg:relative lg:translate-x-0', sidebarOpen ? 'translate-x-0' : '-translate-x-full')}>
        <div className="flex items-center justify-between border-b px-4 py-4">
          <Link href="/merchant/dashboard" className="flex items-center gap-2">
            <Clock className="h-6 w-6 text-orange-600" />
            <span className="text-lg font-bold">Merchant</span>
          </Link>
          <button onClick={() => setSidebarOpen(false)} className="lg:hidden cursor-pointer"><X className="h-5 w-5" /></button>
        </div>
        <nav className="space-y-1 px-3 py-4">
          {sidebarItems.map(item => {
            const active = pathname === item.href || (item.href !== '/merchant/dashboard' && pathname.startsWith(item.href));
            return (
              <Link key={item.href} href={item.href} onClick={() => setSidebarOpen(false)} className={cn('flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors', active ? 'bg-orange-50 text-orange-700' : 'text-gray-600 hover:bg-gray-100')}>
                <item.icon className="h-5 w-5" /> {item.label}
              </Link>
            );
          })}
          <button onClick={() => { logout(); router.push('/login'); }} className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-gray-600 hover:bg-gray-100 cursor-pointer">
            <LogOut className="h-5 w-5" /> Logout
          </button>
        </nav>
      </aside>

      {sidebarOpen && <div className="fixed inset-0 z-40 bg-black/20 lg:hidden" onClick={() => setSidebarOpen(false)} />}

      <div className="flex-1">
        <header className="sticky top-0 z-30 border-b bg-white lg:hidden">
          <div className="flex items-center justify-between px-4 py-3">
            <button onClick={() => setSidebarOpen(true)} className="cursor-pointer"><Menu className="h-5 w-5" /></button>
            <span className="font-bold">Merchant Panel</span>
            <div className="w-5" />
          </div>
        </header>
        <main className="p-4 lg:p-6">{children}</main>
      </div>
    </div>
  );
}
