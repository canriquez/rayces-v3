# INITIAL-SCRUM-40.md

## Feature

### Initialize Next.js App & Configure State Management

This story focuses on extending the existing MyHub Next.js application with state management capabilities specifically designed for the Rayces V3 booking platform. The implementation builds upon the operational MyHub foundation while preserving all existing social media functionality.

**Key Requirements:**
- **Extend MyHub Foundation**: Build upon the existing Next.js 14 app with working components, authentication, and UI patterns
- **Zustand State Management**: Implement local UI state management for booking flows, professional schedules, and client interactions
- **TanStack Query Integration**: Configure server state management for API data fetching, caching, and synchronization
- **Multi-tenant Support**: Ensure state management respects organization boundaries and tenant isolation
- **TypeScript Configuration**: Full type safety across all state management implementations
- **Developer Experience**: Set up React Query DevTools and Zustand DevTools for debugging

### Implementation Tasks:

1. **Install State Management Dependencies**
   - Add Zustand for local UI state
   - Add @tanstack/react-query for server state
   - Add @tanstack/react-query-devtools for debugging
   - Configure axios for API client

2. **Configure Query Client Provider**
   - Set up QueryClientProvider with SSR-friendly configuration
   - Implement singleton pattern for browser client
   - Configure default options for staleTime and refetch behavior
   - Integrate with existing NextAuth.js SessionProvider

3. **Create Zustand Stores**
   - **BookingStore**: Multi-step booking flow state
   - **ProfessionalStore**: Professional-specific state and schedule management
   - **ClientStore**: Client/parent state for student management
   - Implement persist middleware for critical UI state
   - Configure devtools integration

4. **Implement API Hooks with React Query**
   - Professional availability queries
   - Student data fetching
   - Appointment creation mutations
   - Implement proper cache invalidation strategies
   - Add prefetch utilities for SSR

5. **Multi-tenant Context Integration**
   - Create TenantProvider for organization context
   - Ensure all API calls include organization scope
   - Implement tenant-aware state isolation

6. **Type Safety Implementation**
   - Define comprehensive TypeScript interfaces
   - Configure module augmentation for React Query
   - Implement type-safe store selectors
   - Add proper error type definitions

## Examples

- `issues/SCRUM-40/examples/booking-store-zustand.ts` - Complete Zustand store implementation for booking flow with TypeScript, devtools, and persist middleware
- `issues/SCRUM-40/examples/api-hooks-tanstack-query.tsx` - TanStack Query hooks for all booking-related API operations with proper typing and cache management
- `issues/SCRUM-40/examples/providers-setup.tsx` - Next.js providers configuration for both Zustand and React Query with SSR support
- `issues/SCRUM-40/examples/booking-wizard-component.tsx` - Full booking wizard implementation showing integration of both state management solutions
- `issues/SCRUM-40/examples/professional-store.ts` - Professional-specific Zustand store with schedule management and computed values

## Documentation

### Zustand Documentation
- [Zustand Official Documentation](https://github.com/pmndrs/zustand)
- [Zustand TypeScript Guide](https://docs.pmnd.rs/zustand/guides/typescript)
- [Zustand Persist Middleware](https://docs.pmnd.rs/zustand/integrations/persisting-store-data)
- [Zustand DevTools Integration](https://docs.pmnd.rs/zustand/guides/redux-devtools)

### TanStack Query Documentation
- [TanStack Query Official Docs](https://tanstack.com/query/latest)
- [React Query SSR Guide](https://tanstack.com/query/latest/docs/framework/react/guides/ssr)
- [React Query with Next.js](https://tanstack.com/query/latest/docs/framework/react/guides/advanced-ssr)
- [TypeScript with React Query](https://tanstack.com/query/latest/docs/framework/react/typescript)

### Next.js Integration
- [Next.js Client Components](https://nextjs.org/docs/app/building-your-application/rendering/client-components)
- [Next.js Context Providers](https://nextjs.org/docs/app/building-your-application/rendering/composition-patterns#using-context-providers)
- [NextAuth.js Session Management](https://next-auth.js.org/getting-started/client#usesession)

### Multi-tenancy Resources
- [Multi-tenant Architecture Patterns](https://docs.microsoft.com/en-us/azure/architecture/guide/multitenant/overview)
- [React Context for Multi-tenancy](https://kentcdodds.com/blog/how-to-use-react-context-effectively)

## Other considerations

### Building on MyHub Foundation
- **Preserve Existing Functionality**: All MyHub social media features must continue working
- **Component Reuse**: Leverage existing UI components and patterns where possible
- **Authentication Integration**: Extend NextAuth.js session with organization context
- **Incremental Migration**: Allow gradual transformation of MyHub components to booking features

### State Management Best Practices
- **Separation of Concerns**: Keep UI state in Zustand, server state in React Query
- **Selective Subscriptions**: Use Zustand selectors to prevent unnecessary re-renders
- **Cache Management**: Implement proper cache invalidation strategies for React Query
- **Persist Critical State**: Only persist non-sensitive UI state to localStorage
- **Error Boundaries**: Implement error boundaries for state management failures

### Performance Optimization
- **Code Splitting**: Lazy load state management stores when needed
- **Memoization**: Use React.memo and useMemo for expensive computations
- **Batch Updates**: Configure React Query batch notifications
- **Debouncing**: Implement debouncing for search and filter operations
- **Prefetching**: Use React Query prefetch for predictable user navigation

### Security Considerations
- **No Sensitive Data in Stores**: Never store passwords, tokens, or PII in Zustand
- **Token Management**: Let NextAuth.js handle all authentication tokens
- **API Authorization**: Ensure all API calls include proper authorization headers
- **Tenant Isolation**: Verify organization context on every API request
- **State Cleanup**: Clear sensitive state on logout

### Testing Strategy
- **Unit Tests**: Test individual store actions and selectors
- **Integration Tests**: Test React Query hooks with MSW (Mock Service Worker)
- **Component Tests**: Use React Testing Library with proper providers
- **E2E Tests**: Ensure state persistence works across page reloads

### Development Workflow
1. Check current branch and pull latest changes
2. Review CHANGELOG.md for recent modifications
3. Run tests before making changes
4. Update CHANGELOG.md with all modifications
5. Ensure TypeScript compilation passes
6. Verify no regressions in MyHub functionality

### Environment Configuration
```env
# .env.local example
NEXT_PUBLIC_API_URL=http://localhost:3001/api/v1
```

### Monitoring and Debugging
- Use React Query DevTools to monitor cache state
- Use Redux DevTools Extension for Zustand stores
- Implement proper error logging for failed queries
- Monitor state hydration issues in production
- Track performance metrics for state updates