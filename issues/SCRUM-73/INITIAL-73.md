# INITIAL-73: Build Admin Testing Interface for Role-Based Security

## Feature

Build a comprehensive admin testing interface for the new nextjs-ui folder to validate role-based security and all user actions. This interface will serve as both a testing tool and future backoffice system. The implementation will focus on creating a robust, type-safe frontend application using modern React patterns and testing practices.

### Key Requirements:
1. **Technology Stack**:
   - Next.js 15.4.3 with App Router
   - React 19.1.0 with TypeScript
   - Tailwind CSS 4.x for styling
   - Axios for API calls with interceptors
   - Zustand for state management
   - TanStack Query for server state management
   - Jest + React Testing Library for unit tests
   - Mock Service Worker (MSW) for API mocking

2. **Core Features**:
   - **Authentication System**: JWT token management with organization header support
   - **User Management CRUD**: Complete user lifecycle with role assignment
   - **Role-Based Access Control**: Five distinct roles (Admin, Professional, Staff, Client, Guest)
   - **Security Testing Interface**: Validate permissions and multi-tenant isolation
   - **Profile & Settings**: User-specific configuration and preferences

3. **Testing Requirements**:
   - 100% unit test coverage for all components and hooks
   - MSW mocks for all API endpoints
   - Component tests with different props and states
   - Hook tests with data fetching and mutations
   - Form tests with validation and submission
   - API client tests with interceptors

### Implementation Tasks:
1. **Project Setup**:
   - Initialize new Next.js 15.4.3 application in `nextjs-ui/` folder
   - Install and configure all required dependencies
   - Set up TypeScript with strict mode
   - Configure Jest and React Testing Library
   - Set up MSW for API mocking

2. **API Client Configuration**:
   - Create Axios instance with base URL configuration
   - Implement request interceptor for JWT and organization headers
   - Implement response interceptor for error handling and 401 redirects
   - Create type-safe API functions for all endpoints

3. **State Management**:
   - Set up Zustand store for authentication state
   - Implement persist middleware for session management
   - Create user store with role-based computed getters
   - Set up TanStack Query for server state caching

4. **Component Development**:
   - Admin layout with navigation and role-based menu items
   - User table with filtering, pagination, and actions
   - User form with validation and role selection
   - Login form with JWT token handling
   - Password change form with current password verification
   - Security test panel for permission validation
   - Loading states and error boundaries

5. **Testing Infrastructure**:
   - Configure Jest with TypeScript and jsdom environment
   - Set up MSW server with comprehensive mock handlers
   - Create test utilities for rendering with providers
   - Write unit tests for all components and hooks
   - Implement test coverage reporting

## Examples

- `issues/73/examples/api-client-interceptors.ts` - Comprehensive Axios configuration with JWT authentication, multi-tenancy headers, and error handling interceptors
- `issues/73/examples/zustand-auth-store.ts` - Type-safe Zustand store implementation with persist middleware, role-based computed properties, and TypeScript interfaces
- `issues/73/examples/react-query-hooks.tsx` - Reusable TanStack Query hooks for CRUD operations with optimistic updates, error handling, and TypeScript generics
- `issues/73/examples/msw-mock-handlers.ts` - Complete MSW mock server setup with all API endpoints, realistic data generators, and error simulation utilities
- `issues/73/examples/role-based-access-control.tsx` - RBAC implementation with protected routes, conditional rendering components, permission hooks, and HOCs

## Documentation

### Official Documentation
- [Next.js 15 Documentation](https://nextjs.org/docs) - App Router, Server Components, and TypeScript setup
- [React 19 Documentation](https://react.dev/) - Latest React features and patterns
- [TanStack Query Documentation](https://tanstack.com/query/latest) - Server state management and caching
- [Zustand Documentation](https://docs.pmnd.rs/zustand/getting-started/introduction) - State management with TypeScript
- [Mock Service Worker Documentation](https://mswjs.io/docs/) - API mocking for testing
- [React Testing Library Documentation](https://testing-library.com/docs/react-testing-library/intro/) - Component testing best practices
- [Axios Documentation](https://axios-http.com/docs/intro) - HTTP client with interceptors

### Architecture References
- [Next.js Authentication Patterns](https://nextjs.org/docs/app/building-your-application/authentication) - JWT and session management
- [React Query Testing Guide](https://tanstack.com/query/latest/docs/framework/react/guides/testing) - Testing hooks and queries
- [Zustand Testing Guide](https://docs.pmnd.rs/zustand/guides/testing) - Store mocking and reset strategies
- [MSW React Integration](https://mswjs.io/docs/integrations/react) - Setting up mocks for React apps

### Related Project Documentation
- Jira Issue: [SCRUM-73](https://canriquez.atlassian.net/browse/SCRUM-73)
- Confluence Guide: [SCRUM-73: Admin Testing Interface - Implementation Guide](https://canriquez.atlassian.net/wiki/spaces/SCRUM/pages/9469963)
- GitHub Issue: [#22](https://github.com/canriquez/rayces-v3/issues/22)

## Other considerations

### Environment Setup
- Create `.env.local` file with required environment variables:
  ```
  NEXT_PUBLIC_API_URL=http://localhost:4000/api/v1
  ```
- When running via `skaffold dev`:
  - Backend (Rails API) runs on port 4000
  - Frontend (Next.js) runs on port 8080
- Use `yarn` for package management to match existing Next.js projects

### Project Structure Guidelines
- Follow feature-based folder structure for better scalability
- Keep components focused and single-purpose
- Use barrel exports for cleaner imports
- Separate business logic from UI components
- Implement proper error boundaries for production readiness

### Testing Best Practices
- Write tests alongside component development (TDD approach)
- Use `data-testid` attributes for reliable element selection
- Mock external dependencies at the module boundary
- Test user interactions, not implementation details
- Ensure tests are deterministic and don't rely on timing

### Security Considerations
- Never store sensitive data in localStorage (only tokens and non-sensitive preferences)
- Implement proper CORS handling in development
- Use HTTPS in production environment
- Validate all user inputs on both client and server
- Implement rate limiting for API calls
- Handle token expiration gracefully with refresh logic

### Performance Optimization
- Use React Server Components where possible
- Implement code splitting for large components
- Optimize bundle size with tree shaking
- Use React.memo for expensive components
- Implement virtual scrolling for large lists
- Enable Tailwind CSS purging for production builds

### Development Workflow
- Run `skaffold dev` from the project root to start the full stack (backend on port 4000, frontend on port 8080)
- Or for standalone development:
  - Run `yarn dev` for local Next.js development with hot reload
  - Run `yarn test` for unit tests with coverage
  - Run `yarn test:watch` for test-driven development
  - Run `yarn build` to verify production build
  - Run `yarn lint` to check code quality
  - Run `yarn typecheck` to verify TypeScript types

### Known Limitations
- Professional and Student endpoints are not yet implemented in the backend
- Focus initial implementation on User, Organization, and Appointment endpoints
- OAuth/SSO integration will be added in future sprints
- Real-time features (WebSocket) will be implemented separately
- File upload functionality is out of scope for this ticket

### Success Metrics
- Zero security vulnerabilities in role-based access implementation
- Sub-200ms response times for all UI interactions
- 100% unit test coverage with all tests passing
- Successful validation of all 5 user roles
- Clean separation between UI unit tests and future E2E tests (SCRUM-74)