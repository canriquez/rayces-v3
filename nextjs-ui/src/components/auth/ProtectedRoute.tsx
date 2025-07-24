'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthPersist } from '@/hooks/useAuthPersist';
import type { User } from '@/types/user';

interface ProtectedRouteProps {
  children: React.ReactNode;
  roles?: User['role'][];
  fallbackUrl?: string;
}

export function ProtectedRoute({
  children,
  roles,
  fallbackUrl = '/login',
}: ProtectedRouteProps) {
  const router = useRouter();
  const { isAuthenticated, user, isHydrated } = useAuthPersist();

  useEffect(() => {
    // Skip check until hydration is complete
    if (!isHydrated) {
      return;
    }

    // Redirect to login if not authenticated
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }

    // Check role-based access if roles are specified
    if (roles && roles.length > 0 && user) {
      const hasRequiredRole = roles.includes(user.role);
      if (!hasRequiredRole) {
        router.push(fallbackUrl);
      }
    }
  }, [isAuthenticated, user, roles, router, fallbackUrl, isHydrated]);

  // Show loading state while hydrating
  if (!isHydrated) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  // If hydrated but not authenticated, show loading briefly before redirect
  if (!isAuthenticated) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  // Check role-based access
  if (roles && roles.length > 0 && user) {
    const hasRequiredRole = roles.includes(user.role);
    if (!hasRequiredRole) {
      return (
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-gray-900">Access Denied</h1>
            <p className="mt-2 text-gray-600">
              You don&apos;t have permission to access this page.
            </p>
            <button
              onClick={() => router.push('/admin')}
              className="mt-4 px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
            >
              Go to Dashboard
            </button>
          </div>
        </div>
      );
    }
  }

  return <>{children}</>;
}