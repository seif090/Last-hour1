import { CardSkeleton } from '@/components/skeleton';

export default function Loading() {
  return (
    <div>
      <div className="h-6 w-32 bg-surface-container-high rounded-md animate-pulse mb-4" />
      <CardSkeleton />
    </div>
  );
}
