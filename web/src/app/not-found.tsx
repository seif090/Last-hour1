import Link from 'next/link';
import { Clock } from 'lucide-react';

export default function NotFound() {
  return (
    <div className="min-h-screen bg-surface flex flex-col items-center justify-center text-center px-4">
      <Clock className="h-16 w-16 text-primary mb-6" />
      <h1 className="text-6xl font-display font-black text-on-surface mb-2">404</h1>
      <p className="text-xl font-display font-bold text-on-surface mb-2">Time&apos;s Up</p>
      <p className="text-sm text-on-surface-variant mb-8 max-w-sm">
        This page doesn&apos;t exist or has expired. Let&apos;s get you back to the deals.
      </p>
      <Link
        href="/offers"
        className="inline-flex items-center justify-center h-12 px-8 text-sm font-bold rounded-md bg-primary text-on-primary glow-crimson transition-all hover:brightness-110"
      >
        Browse Offers
      </Link>
    </div>
  );
}
