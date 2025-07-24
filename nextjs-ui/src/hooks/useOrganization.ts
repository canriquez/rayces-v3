import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { organizationApi } from '@/lib/api/endpoints';
import { handleApiError } from '@/lib/api/client';
import type { Organization } from '@/types/user';

// Query key factory
export const organizationKeys = {
  all: ['organization'] as const,
  detail: () => [...organizationKeys.all, 'detail'] as const,
};

// Hook to fetch organization data
export const useOrganizationData = () => {
  return useQuery({
    queryKey: organizationKeys.detail(),
    queryFn: organizationApi.getOrganization,
    staleTime: 10 * 60 * 1000, // 10 minutes
    retry: 1,
  });
};

// Hook to update organization
export const useUpdateOrganization = () => {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: organizationApi.updateOrganization,
    onSuccess: (data) => {
      // Update cache with new data
      queryClient.setQueryData(organizationKeys.detail(), data);
      
      // Also update the auth store if needed
      const authStore = (window as any).__authStore;
      if (authStore?.setOrganization) {
        authStore.setOrganization(data.organization);
      }
    },
    onError: (error) => {
      const message = handleApiError(error);
      console.error('Failed to update organization:', message);
    },
  });
};