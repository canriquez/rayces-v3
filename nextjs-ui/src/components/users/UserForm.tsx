'use client';

import { useForm } from 'react-hook-form';
import { useRouter } from 'next/navigation';
import { handleApiError } from '@/lib/api/client';
import type { User, CreateUserData, UpdateUserData } from '@/types/user';

interface UserFormProps {
  user?: User;
  onSubmit: (data: CreateUserData | UpdateUserData) => Promise<void>;
  isLoading?: boolean;
}

type FormData = {
  first_name: string;
  last_name: string;
  email: string;
  phone?: string;
  role: User['role'];
  password?: string;
};

export function UserForm({ user, onSubmit, isLoading = false }: UserFormProps) {
  const router = useRouter();
  const isEditing = !!user;
  
  const {
    register,
    handleSubmit,
    formState: { errors },
    setError,
  } = useForm<FormData>({
    defaultValues: user ? {
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      phone: user.phone || '',
      role: user.role,
    } : {},
  });

  const handleFormSubmit = async (data: FormData) => {
    try {
      await onSubmit(data);
      router.push('/admin/users');
    } catch (error) {
      const message = handleApiError(error);
      setError('root', { message });
    }
  };

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-6 bg-white shadow px-4 py-5 sm:rounded-lg sm:p-6">
      {errors.root && (
        <div className="rounded-md bg-red-50 p-4">
          <div className="text-sm text-red-800">{errors.root.message}</div>
        </div>
      )}

      <div className="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
        <div>
          <label htmlFor="first_name" className="block text-sm font-medium text-gray-700">
            First Name
          </label>
          <input
            {...register('first_name', { required: 'First name is required' })}
            type="text"
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
          {errors.first_name && (
            <p className="mt-1 text-sm text-red-600">{String(errors.first_name?.message || '')}</p>
          )}
        </div>

        <div>
          <label htmlFor="last_name" className="block text-sm font-medium text-gray-700">
            Last Name
          </label>
          <input
            {...register('last_name', { required: 'Last name is required' })}
            type="text"
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
          {errors.last_name && (
            <p className="mt-1 text-sm text-red-600">{String(errors.last_name?.message || '')}</p>
          )}
        </div>

        <div className={isEditing ? 'sm:col-span-2' : ''}>
          <label htmlFor="email" className="block text-sm font-medium text-gray-700">
            Email
          </label>
          <input
            {...register('email', {
              required: 'Email is required',
              pattern: {
                value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                message: 'Invalid email address',
              },
            })}
            type="email"
            disabled={isEditing}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm disabled:bg-gray-100"
          />
          {errors.email && (
            <p className="mt-1 text-sm text-red-600">{String(errors.email?.message || '')}</p>
          )}
        </div>

        {!isEditing && (
          <div>
            <label htmlFor="password" className="block text-sm font-medium text-gray-700">
              Password
            </label>
            <input
              {...register('password', {
                required: 'Password is required',
                minLength: {
                  value: 6,
                  message: 'Password must be at least 6 characters',
                },
              })}
              type="password"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            />
            {errors.password && (
              <p className="mt-1 text-sm text-red-600">{String(errors.password?.message || '')}</p>
            )}
          </div>
        )}

        <div>
          <label htmlFor="phone" className="block text-sm font-medium text-gray-700">
            Phone (optional)
          </label>
          <input
            {...register('phone')}
            type="tel"
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          />
        </div>

        <div>
          <label htmlFor="role" className="block text-sm font-medium text-gray-700">
            Role
          </label>
          <select
            {...register('role', { required: 'Role is required' })}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
          >
            <option value="">Select a role</option>
            <option value="admin">Admin</option>
            <option value="professional">Professional</option>
            <option value="staff">Staff</option>
            <option value="guardian">Guardian</option>
          </select>
          {errors.role && (
            <p className="mt-1 text-sm text-red-600">{String(errors.role?.message || '')}</p>
          )}
        </div>
      </div>

      <div className="flex justify-end space-x-3">
        <button
          type="button"
          onClick={() => router.push('/admin/users')}
          className="bg-white py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={isLoading}
          className="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
        >
          {isLoading ? 'Saving...' : isEditing ? 'Update User' : 'Create User'}
        </button>
      </div>
    </form>
  );
}