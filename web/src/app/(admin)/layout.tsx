'use client';

import ErrorBoundary from '@/components/error-boundary';
import { useAuth } from '@/contexts/auth-context';
import { useRouter, usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { cn } from '@/lib/utils';
import { LayoutDashboard, Users, Store, ShoppingBag, Tag, TicketPercent, GitCompareArrows, Activity, LogOut, Menu, X, Shield } from 'lucide-react';

const sidebarItems = [
  { href: '/admin', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/admin/users', label: 'Users', icon: Users },
  { href: '/admin/merchants', label: 'Merchants', icon: Store },
  { href: '/admin/orders', label: 'Orders', icon: ShoppingBag },
  { href: '/admin/offers', label: 'Offers', icon: Tag },
  { href: '/admin/coupons', label: 'Coupons', icon: TicketPercent },
  { href: '/admin/referrals', label: 'Referrals', icon: GitCompareArrows },
  { href: '/admin/health', label: 'System', icon: Activity },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { user, loading, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    if (!loading && (!user || user.role !== 'admin')) {
      if (!user) router.replace('/login');
      else router.replace(user.role === 'merchant' ? '/merchant/dashboard' : '/offers');
    }
  }, [user, loading, router]);

  if (loading || !user) return null;

  return (
    <div className="flex min-h-screen bg-surface">
      <aside className={cn('fixed inset-y-0 left-0 z-50 w-64 transform border-r border-outline bg-surface-container transition-transform lg:relative lg:translate-x-0', sidebarOpen ? 'translate-x-0' : '-translate-x-full')}>
        <div className="flex items-center justify-between border-b border-outline px-4 py-4">
          <Link href="/admin" className="flex items-center gap-2">
            <Shield className="h-6 w-6 text-primary" />
            <span className="text-lg font-display font-extrabold text-on-surface">Admin</span>
          </Link>
          <button onClick={() => setSidebarOpen(false)} className="lg:hidden cursor-pointer"><X className="h-5 w-5 text-on-surface-variant" /></button>
        </div>
        <nav className="space-y-1 px-3 py-4">
          {sidebarItems.map(item => {
            const active = pathname === item.href || (item.href !== '/admin' && pathname.startsWith(item.href));
            return (
              <Link key={item.href} href={item.href} onClick={() => setSidebarOpen(false)} className={cn('flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-body font-bold transition-colors', active ? 'bg-primary/15 text-primary' : 'text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface')}>
                <item.icon className={cn('h-5 w-5', active && 'glow-crimson-sm')} /> {item.label}
              </Link>
            );
          })}
          <button onClick={() => { logout(); router.push('/login'); }} className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm font-body font-bold text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface cursor-pointer transition-colors">
            <LogOut className="h-5 w-5" /> Logout
          </button>
        </nav>
      </aside>

      {sidebarOpen && <div className="fixed inset-0 z-40 bg-black/50 lg:hidden" onClick={() => setSidebarOpen(false)} />}

      <div className="flex-1">
        <header className="sticky top-0 z-30 border-b border-outline bg-surface-container lg:hidden">
          <div className="flex items-center justify-between px-4 py-3">
            <button onClick={() => setSidebarOpen(true)} className="cursor-pointer"><Menu className="h-5 w-5 text-on-surface" /></button>
            <span className="font-display font-extrabold text-on-surface">Admin</span>
            <div className="w-5" />
          </div>
        </header>
        <main className="p-4 lg:p-6"><ErrorBoundary>{children}</ErrorBoundary></main>
      </div>
    </div>
  );
}
