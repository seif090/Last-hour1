'use client';

export default function BackButton() {
  return (
    <button onClick={() => window.history.back()} className="flex items-center gap-1 text-sm text-on-surface-variant hover:text-on-surface mb-4 cursor-pointer">
      <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M19 12H5M12 19l-7-7 7-7" />
      </svg>
      Back
    </button>
  );
}
