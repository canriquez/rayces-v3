// Role-Based Access Control Components and Hooks
// This example demonstrates how to implement RBAC in React components
// with route guards, conditional rendering, and permission checks

import React, { PropsWithChildren, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore, User } from './zustand-auth-store';

// Permission types
type Permission = 
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

// Hook to check if user has specific role(s)
export const useRole = (roles: User['role'] | User['role'][]): boolean => {
  const user = useAuthStore((state) => state.user);
  
  if (!user) return false;
  
  if (Array.isArray(roles)) {
    return roles.includes(user.role);
  }
  
  return user.role === roles;
};

// Protected route component
interface ProtectedRouteProps {
  roles?: User['role'][];
  permissions?: Permission[];
  fallbackUrl?: string;
  children: React.ReactNode;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({
  roles,
  permissions,
  fallbackUrl = '/unauthorized',
  children,
}) => {
  const router = useRouter();
  const { isAuthenticated, user } = useAuthStore();
  const hasRole = useRole(roles || []);
  const hasPermission = usePermission(permissions || []);
  
  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login');
      return;
    }
    
    const hasAccess = 
      (!roles || roles.length === 0 || hasRole) &&
      (!permissions || permissions.length === 0 || hasPermission);
    
    if (!hasAccess) {
      router.push(fallbackUrl);
    }
  }, [isAuthenticated, hasRole, hasPermission, router, fallbackUrl, roles, permissions]);
  
  // Show loading state while checking auth
  if (!isAuthenticated) {
    return <div>Loading...</div>;
  }
  
  // Check access
  const hasAccess = 
    (!roles || roles.length === 0 || hasRole) &&
    (!permissions || permissions.length === 0 || hasPermission);
  
  if (!hasAccess) {
    return null;
  }
  
  return <>{children}</>;
};

// Conditional rendering component
interface CanProps {
  perform?: Permission | Permission[];
  role?: User['role'] | User['role'][];
  fallback?: React.ReactNode;
  children: React.ReactNode;
}

export const Can: React.FC<CanProps> = ({
  perform,
  role,
  fallback = null,
  children,
}) => {
  const hasPermission = usePermission(perform || []);
  const hasRole = useRole(role || []);
  
  const canAccess = 
    (!perform || hasPermission) &&
    (!role || hasRole);
  
  return canAccess ? <>{children}</> : <>{fallback}</>;
};

// Higher-order component for role protection
export function withRole<P extends object>(
  Component: React.ComponentType<P>,
  allowedRoles: User['role'][],
  FallbackComponent?: React.ComponentType
) {
  return function ProtectedComponent(props: P) {
    const hasRole = useRole(allowedRoles);
    
    if (!hasRole) {
      return FallbackComponent ? <FallbackComponent /> : null;
    }
    
    return <Component {...props} />;
  };
}

// Role-specific layout wrapper
interface RoleLayoutProps extends PropsWithChildren {
  title: string;
}

export const AdminLayout: React.FC<RoleLayoutProps> = ({ title, children }) => {
  return (
    <ProtectedRoute roles={['admin']}>
      <div className="admin-layout">
        <header className="bg-red-600 text-white p-4">
          <h1>{title} - Admin Dashboard</h1>
        </header>
        <nav className="bg-gray-100 p-4">
          <Can perform="users.view">
            <a href="/admin/users" className="mr-4">Users</a>
          </Can>
          <Can perform="organization.view">
            <a href="/admin/organization" className="mr-4">Organization</a>
          </Can>
          <Can perform="reports.view">
            <a href="/admin/reports" className="mr-4">Reports</a>
          </Can>
        </nav>
        <main className="p-4">{children}</main>
      </div>
    </ProtectedRoute>
  );
};

// Example usage in components
export const UserManagementPage: React.FC = () => {
  const canCreateUser = usePermission('users.create');
  const canDeleteUser = usePermission('users.delete');
  const isAdmin = useRole('admin');
  
  return (
    <AdminLayout title="User Management">
      <div>
        <h2>Users</h2>
        
        {/* Conditional button rendering */}
        <Can perform="users.create">
          <button className="btn-primary">Create New User</button>
        </Can>
        
        {/* Alternative conditional rendering */}
        {canCreateUser && (
          <button className="btn-secondary">Import Users</button>
        )}
        
        {/* Role-based UI variation */}
        {isAdmin ? (
          <p>You have full access to all user operations.</p>
        ) : (
          <p>You have limited access to user operations.</p>
        )}
        
        {/* Table with conditional actions */}
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Role</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {/* User rows */}
            <tr>
              <td>John Doe</td>
              <td>john@example.com</td>
              <td>Staff</td>
              <td>
                <Can perform="users.update">
                  <button>Edit</button>
                </Can>
                <Can 
                  perform="users.delete"
                  fallback={<span className="text-gray-400">Delete</span>}
                >
                  <button className="text-red-600">Delete</button>
                </Can>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </AdminLayout>
  );
};

// Protected API hook wrapper
export const useProtectedQuery = (
  queryFn: () => Promise<any>,
  options: {
    enabled?: boolean;
    requiredPermissions?: Permission[];
    requiredRoles?: User['role'][];
  } = {}
) => {
  const hasPermission = usePermission(options.requiredPermissions || []);
  const hasRole = useRole(options.requiredRoles || []);
  
  const hasAccess = 
    (!options.requiredPermissions || hasPermission) &&
    (!options.requiredRoles || hasRole);
  
  // Only enable query if user has access
  const enabled = options.enabled !== false && hasAccess;
  
  // You would use this with React Query
  // return useQuery({
  //   queryKey: ['protected-data'],
  //   queryFn,
  //   enabled,
  // });
  
  return { enabled, hasAccess };
};

// Example page using multiple protection methods
export const SecureAdminPage: React.FC = () => {
  return (
    <ProtectedRoute 
      roles={['admin', 'staff']} 
      permissions={['users.view']}
      fallbackUrl="/dashboard"
    >
      <AdminLayout title="Secure Admin Area">
        <Can 
          perform={['users.create', 'users.update']}
          role="admin"
          fallback={
            <div className="alert alert-warning">
              You need admin privileges to manage users.
            </div>
          }
        >
          <UserManagementPage />
        </Can>
      </AdminLayout>
    </ProtectedRoute>
  );
};