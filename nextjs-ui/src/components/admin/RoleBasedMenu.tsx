'use client';

import { usePermissions } from '@/hooks/usePermissions';
import type { Permission } from '@/hooks/usePermissions';

interface MenuItem {
  label: string;
  href?: string;
  onClick?: () => void;
  permission?: Permission;
  icon?: React.ReactNode;
  className?: string;
}

interface RoleBasedMenuProps {
  items: MenuItem[];
  className?: string;
}

export function RoleBasedMenu({ items, className = '' }: RoleBasedMenuProps) {
  const permissions = usePermissions();
  
  // Filter items based on permissions
  const visibleItems = items.filter((item) => {
    if (!item.permission) return true;
    return permissions[item.permission] || false;
  });

  if (visibleItems.length === 0) {
    return null;
  }

  return (
    <div className={`space-y-1 ${className}`}>
      {visibleItems.map((item, index) => {
        const Component = item.href ? 'a' : 'button';
        
        return (
          <Component
            key={index}
            href={item.href}
            onClick={item.onClick}
            className={`
              flex items-center space-x-3 px-3 py-2 text-sm font-medium rounded-md
              transition-colors duration-150
              ${item.className || 'text-gray-700 hover:text-gray-900 hover:bg-gray-100'}
            `}
          >
            {item.icon && <span className="text-gray-400">{item.icon}</span>}
            <span>{item.label}</span>
          </Component>
        );
      })}
    </div>
  );
}

// Example usage with common menu items
export function UserActionsMenu({ userId }: { userId: number }) {
  const menuItems: MenuItem[] = [
    {
      label: 'View Details',
      href: `/admin/users/${userId}`,
      permission: 'users.view',
    },
    {
      label: 'Edit User',
      href: `/admin/users/${userId}/edit`,
      permission: 'users.update',
    },
    {
      label: 'Change Password',
      href: `/admin/users/${userId}/password`,
      permission: 'users.update',
    },
    {
      label: 'Delete User',
      onClick: () => console.log('Delete user', userId),
      permission: 'users.delete',
      className: 'text-red-600 hover:text-red-700 hover:bg-red-50',
    },
  ];

  return <RoleBasedMenu items={menuItems} />;
}