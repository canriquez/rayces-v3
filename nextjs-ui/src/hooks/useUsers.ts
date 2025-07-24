import {
  useQuery,
  useMutation,
  useQueryClient,
  UseQueryOptions,
  UseMutationOptions,
} from '@tanstack/react-query';
import { userApi } from '@/lib/api/endpoints';
import { handleApiError } from '@/lib/api/client';
import type {
  UsersResponse,
  UserResponse,
  GetUsersParams,
} from '@/types/api';
import type {
  CreateUserData,
  UpdateUserData,
  ChangePasswordData,
} from '@/types/user';

// Query key factory for consistent cache keys
export const userKeys = {
  all: ['users'] as const,
  lists: () => [...userKeys.all, 'list'] as const,
  list: (params: GetUsersParams) => [...userKeys.lists(), params] as const,
  details: () => [...userKeys.all, 'detail'] as const,
  detail: (id: number) => [...userKeys.details(), id] as const,
};

// Hook to fetch users list
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

// Hook to fetch single user
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

// Hook to create user
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

// Hook to update user
export const useUpdateUser = (
  options?: UseMutationOptions<UserResponse, Error, UpdateUserData & { id: number }>
) => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: userApi.updateUser,
    // TODO: Fix TypeScript issue with onMutate return type
    // onMutate: async (updatedUser) => {
    //   await queryClient.cancelQueries({ queryKey: userKeys.detail(updatedUser.id) });
    //   const previousUser = queryClient.getQueryData(userKeys.detail(updatedUser.id));
    //   queryClient.setQueryData(userKeys.detail(updatedUser.id), (old: UserResponse | undefined) => {
    //     if (!old) return old;
    //     return { ...old, user: { ...old.user, ...updatedUser } };
    //   });
    //   return { previousUser };
    // },
    onError: (err, updatedUser) => {
      const message = handleApiError(err);
      console.error('Failed to update user:', message);
      options?.onError?.(err, updatedUser, undefined);
    },
    onSettled: (data, error, variables) => {
      // Always refetch after error or success
      queryClient.invalidateQueries({ queryKey: userKeys.detail(variables.id) });
      queryClient.invalidateQueries({ queryKey: userKeys.lists() });
    },
    ...options,
  });
};

// Hook to delete user
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

// Hook to change password
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