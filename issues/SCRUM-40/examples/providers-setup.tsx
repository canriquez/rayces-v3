// Next.js providers setup for Zustand and TanStack Query
'use client'

import { ReactNode } from 'react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { SessionProvider } from 'next-auth/react'
import { useState } from 'react'

// Create a QueryClient with proper configuration for SSR
function makeQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        // With SSR, we usually want to set some default staleTime
        // above 0 to avoid refetching immediately on the client
        staleTime: 60 * 1000, // 1 minute
        refetchOnWindowFocus: false,
        retry: 1,
      },
      mutations: {
        retry: 1,
      },
    },
  })
}

// Singleton pattern for browser client
let browserQueryClient: QueryClient | undefined = undefined

function getQueryClient() {
  if (typeof window === 'undefined') {
    // Server: always make a new query client
    return makeQueryClient()
  } else {
    // Browser: make a new query client if we don't already have one
    // This is very important, so we don't re-make a new client if React
    // suspends during the initial render
    if (!browserQueryClient) browserQueryClient = makeQueryClient()
    return browserQueryClient
  }
}

interface ProvidersProps {
  children: ReactNode
}

export default function Providers({ children }: ProvidersProps) {
  // Avoid useState when initializing the query client if you don't
  // have a suspense boundary between this and the code that may
  // suspend because React will throw away the client on the initial
  // render if it suspends and there is no boundary
  const queryClient = getQueryClient()

  return (
    <SessionProvider>
      <QueryClientProvider client={queryClient}>
        {children}
        <ReactQueryDevtools initialIsOpen={false} />
      </QueryClientProvider>
    </SessionProvider>
  )
}

// Alternative setup with additional providers for multi-tenant context
import { createContext, useContext, useState, useEffect } from 'react'
import { useSession } from 'next-auth/react'

interface Organization {
  id: string
  name: string
  subdomain: string
}

interface TenantContextType {
  organization: Organization | null
  isLoading: boolean
}

const TenantContext = createContext<TenantContextType>({
  organization: null,
  isLoading: true,
})

export const useTenant = () => {
  const context = useContext(TenantContext)
  if (!context) {
    throw new Error('useTenant must be used within TenantProvider')
  }
  return context
}

function TenantProvider({ children }: { children: ReactNode }) {
  const { data: session } = useSession()
  const [organization, setOrganization] = useState<Organization | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    if (session?.user?.organization_id) {
      // In a real app, you might fetch organization details here
      setOrganization({
        id: session.user.organization_id,
        name: session.user.organization_name || 'Unknown',
        subdomain: window.location.hostname.split('.')[0],
      })
    }
    setIsLoading(false)
  }, [session])

  return (
    <TenantContext.Provider value={{ organization, isLoading }}>
      {children}
    </TenantContext.Provider>
  )
}

// Enhanced providers with all contexts
export function EnhancedProviders({ children }: ProvidersProps) {
  const queryClient = getQueryClient()

  return (
    <SessionProvider>
      <QueryClientProvider client={queryClient}>
        <TenantProvider>
          {children}
        </TenantProvider>
        <ReactQueryDevtools initialIsOpen={false} />
      </QueryClientProvider>
    </SessionProvider>
  )
}

// Root layout integration example
/*
// app/layout.tsx
import { EnhancedProviders } from '@/lib/providers'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        <EnhancedProviders>
          {children}
        </EnhancedProviders>
      </body>
    </html>
  )
}
*/