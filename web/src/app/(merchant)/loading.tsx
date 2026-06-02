import { CardSkeleton } from '@/components/skeleton';

export default function Loading() {
  return (
    <div>
      <div className="h-8 w-48 bg-surface-container-high rounded-md animate-pulse mb-6" />
      <div className="space-y-4">
        <CardSkeleton />
        <CardSkeleton />
        <CardSkeleton />
      </div>
    </div>
  );
}
