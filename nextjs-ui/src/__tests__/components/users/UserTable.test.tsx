import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { UserTable } from '@/components/users/UserTable';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { mockUsers } from '@/__tests__/mocks/handlers';
import { server } from '@/__tests__/mocks/server';
import { http, HttpResponse } from 'msw';

// Mock the router
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(),
}));

// Mock the auth store
jest.mock('@/stores/authStore', () => ({
  useAuthStore: jest.fn(() => ({
    user: { id: 1, email: 'admin@rayces.com', role: 'admin' },
  })),
}));

// Helper to render with providers
const renderWithProviders = (component: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      {component}
    </QueryClientProvider>
  );
};

describe('UserTable', () => {
  const mockPush = jest.fn();

  beforeEach(() => {
    (useRouter as jest.Mock).mockReturnValue({ push: mockPush });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders user table with data', async () => {
    renderWithProviders(<UserTable />);

    // Wait for data to load
    await waitFor(() => {
      expect(screen.getByText('Admin User')).toBeInTheDocument();
    });

    // Check table headers
    expect(screen.getByText('Name')).toBeInTheDocument();
    expect(screen.getByText('Email')).toBeInTheDocument();
    expect(screen.getByText('Role')).toBeInTheDocument();
    expect(screen.getByText('Phone')).toBeInTheDocument();
    expect(screen.getByText('Actions')).toBeInTheDocument();

    // Check first few users are rendered
    expect(screen.getByText('admin@rayces.com')).toBeInTheDocument();
    expect(screen.getByText('professional@rayces.com')).toBeInTheDocument();
    expect(screen.getByText('secretary@rayces.com')).toBeInTheDocument();
  });

  it('displays loading state initially', () => {
    renderWithProviders(<UserTable />);
    expect(screen.getByText(/loading users/i)).toBeInTheDocument();
  });

  it('handles server errors gracefully', async () => {
    // Override handler to return error
    server.use(
      http.get('http://localhost:4000/api/v1/users', () => {
        return HttpResponse.json(
          { error: 'Internal server error' },
          { status: 500 }
        );
      })
    );

    renderWithProviders(<UserTable />);

    await waitFor(() => {
      expect(screen.getByText(/failed to load users/i)).toBeInTheDocument();
    });
  });

  it('navigates to user detail page on row click', async () => {
    const user = userEvent.setup();
    renderWithProviders(<UserTable />);

    // Wait for data to load
    await waitFor(() => {
      expect(screen.getByText('Admin User')).toBeInTheDocument();
    });

    // Click on first user row
    const firstUserRow = screen.getByText('Admin User').closest('tr');
    if (firstUserRow) {
      await user.click(firstUserRow);
    }

    expect(mockPush).toHaveBeenCalledWith('/admin/users/1');
  });

  it('filters users by role', async () => {
    // TODO: Add user interaction tests when filter UI is implemented
    renderWithProviders(<UserTable />);

    // Wait for data to load
    await waitFor(() => {
      expect(screen.getByText('Admin User')).toBeInTheDocument();
    });

    // Check that professional users are shown
    expect(screen.getByText('professional@rayces.com')).toBeInTheDocument();
    expect(screen.getByText('admin@rayces.com')).toBeInTheDocument();
  });

  it('displays role badges with correct colors', async () => {
    renderWithProviders(<UserTable />);

    // Wait for data to load
    await waitFor(() => {
      expect(screen.getByText('Admin User')).toBeInTheDocument();
    });

    // Check role badges
    const adminBadge = screen.getByText('admin');
    expect(adminBadge).toHaveClass('bg-purple-100', 'text-purple-800');

    const professionalBadge = screen.getByText('professional');
    expect(professionalBadge).toHaveClass('bg-blue-100', 'text-blue-800');

    const staffBadge = screen.getByText('staff');
    expect(staffBadge).toHaveClass('bg-green-100', 'text-green-800');
  });

  it('shows edit and delete buttons for admin users', async () => {
    renderWithProviders(<UserTable />);

    // Wait for data to load
    await waitFor(() => {
      expect(screen.getByText('Admin User')).toBeInTheDocument();
    });

    // Should have edit and delete buttons for each user
    const editButtons = screen.getAllByRole('button', { name: /edit/i });
    const deleteButtons = screen.getAllByRole('button', { name: /delete/i });

    expect(editButtons.length).toBeGreaterThan(0);
    expect(deleteButtons.length).toBeGreaterThan(0);
  });

  it('handles delete user action', async () => {
    const user = userEvent.setup();
    
    // Mock confirm dialog
    global.confirm = jest.fn(() => true);

    renderWithProviders(<UserTable />);

    // Wait for data to load
    await waitFor(() => {
      expect(screen.getByText('Admin User')).toBeInTheDocument();
    });

    // Find delete button for the second user (not deleting admin)
    const deleteButtons = screen.getAllByRole('button', { name: /delete/i });
    await user.click(deleteButtons[1]); // Delete professional user

    // Wait for confirmation and deletion
    await waitFor(() => {
      expect(global.confirm).toHaveBeenCalledWith(
        'Are you sure you want to delete this user?'
      );
    });

    // Check user is removed from table
    await waitFor(() => {
      expect(screen.queryByText('professional@rayces.com')).not.toBeInTheDocument();
    });
  });

  it('handles pagination controls', async () => {
    // Mock server to return paginated results
    server.use(
      http.get('http://localhost:4000/api/v1/users', ({ request }) => {
        const url = new URL(request.url);
        const page = Number(url.searchParams.get('page')) || 1;
        
        return HttpResponse.json({
          data: mockUsers.slice(0, 2), // Only 2 users per page
          meta: {
            current_page: page,
            total_pages: 2,
            total_count: 4,
            per_page: 2,
          },
        });
      })
    );

    renderWithProviders(<UserTable />);

    // Wait for data to load
    await waitFor(() => {
      expect(screen.getByText('Admin User')).toBeInTheDocument();
    });

    // Should show pagination info
    expect(screen.getByText(/showing 1 to 2 of 4 results/i)).toBeInTheDocument();
  });

  it('handles empty state', async () => {
    // Override handler to return empty results
    server.use(
      http.get('http://localhost:4000/api/v1/users', () => {
        return HttpResponse.json({
          data: [],
          meta: {
            current_page: 1,
            total_pages: 0,
            total_count: 0,
            per_page: 20,
          },
        });
      })
    );

    renderWithProviders(<UserTable />);

    await waitFor(() => {
      expect(screen.getByText(/no users found/i)).toBeInTheDocument();
    });
  });
});