import { type ReactNode } from 'react';
import { cn } from '@/lib/utils';

type BadgeVariant = 'default' | 'success' | 'warning' | 'danger' | 'info' | 'primary';

interface BadgeProps {
  children: ReactNode;
  variant?: BadgeVariant;
  className?: string;
}

const variantClasses: Record<BadgeVariant, string> = {
  default: 'bg-surface-container-high text-on-surface-variant',
  success: 'bg-tertiary/20 text-tertiary',
  warning: 'bg-yellow-500/20 text-yellow-400',
  danger: 'bg-error/20 text-error',
  info: 'bg-primary/15 text-primary',
  primary: 'bg-primary text-on-primary',
};

export function Badge({ children, variant = 'default', className }: BadgeProps) {
  return (
    <span className={cn('inline-flex items-center px-2 py-0.5 text-[11px] font-bold tracking-wider uppercase rounded-full', variantClasses[variant], className)}>
      {children}
    </span>
  );
}

export function LiveBadge() {
  return (
    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-bold tracking-wider uppercase rounded-full bg-primary/15 text-primary">
      <span className="relative flex h-2 w-2">
        <span className="absolute inline-flex h-full w-full rounded-full bg-primary opacity-75 animate-ping" />
        <span className="relative inline-flex h-2 w-2 rounded-full bg-primary" />
      </span>
      Live Now
    </span>
  );
}

export function CountdownChip({ children }: { children: ReactNode }) {
  return (
    <span className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-display font-black tracking-tight rounded-full bg-surface-container-low border border-primary/40 text-primary">
      {children}
    </span>
  );
}

export function InventoryBar({ current, max }: { current: number; max: number }) {
  const pct = max > 0 ? Math.round((current / max) * 100) : 0;
  const low = pct < 10;
  return (
    <div className="h-1.5 w-full rounded-full bg-surface-dim overflow-hidden">
      <div
        className={cn('h-full rounded-full transition-all duration-500', low ? 'bg-primary shimmer' : 'bg-primary/70')}
        style={{ width: `${pct}%` }}
      />
    </div>
  );
}
