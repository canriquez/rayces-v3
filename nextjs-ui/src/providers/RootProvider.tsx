'use client';

import { QueryProvider } from './QueryProvider';
import type { ReactNode } from 'react';

interface RootProviderProps {
  children: ReactNode;
}

export function RootProvider({ children }: RootProviderProps) {
  return (
    <QueryProvider>
      {/* Add other providers here as needed (e.g., ThemeProvider, ToastProvider) */}
      {children}
    </QueryProvider>
  );
}