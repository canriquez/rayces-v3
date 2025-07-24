'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuthStore } from '@/stores/authStore';
import { useLogout } from '@/hooks/useAuth';
import { usePermission } from '@/hooks/usePermissions';

interface NavItem {
  href: string;
  label: string;
  permission?: string;
}

const navItems: NavItem[] = [
  { href: '/admin', label: 'Dashboard' },
  { href: '/admin/users', label: 'Users', permission: 'users.view' },
  { href: '/admin/appointments', label: 'Appointments', permission: 'appointments.view' },
  { href: '/admin/reports', label: 'Reports', permission: 'reports.view' },
  { href: '/admin/organization', label: 'Organization', permission: 'organization.view' },
];

export function AdminNav() {
  const pathname = usePathname();
  const { user } = useAuthStore();
  const logout = useLogout();
  
  // Check all permissions upfront
  const canViewUsers = usePermission('users.view');
  const canViewAppointments = usePermission('appointments.view');
  const canViewReports = usePermission('reports.view');
  const canViewOrganization = usePermission('organization.view');
  
  const permissions: Record<string, boolean> = {
    'users.view': canViewUsers,
    'appointments.view': canViewAppointments,
    'reports.view': canViewReports,
    'organization.view': canViewOrganization,
  };
  
  const isActive = (href: string) => {
    if (href === '/admin') {
      return pathname === href;
    }
    return pathname.startsWith(href);
  };

  return (
    <nav className="bg-gray-800">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <h1 className="text-white text-xl font-bold">Admin Panel</h1>
            </div>
            <div className="ml-10 flex items-baseline space-x-4">
              {navItems.map((item) => {
                // Check permission if required
                if (item.permission && !permissions[item.permission]) {
                  return null;
                }
                
                const active = isActive(item.href);
                
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={`px-3 py-2 rounded-md text-sm font-medium ${
                      active
                        ? 'bg-gray-900 text-white'
                        : 'text-gray-300 hover:bg-gray-700 hover:text-white'
                    }`}
                  >
                    {item.label}
                  </Link>
                );
              })}
            </div>
          </div>
          
          <div className="flex items-center space-x-4">
            <div className="text-gray-300 text-sm">
              <span>{user?.full_name}</span>
              <span className="ml-2 text-xs text-gray-400">({user?.role})</span>
            </div>
            <button
              onClick={() => logout.mutate()}
              disabled={logout.isPending}
              className="text-gray-300 hover:text-white text-sm font-medium"
            >
              {logout.isPending ? 'Logging out...' : 'Logout'}
            </button>
          </div>
        </div>
      </div>
    </nav>
  );
}