'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function CustomerHome() {
  const router = useRouter();
  useEffect(() => { router.replace('/offers'); }, [router]);
  return null;
}
