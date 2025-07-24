'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useUsers } from '@/hooks/useUsers';
import { usePermission } from '@/hooks/usePermissions';
import { UserTable } from '@/components/users/UserTable';

export default function UsersPage() {
  const [page, setPage] = useState(1);
  const [role, setRole] = useState<'admin' | 'professional' | 'staff' | 'guardian' | ''>('');
  
  const canCreate = usePermission('users.create');
  
  const { data, isLoading, error } = useUsers({
    page,
    per_page: 20,
    ...(role && { role: role as 'admin' | 'professional' | 'staff' | 'guardian' }),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-md bg-red-50 p-4">
        <div className="text-sm text-red-800">
          Failed to load users: {error.message}
        </div>
      </div>
    );
  }

  const totalPages = data?.meta?.total_pages || 1;

  return (
    <div>
      <div className="sm:flex sm:items-center sm:justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Users</h1>
          <p className="mt-2 text-sm text-gray-700">
            Manage user accounts and permissions
          </p>
        </div>
        {canCreate && (
          <div className="mt-4 sm:mt-0">
            <Link
              href="/admin/users/new"
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Create New User
            </Link>
          </div>
        )}
      </div>

      {/* Filters */}
      <div className="mb-6 bg-white shadow px-4 py-3 sm:rounded-lg sm:px-6">
        <div className="flex items-center space-x-4">
          <label htmlFor="role-filter" className="text-sm font-medium text-gray-700">
            Filter by role:
          </label>
          <select
            id="role-filter"
            value={role}
            onChange={(e) => {
              setRole(e.target.value as 'admin' | 'professional' | 'staff' | 'guardian' | '');
              setPage(1); // Reset to first page when filtering
            }}
            className="block w-48 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          >
            <option value="">All roles</option>
            <option value="admin">Admin</option>
            <option value="professional">Professional</option>
            <option value="staff">Staff</option>
            <option value="guardian">Guardian</option>
          </select>
        </div>
      </div>

      {/* Results summary */}
      <div className="mb-4 text-sm text-gray-700">
        Showing {data?.data?.length || 0} of {data?.meta?.total_count || 0} users
      </div>

      {/* Users table */}
      {data?.data && data.data.length > 0 ? (
        <UserTable
          users={data.data}
          currentPage={page}
          totalPages={totalPages}
          onPageChange={setPage}
        />
      ) : (
        <div className="bg-white shadow overflow-hidden sm:rounded-lg p-6 text-center text-gray-500">
          No users found
        </div>
      )}
    </div>
  );
}