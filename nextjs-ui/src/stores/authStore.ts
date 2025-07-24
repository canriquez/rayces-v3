// Zustand Auth Store with TypeScript and Persist Middleware
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { devtools } from 'zustand/middleware';
import { User, Organization } from '@/types/user';

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
          if (typeof window !== 'undefined') {
            localStorage.setItem('auth_token', token);
            
            // Store organization subdomain if available
            if (user.organization?.subdomain) {
              localStorage.setItem('organization_subdomain', user.organization.subdomain);
            }
            
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
          if (typeof window !== 'undefined') {
            localStorage.removeItem('auth_token');
            localStorage.removeItem('organization_subdomain');
          }
          
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
          if (typeof window !== 'undefined') {
            localStorage.setItem('organization_subdomain', organization.subdomain);
          }
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