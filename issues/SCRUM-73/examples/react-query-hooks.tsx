// React Query (TanStack Query) Hooks for User Management
// This example demonstrates how to create reusable hooks for CRUD operations
// with proper TypeScript typing, error handling, and optimistic updates

import {
  useQuery,
  useMutation,
  useQueryClient,
  UseQueryOptions,
  UseMutationOptions,
} from '@tanstack/react-query';
import { apiClient, handleApiError } from './api-client-interceptors';
import type { User } from './zustand-auth-store';

// API response types
interface UsersResponse {
  users: User[];
  meta: {
    total: number;
    page: number;
    per_page: number;
  };
}

interface UserResponse {
  user: User;
}

// API function types
interface GetUsersParams {
  page?: number;
  per_page?: number;
  role?: User['role'];
  search?: string;
}

interface CreateUserData {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  phone?: string;
  role: User['role'];
}

interface UpdateUserData {
  first_name?: string;
  last_name?: string;
  phone?: string;
  role?: User['role'];
}

interface ChangePasswordData {
  current_password: string;
  password: string;
  password_confirmation: string;
}

// API functions
const userApi = {
  getUsers: async (params: GetUsersParams = {}): Promise<UsersResponse> => {
    const { data } = await apiClient.get('/users', { params });
    return data;
  },
  
  getUser: async (id: number): Promise<UserResponse> => {
    const { data } = await apiClient.get(`/users/${id}`);
    return data;
  },
  
  createUser: async (userData: CreateUserData): Promise<UserResponse> => {
    const { data } = await apiClient.post('/users', { user: userData });
    return data;
  },
  
  updateUser: async ({ id, ...userData }: UpdateUserData & { id: number }): Promise<UserResponse> => {
    const { data } = await apiClient.patch(`/users/${id}`, { user: userData });
    return data;
  },
  
  deleteUser: async (id: number): Promise<void> => {
    await apiClient.delete(`/users/${id}`);
  },
  
  changePassword: async ({ id, ...passwords }: ChangePasswordData & { id: number }): Promise<void> => {
    await apiClient.patch(`/users/${id}/change_password`, { user: passwords });
  },
};

// Query key factory for consistent cache keys
export const userKeys = {
  all: ['users'] as const,
  lists: () => [...userKeys.all, 'list'] as const,
  list: (params: GetUsersParams) => [...userKeys.lists(), params] as const,
  details: () => [...userKeys.all, 'detail'] as const,
  detail: (id: number) => [...userKeys.details(), id] as const,
};

// Custom hooks
export const useUsers = (
  params: GetUsersParams = {},
  options?: Omit<UseQueryOptions<UsersResponse, Error>, 'queryKey' | 'queryFn'>
) => {
  return useQuery({
    queryKey: userKeys.list(params),
    queryFn: () => userApi.getUsers(params),
    staleTime: 5 * 60 * 1000, // 5 minutes
    ...options,
  });
};

export const useUser = (
  id: number,
  options?: Omit<UseQueryOptions<UserResponse, Error>, 'queryKey' | 'queryFn'>
) => {
  return useQuery({
    queryKey: userKeys.detail(id),
    queryFn: () => userApi.getUser(id),
    enabled: !!id,
    staleTime: 5 * 60 * 1000,
    ...options,
  });
};

export const useCreateUser = (
  options?: UseMutationOptions<UserResponse, Error, CreateUserData>
) => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: userApi.createUser,
    onSuccess: (data, variables, context) => {
      // Invalidate and refetch user lists
      queryClient.invalidateQueries({ queryKey: userKeys.lists() });
      
      // Optionally set the new user data in cache
      queryClient.setQueryData(userKeys.detail(data.user.id), data);
      
      // Call custom onSuccess if provided
      options?.onSuccess?.(data, variables, context);
    },
    onError: (error, variables, context) => {
      const message = handleApiError(error);
      console.error('Failed to create user:', message);
      options?.onError?.(error, variables, context);
    },
    ...options,
  });
};

export const useUpdateUser = (
  options?: UseMutationOptions<UserResponse, Error, UpdateUserData & { id: number }>
) => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: userApi.updateUser,
    onMutate: async (updatedUser) => {
      // Cancel any outgoing refetches
      await queryClient.cancelQueries({ queryKey: userKeys.detail(updatedUser.id) });
      
      // Snapshot the previous value
      const previousUser = queryClient.getQueryData(userKeys.detail(updatedUser.id));
      
      // Optimistically update to the new value
      queryClient.setQueryData(userKeys.detail(updatedUser.id), (old: UserResponse | undefined) => {
        if (!old) return old;
        return {
          ...old,
          user: { ...old.user, ...updatedUser },
        };
      });
      
      // Return a context object with the snapshotted value
      return { previousUser };
    },
    onError: (err, updatedUser, context) => {
      // If the mutation fails, use the context returned from onMutate to roll back
      if (context?.previousUser) {
        queryClient.setQueryData(userKeys.detail(updatedUser.id), context.previousUser);
      }
      const message = handleApiError(err);
      console.error('Failed to update user:', message);
      options?.onError?.(err, updatedUser, context);
    },
    onSettled: (data, error, variables) => {
      // Always refetch after error or success
      queryClient.invalidateQueries({ queryKey: userKeys.detail(variables.id) });
      queryClient.invalidateQueries({ queryKey: userKeys.lists() });
    },
    ...options,
  });
};

export const useDeleteUser = (
  options?: UseMutationOptions<void, Error, number>
) => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: userApi.deleteUser,
    onSuccess: (data, userId, context) => {
      // Remove user from cache
      queryClient.removeQueries({ queryKey: userKeys.detail(userId) });
      
      // Invalidate user lists
      queryClient.invalidateQueries({ queryKey: userKeys.lists() });
      
      options?.onSuccess?.(data, userId, context);
    },
    onError: (error, userId, context) => {
      const message = handleApiError(error);
      console.error('Failed to delete user:', message);
      options?.onError?.(error, userId, context);
    },
    ...options,
  });
};

export const useChangePassword = (
  options?: UseMutationOptions<void, Error, ChangePasswordData & { id: number }>
) => {
  return useMutation({
    mutationFn: userApi.changePassword,
    onError: (error, variables, context) => {
      const message = handleApiError(error);
      console.error('Failed to change password:', message);
      options?.onError?.(error, variables, context);
    },
    ...options,
  });
};

// Example usage in a component:
// import { useUsers, useCreateUser, useUpdateUser } from '@/hooks/useUsers';
// 
// function UserManagement() {
//   const { data, isLoading, error } = useUsers({ role: 'admin', page: 1 });
//   const createUser = useCreateUser({
//     onSuccess: (data) => {
//       toast.success(`User ${data.user.email} created successfully!`);
//     },
//   });
//   const updateUser = useUpdateUser();
//   
//   if (isLoading) return <div>Loading users...</div>;
//   if (error) return <div>Error: {error.message}</div>;
//   
//   return (
//     <div>
//       <h1>Users ({data?.meta.total})</h1>
//       <ul>
//         {data?.users.map((user) => (
//           <li key={user.id}>
//             {user.full_name} - {user.role}
//             <button onClick={() => updateUser.mutate({ id: user.id, role: 'staff' })}>
//               Make Staff
//             </button>
//           </li>
//         ))}
//       </ul>
//     </div>
//   );
// }