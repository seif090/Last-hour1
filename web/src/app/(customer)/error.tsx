'use client';

import { Button } from '@/components/ui/button';
import { AlertTriangle, RefreshCw } from 'lucide-react';

export default function Error({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center py-20 text-center">
      <AlertTriangle className="h-12 w-12 text-primary mb-4" />
      <h2 className="text-xl font-display font-extrabold text-on-surface mb-2">Something went wrong</h2>
      <p className="text-sm text-on-surface-variant mb-6 max-w-md">{error.message || 'An unexpected error occurred'}</p>
      <Button onClick={reset}><RefreshCw className="h-4 w-4 mr-2" /> Try Again</Button>
    </div>
  );
}
