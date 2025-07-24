import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useUsers, useUser, useCreateUser, useUpdateUser, useDeleteUser } from '@/hooks/useUsers';
import { server } from '@/__tests__/mocks/server';
import { http, HttpResponse } from 'msw';
import { act } from 'react';

// Helper to create wrapper with QueryClient
const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

  const Wrapper = ({ children }: { children: React.ReactNode }) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  );
  Wrapper.displayName = 'QueryClientWrapper';
  return Wrapper;
};

describe('useUsers', () => {
  it('fetches users successfully', async () => {
    const { result } = renderHook(() => useUsers(), {
      wrapper: createWrapper(),
    });

    // Initially loading
    expect(result.current.isLoading).toBe(true);
    expect(result.current.data).toBeUndefined();

    // Wait for data
    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data?.data).toHaveLength(4);
    expect(result.current.data?.data[0].email).toBe('admin@rayces.com');
  });

  it('filters users by role', async () => {
    const { result } = renderHook(() => useUsers({ role: 'admin' }), {
      wrapper: createWrapper(),
    });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    // Should only return admin users
    const adminUsers = result.current.data?.data.filter(u => u.role === 'admin');
    expect(adminUsers).toHaveLength(1);
  });

  it('handles pagination parameters', async () => {
    const { result } = renderHook(() => useUsers({ page: 2, per_page: 2 }), {
      wrapper: createWrapper(),
    });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data?.meta.current_page).toBe(2);
    expect(result.current.data?.meta.per_page).toBe(2);
  });

  it('handles server errors', async () => {
    server.use(
      http.get('http://localhost:4000/api/v1/users', () => {
        return HttpResponse.json(
          { error: 'Internal server error' },
          { status: 500 }
        );
      })
    );

    const { result } = renderHook(() => useUsers(), {
      wrapper: createWrapper(),
    });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });

    expect(result.current.error).toBeDefined();
  });
});

describe('useUser', () => {
  it('fetches single user successfully', async () => {
    const { result } = renderHook(() => useUser(1), {
      wrapper: createWrapper(),
    });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data?.email).toBe('admin@rayces.com');
    expect(result.current.data?.id).toBe(1);
  });

  it('handles user not found', async () => {
    const { result } = renderHook(() => useUser(999), {
      wrapper: createWrapper(),
    });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });

    expect(result.current.error).toBeDefined();
  });

  it('skips query when id is null', () => {
    const { result } = renderHook(() => useUser(null), {
      wrapper: createWrapper(),
    });

    expect(result.current.isLoading).toBe(false);
    expect(result.current.data).toBeUndefined();
  });
});

describe('useCreateUser', () => {
  it('creates user successfully', async () => {
    const { result } = renderHook(() => useCreateUser(), {
      wrapper: createWrapper(),
    });

    const newUser = {
      email: 'newuser@example.com',
      first_name: 'New',
      last_name: 'User',
      password: 'password123',
      password_confirmation: 'password123',
      role: 'staff' as const,
      phone: '+1234567890',
    };

    await act(async () => {
      result.current.mutate(newUser);
    });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data?.email).toBe('newuser@example.com');
    expect(result.current.data?.full_name).toBe('New User');
  });

  it('handles validation errors', async () => {
    server.use(
      http.post('http://localhost:4000/api/v1/users', () => {
        return HttpResponse.json(
          {
            errors: {
              email: ['has already been taken'],
            },
          },
          { status: 422 }
        );
      })
    );

    const { result } = renderHook(() => useCreateUser(), {
      wrapper: createWrapper(),
    });

    await act(async () => {
      result.current.mutate({
        email: 'admin@rayces.com',
        first_name: 'Test',
        last_name: 'User',
        password: 'password123',
        password_confirmation: 'password123',
        role: 'staff',
        phone: '+1234567890',
      });
    });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });
  });
});

describe('useUpdateUser', () => {
  it('updates user successfully', async () => {
    const { result } = renderHook(() => useUpdateUser(), {
      wrapper: createWrapper(),
    });

    await act(async () => {
      result.current.mutate({
        id: 1,
        data: {
          first_name: 'Updated',
          last_name: 'Admin',
        },
      });
    });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(result.current.data?.first_name).toBe('Updated');
    expect(result.current.data?.full_name).toBe('Updated Admin');
  });

  it('handles user not found', async () => {
    const { result } = renderHook(() => useUpdateUser(), {
      wrapper: createWrapper(),
    });

    await act(async () => {
      result.current.mutate({
        id: 999,
        data: { first_name: 'Test' },
      });
    });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });
  });
});

describe('useDeleteUser', () => {
  it('deletes user successfully', async () => {
    const { result } = renderHook(() => useDeleteUser(), {
      wrapper: createWrapper(),
    });

    await act(async () => {
      result.current.mutate(2);
    });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });
  });

  it('handles insufficient permissions', async () => {
    server.use(
      http.delete('http://localhost:4000/api/v1/users/:id', () => {
        return HttpResponse.json(
          { error: 'Insufficient permissions' },
          { status: 403 }
        );
      })
    );

    const { result } = renderHook(() => useDeleteUser(), {
      wrapper: createWrapper(),
    });

    await act(async () => {
      result.current.mutate(2);
    });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });
  });

  it('handles user not found', async () => {
    const { result } = renderHook(() => useDeleteUser(), {
      wrapper: createWrapper(),
    });

    await act(async () => {
      result.current.mutate(999);
    });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });
  });
});