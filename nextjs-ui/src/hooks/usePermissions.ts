import { useAuthStore } from '@/stores/authStore';
import type { User } from '@/types/user';

// Permission types
export type Permission = 
  | 'users.view'
  | 'users.create'
  | 'users.update'
  | 'users.delete'
  | 'appointments.view'
  | 'appointments.create'
  | 'appointments.update'
  | 'appointments.cancel'
  | 'organization.view'
  | 'organization.update'
  | 'reports.view'
  | 'reports.create';

// Role-permission mapping
const rolePermissions: Record<User['role'], Permission[]> = {
  admin: [
    'users.view', 'users.create', 'users.update', 'users.delete',
    'appointments.view', 'appointments.create', 'appointments.update', 'appointments.cancel',
    'organization.view', 'organization.update',
    'reports.view', 'reports.create',
  ],
  professional: [
    'appointments.view', 'appointments.update',
    'reports.view', 'reports.create',
  ],
  staff: [
    'users.view', 'users.create', 'users.update',
    'appointments.view', 'appointments.create', 'appointments.update', 'appointments.cancel',
    'reports.view',
  ],
  guardian: [
    'appointments.view',
    'reports.view',
  ],
};

// Hook to check permissions
export const usePermission = (permission: Permission | Permission[]): boolean => {
  const user = useAuthStore((state) => state.user);
  
  if (!user) return false;
  
  const userPermissions = rolePermissions[user.role] || [];
  
  if (Array.isArray(permission)) {
    // Check if user has ANY of the requested permissions
    return permission.some(p => userPermissions.includes(p));
  }
  
  return userPermissions.includes(permission);
};

// Hook to get all permissions as an object
export const usePermissions = (): Record<Permission, boolean> => {
  const user = useAuthStore((state) => state.user);
  
  if (!user) {
    return Object.keys(rolePermissions).reduce((acc, role) => {
      rolePermissions[role as keyof typeof rolePermissions].forEach((permission: Permission) => {
        acc[permission] = false;
      });
      return acc;
    }, {} as Record<Permission, boolean>);
  }
  
  const userPermissions = rolePermissions[user.role] || [];
  const allPermissions = Object.values(rolePermissions).flat();
  const uniquePermissions = Array.from(new Set(allPermissions)) as Permission[];
  
  return uniquePermissions.reduce((acc, permission) => {
    acc[permission] = userPermissions.includes(permission);
    return acc;
  }, {} as Record<Permission, boolean>);
};

// Hook to check if user has specific role(s)
export const useRole = (roles: User['role'] | User['role'][]): boolean => {
  const user = useAuthStore((state) => state.user);
  
  if (!user) return false;
  
  if (Array.isArray(roles)) {
    return roles.includes(user.role);
  }
  
  return user.role === roles;
};

// Hook to get all user permissions
export const useUserPermissions = (): Permission[] => {
  const user = useAuthStore((state) => state.user);
  
  if (!user) return [];
  
  return rolePermissions[user.role] || [];
};

// Convenience hooks for common permission checks
export const useCanManageUsers = () => usePermission(['users.create', 'users.update', 'users.delete']);
export const useCanViewUsers = () => usePermission('users.view');
export const useCanManageAppointments = () => usePermission(['appointments.create', 'appointments.update', 'appointments.cancel']);
export const useCanViewAppointments = () => usePermission('appointments.view');
export const useCanManageOrganization = () => usePermission('organization.update');
export const useCanCreateReports = () => usePermission('reports.create');