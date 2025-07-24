'use client';

import { useEffect, useState } from 'react';
import { useAuthStore } from '@/stores/authStore';

/**
 * Hook to handle auth persistence and hydration
 * Returns true when hydration is complete
 */
export function useAuthPersist() {
  const [isHydrated, setIsHydrated] = useState(false);
  const store = useAuthStore();

  useEffect(() => {
    // Check if we have persisted auth data
    const hasPersistedAuth = useAuthStore.persist.hasHydrated();
    
    if (!hasPersistedAuth) {
      // Wait for hydration
      const unsubscribe = useAuthStore.persist.onFinishHydration(() => {
        setIsHydrated(true);
      });

      // Check again in case hydration already finished
      if (useAuthStore.persist.hasHydrated()) {
        setIsHydrated(true);
      }

      return () => {
        unsubscribe();
      };
    } else {
      // Already hydrated
      setIsHydrated(true);
    }
  }, []);

  return {
    isHydrated,
    ...store
  };
}