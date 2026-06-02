import { type InputHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

export function Input({ className, label, error, id, ...props }: InputProps) {
  const inputId = id || label?.toLowerCase().replace(/\s+/g, '-');

  return (
    <div className="space-y-1.5">
      {label && (
        <label htmlFor={inputId} className="block text-xs font-bold tracking-wider uppercase text-on-surface-variant">
          {label}
        </label>
      )}
      <input
        id={inputId}
        className={cn(
          'w-full rounded-md bg-surface-container-high border px-3 py-2 text-sm text-on-surface placeholder:text-on-surface-variant/50 transition-all duration-150',
          'border-outline focus:border-primary focus:glow-crimson-sm focus:outline-none',
          error && 'border-error',
          className,
        )}
        {...props}
      />
      {error && <p className="text-xs text-error">{error}</p>}
    </div>
  );
}
