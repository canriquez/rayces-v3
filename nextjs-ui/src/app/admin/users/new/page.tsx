'use client';

import { UserForm } from '@/components/users/UserForm';
import { useCreateUser } from '@/hooks/useUsers';
import type { CreateUserData, UpdateUserData } from '@/types/user';

export default function NewUserPage() {
  const createUser = useCreateUser();

  const handleSubmit = async (data: CreateUserData | UpdateUserData) => {
    await createUser.mutateAsync(data as CreateUserData);
  };

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900">Create New User</h1>
        <p className="mt-2 text-sm text-gray-700">
          Add a new user to the system
        </p>
      </div>

      <UserForm
        onSubmit={handleSubmit}
        isLoading={createUser.isPending}
      />
    </div>
  );
}