import { StatsCardSkeleton, TableSkeleton } from '@/components/skeleton';

export default function Loading() {
  return (
    <div>
      <div className="grid grid-cols-2 gap-4 mb-8">
        <StatsCardSkeleton />
        <StatsCardSkeleton />
        <StatsCardSkeleton />
        <StatsCardSkeleton />
      </div>
      <TableSkeleton rows={8} cols={4} />
    </div>
  );
}
