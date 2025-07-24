import { useMutation } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { authApi } from '@/lib/api/endpoints';
import { useAuthStore } from '@/stores/authStore';
import { handleApiError } from '@/lib/api/client';
import type { LoginCredentials } from '@/types/user';

export const useLogin = () => {
  const router = useRouter();
  const { login, setError } = useAuthStore();

  return useMutation({
    mutationFn: (credentials: LoginCredentials) => authApi.login(credentials),
    onSuccess: (data) => {
      // Store auth data in Zustand store
      login(data.user, data.token);
      // Redirect to admin dashboard
      router.push('/admin');
    },
    onError: (error) => {
      const message = handleApiError(error);
      setError(message);
    },
  });
};

export const useLogout = () => {
  const router = useRouter();
  const { logout } = useAuthStore();

  return useMutation({
    mutationFn: authApi.logout,
    onSuccess: () => {
      // Clear auth data from Zustand store
      logout();
      // Redirect to login
      router.push('/login');
    },
    onError: (error) => {
      console.error('Logout failed:', error);
      // Even if logout fails on server, clear local state
      logout();
      router.push('/login');
    },
  });
};

export const useCurrentUser = () => {
  const { user } = useAuthStore();
  
  // This hook could be extended to refetch user data from the server
  // For now, it just returns the user from the store
  return {
    user,
    isLoading: false,
    error: null,
  };
};