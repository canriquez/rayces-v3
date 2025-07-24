'use client';

import Link from 'next/link';
import { useAuthStore } from '@/stores/authStore';
import { usePermission } from '@/hooks/usePermissions';

export default function AdminDashboard() {
  const { user, organization } = useAuthStore();
  
  const canManageUsers = usePermission('users.view');
  const canManageAppointments = usePermission('appointments.view');
  const canViewReports = usePermission('reports.view');
  const canManageOrganization = usePermission('organization.update');

  return (
    <div>
      <h1 className="text-3xl font-bold text-gray-900">Admin Dashboard</h1>
      
      <div className="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {/* User Info Card */}
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg font-medium text-gray-900">User Information</h3>
            <div className="mt-3 space-y-2">
              <p className="text-sm text-gray-600">
                <span className="font-medium">Name:</span> {user?.full_name}
              </p>
              <p className="text-sm text-gray-600">
                <span className="font-medium">Email:</span> {user?.email}
              </p>
              <p className="text-sm text-gray-600">
                <span className="font-medium">Role:</span>{' '}
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                  {user?.role}
                </span>
              </p>
            </div>
          </div>
        </div>

        {/* Organization Info Card */}
        {organization && (
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <h3 className="text-lg font-medium text-gray-900">Organization</h3>
              <div className="mt-3 space-y-2">
                <p className="text-sm text-gray-600">
                  <span className="font-medium">Name:</span> {organization.name}
                </p>
                <p className="text-sm text-gray-600">
                  <span className="font-medium">Subdomain:</span> {organization.subdomain}
                </p>
                <p className="text-sm text-gray-600">
                  <span className="font-medium">Status:</span>{' '}
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    organization.active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                  }`}>
                    {organization.active ? 'Active' : 'Inactive'}
                  </span>
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Permissions Card */}
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg font-medium text-gray-900">Your Permissions</h3>
            <div className="mt-3 space-y-2">
              <p className="text-sm text-gray-600">
                <span className={`inline-flex items-center ${canManageUsers ? 'text-green-600' : 'text-gray-400'}`}>
                  {canManageUsers ? '✓' : '✗'} Manage Users
                </span>
              </p>
              <p className="text-sm text-gray-600">
                <span className={`inline-flex items-center ${canManageAppointments ? 'text-green-600' : 'text-gray-400'}`}>
                  {canManageAppointments ? '✓' : '✗'} Manage Appointments
                </span>
              </p>
              <p className="text-sm text-gray-600">
                <span className={`inline-flex items-center ${canViewReports ? 'text-green-600' : 'text-gray-400'}`}>
                  {canViewReports ? '✓' : '✗'} View Reports
                </span>
              </p>
              <p className="text-sm text-gray-600">
                <span className={`inline-flex items-center ${canManageOrganization ? 'text-green-600' : 'text-gray-400'}`}>
                  {canManageOrganization ? '✓' : '✗'} Manage Organization
                </span>
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mt-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {canManageUsers && (
            <Link
              href="/admin/users"
              className="bg-white p-4 rounded-lg shadow hover:shadow-md transition-shadow text-center block"
            >
              <div className="text-2xl mb-2">👥</div>
              <p className="text-sm font-medium text-gray-900">Manage Users</p>
            </Link>
          )}
          {canManageAppointments && (
            <Link
              href="/admin/appointments"
              className="bg-white p-4 rounded-lg shadow hover:shadow-md transition-shadow text-center block"
            >
              <div className="text-2xl mb-2">📅</div>
              <p className="text-sm font-medium text-gray-900">View Appointments</p>
            </Link>
          )}
          {canViewReports && (
            <Link
              href="/admin/reports"
              className="bg-white p-4 rounded-lg shadow hover:shadow-md transition-shadow text-center block"
            >
              <div className="text-2xl mb-2">📊</div>
              <p className="text-sm font-medium text-gray-900">View Reports</p>
            </Link>
          )}
          {canManageOrganization && (
            <Link
              href="/admin/organization"
              className="bg-white p-4 rounded-lg shadow hover:shadow-md transition-shadow text-center block"
            >
              <div className="text-2xl mb-2">🏢</div>
              <p className="text-sm font-medium text-gray-900">Organization Settings</p>
            </Link>
          )}
        </div>
      </div>
    </div>
  );
}