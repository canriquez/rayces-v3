// Zustand Auth Store with TypeScript
// This example shows how to create a type-safe authentication store
// with persist middleware for session management

import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { devtools } from 'zustand/middleware';

// Types for user and organization
export interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone?: string;
  role: 'admin' | 'professional' | 'staff' | 'guardian';
  created_at: string;
  updated_at: string;
  organization?: Organization;
}

export interface Organization {
  id: number;
  name: string;
  subdomain: string;
  phone?: string;
  address?: string;
  active: boolean;
  created_at: string;
  updated_at: string;
  email?: string;
  settings?: Record<string, any>;
}

// Auth store state interface
interface AuthState {
  // State
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  organization: Organization | null;
  
  // Actions
  login: (user: User, token: string) => void;
  logout: () => void;
  updateUser: (user: Partial<User>) => void;
  setOrganization: (organization: Organization) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  clearError: () => void;
  
  // Computed getters
  hasRole: (role: User['role']) => boolean;
  isAdmin: () => boolean;
  isProfessional: () => boolean;
  isStaff: () => boolean;
  isGuardian: () => boolean;
}

// Create the auth store with persist middleware
export const useAuthStore = create<AuthState>()(
  devtools(
    persist(
      (set, get) => ({
        // Initial state
        user: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
        error: null,
        organization: null,
        
        // Actions
        login: (user, token) => {
          // Store token in localStorage for interceptors
          localStorage.setItem('auth_token', token);
          
          // Store organization subdomain if available
          if (user.organization?.subdomain) {
            localStorage.setItem('organization_subdomain', user.organization.subdomain);
          }
          
          set({
            user,
            token,
            isAuthenticated: true,
            error: null,
            organization: user.organization || null,
          });
        },
        
        logout: () => {
          // Clear all auth data from localStorage
          localStorage.removeItem('auth_token');
          localStorage.removeItem('organization_subdomain');
          
          set({
            user: null,
            token: null,
            isAuthenticated: false,
            error: null,
            organization: null,
          });
        },
        
        updateUser: (updates) => {
          const currentUser = get().user;
          if (currentUser) {
            set({
              user: { ...currentUser, ...updates },
            });
          }
        },
        
        setOrganization: (organization) => {
          // Update organization subdomain in localStorage
          localStorage.setItem('organization_subdomain', organization.subdomain);
          set({ organization });
        },
        
        setLoading: (loading) => set({ isLoading: loading }),
        
        setError: (error) => set({ error }),
        
        clearError: () => set({ error: null }),
        
        // Computed getters
        hasRole: (role) => {
          const user = get().user;
          return user?.role === role || false;
        },
        
        isAdmin: () => get().hasRole('admin'),
        isProfessional: () => get().hasRole('professional'),
        isStaff: () => get().hasRole('staff'),
        isGuardian: () => get().hasRole('guardian'),
      }),
      {
        name: 'auth-storage', // unique name for localStorage
        storage: createJSONStorage(() => localStorage),
        partialize: (state) => ({
          // Only persist these fields
          user: state.user,
          token: state.token,
          isAuthenticated: state.isAuthenticated,
          organization: state.organization,
        }),
      }
    ),
    {
      name: 'AuthStore', // name for Redux DevTools
    }
  )
);

// Selector hooks for common use cases
export const useUser = () => useAuthStore((state) => state.user);
export const useIsAuthenticated = () => useAuthStore((state) => state.isAuthenticated);
export const useUserRole = () => useAuthStore((state) => state.user?.role);
export const useOrganization = () => useAuthStore((state) => state.organization);

// Hook to check if user has specific permissions
export const useHasPermission = (requiredRoles: User['role'][]) => {
  const userRole = useUserRole();
  return userRole ? requiredRoles.includes(userRole) : false;
};

// Example usage:
// import { useAuthStore, useUser, useHasPermission } from '@/stores/authStore';
// 
// function MyComponent() {
//   const { login, logout, isAuthenticated } = useAuthStore();
//   const user = useUser();
//   const canManageUsers = useHasPermission(['admin', 'staff']);
//   
//   const handleLogin = async (credentials) => {
//     try {
//       const response = await apiClient.post('/login', credentials);
//       login(response.data.user, response.data.token);
//     } catch (error) {
//       console.error('Login failed:', error);
//     }
//   };
//   
//   return (
//     <div>
//       {isAuthenticated ? (
//         <p>Welcome, {user?.full_name}!</p>
//       ) : (
//         <button onClick={() => handleLogin({ email, password })}>Login</button>
//       )}
//     </div>
//   );
// }