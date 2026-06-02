import { type ButtonHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
}

export function Button({ className, variant = 'primary', size = 'md', loading, disabled, children, ...props }: ButtonProps) {
  const base = 'inline-flex items-center justify-center font-body font-bold transition-all duration-150 disabled:opacity-40 disabled:pointer-events-none cursor-pointer';

  const variants: Record<string, string> = {
    primary: 'bg-primary text-on-primary glow-crimson-sm hover:glow-crimson active:brightness-110',
    secondary: 'bg-surface-container-high text-on-surface border border-outline hover:bg-surface-container-highest',
    outline: 'border-2 border-primary text-primary hover:bg-primary/10',
    ghost: 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container-high',
    danger: 'bg-error text-on-error hover:brightness-110',
  };

  const sizes: Record<string, string> = {
    sm: 'h-8 px-3 text-xs rounded-md',
    md: 'h-10 px-5 text-sm rounded-md',
    lg: 'h-12 px-7 text-base rounded-lg',
  };

  return (
    <button
      className={cn(base, variants[variant], sizes[size], className)}
      disabled={disabled || loading}
      {...props}
    >
      {loading && (
        <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
      )}
      {children}
    </button>
  );
}
