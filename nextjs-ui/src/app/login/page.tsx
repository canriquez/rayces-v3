'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { LoginForm } from '@/components/auth/LoginForm';
import { useAuthPersist } from '@/hooks/useAuthPersist';

export default function LoginPage() {
  const router = useRouter();
  const { isAuthenticated, isHydrated } = useAuthPersist();

  useEffect(() => {
    // If already authenticated, redirect to admin
    if (isHydrated && isAuthenticated) {
      router.push('/admin');
    }
  }, [isAuthenticated, isHydrated, router]);

  // Show loading while checking auth
  if (!isHydrated) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  // If authenticated, show loading while redirecting
  if (isAuthenticated) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return <LoginForm />;
}