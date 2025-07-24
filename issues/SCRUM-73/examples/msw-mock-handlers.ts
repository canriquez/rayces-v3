// Mock Service Worker (MSW) Handlers for Testing
// This example shows how to mock all API endpoints for unit testing
// with realistic response data and error scenarios

import { rest } from 'msw';
import { setupServer } from 'msw/node';

// Mock data generators
const mockUsers = [
  {
    id: 1,
    email: 'admin@rayces.com',
    first_name: 'Admin',
    last_name: 'User',
    full_name: 'Admin User',
    phone: '+1234567890',
    role: 'admin' as const,
    created_at: '2025-01-01T00:00:00Z',
    updated_at: '2025-01-01T00:00:00Z',
    organization: {
      id: 1,
      name: 'Rayces Organization',
      subdomain: 'rayces',
      phone: '+1234567890',
      address: '123 Main St',
      active: true,
      created_at: '2025-01-01T00:00:00Z',
      updated_at: '2025-01-01T00:00:00Z',
      email: 'admin@rayces.com',
      settings: {},
    },
  },
  {
    id: 2,
    email: 'professional@rayces.com',
    first_name: 'John',
    last_name: 'Therapist',
    full_name: 'John Therapist',
    phone: '+1234567891',
    role: 'professional' as const,
    created_at: '2025-01-02T00:00:00Z',
    updated_at: '2025-01-02T00:00:00Z',
  },
  {
    id: 3,
    email: 'secretary@rayces.com',
    first_name: 'Jane',
    last_name: 'Secretary',
    full_name: 'Jane Secretary',
    phone: '+1234567892',
    role: 'staff' as const,
    created_at: '2025-01-03T00:00:00Z',
    updated_at: '2025-01-03T00:00:00Z',
  },
  {
    id: 4,
    email: 'parent@rayces.com',
    first_name: 'Mary',
    last_name: 'Parent',
    full_name: 'Mary Parent',
    phone: '+1234567893',
    role: 'guardian' as const,
    created_at: '2025-01-04T00:00:00Z',
    updated_at: '2025-01-04T00:00:00Z',
  },
];

const mockAppointments = [
  {
    id: 1,
    scheduled_at: '2025-07-25T10:00:00Z',
    ends_at: '2025-07-25T11:00:00Z',
    duration_minutes: 60,
    state: 'confirmed',
    notes: 'Regular therapy session',
    price: '100.00',
    uses_credits: true,
    credits_used: 1,
    created_at: '2025-07-20T00:00:00Z',
    updated_at: '2025-07-20T00:00:00Z',
    professional: mockUsers[1],
    client: mockUsers[3],
    student: {
      id: 1,
      first_name: 'Jimmy',
      last_name: 'Student',
      date_of_birth: '2015-01-01',
    },
  },
];

// Base URL for API
const API_BASE_URL = 'http://localhost:3000/api/v1';

// Handler factory for common patterns
const createPaginatedHandler = (endpoint: string, data: any[], filterKey?: string) => {
  return rest.get(`${API_BASE_URL}${endpoint}`, (req, res, ctx) => {
    const page = Number(req.url.searchParams.get('page')) || 1;
    const perPage = Number(req.url.searchParams.get('per_page')) || 20;
    const filter = filterKey ? req.url.searchParams.get(filterKey) : null;
    
    let filtered = data;
    if (filter && filterKey) {
      filtered = data.filter((item: any) => item[filterKey] === filter);
    }
    
    const start = (page - 1) * perPage;
    const end = start + perPage;
    const paginated = filtered.slice(start, end);
    
    return res(
      ctx.status(200),
      ctx.json({
        [endpoint.split('/')[1]]: paginated,
        meta: {
          total: filtered.length,
          page,
          per_page: perPage,
        },
      })
    );
  });
};

// Define all API handlers
export const handlers = [
  // Authentication endpoints
  rest.post(`${API_BASE_URL}/login`, async (req, res, ctx) => {
    const { user } = await req.json();
    
    // Simulate validation error
    if (!user?.email || !user?.password) {
      return res(
        ctx.status(422),
        ctx.json({
          errors: {
            email: !user?.email ? ['is required'] : [],
            password: !user?.password ? ['is required'] : [],
          },
        })
      );
    }
    
    // Simulate invalid credentials
    if (user.password === 'wrong') {
      return res(
        ctx.status(401),
        ctx.json({ error: 'Invalid email or password' })
      );
    }
    
    // Success response
    const mockUser = mockUsers.find(u => u.email === user.email) || mockUsers[0];
    return res(
      ctx.status(200),
      ctx.json({
        user: mockUser,
        token: 'mock-jwt-token-' + mockUser.id,
      }),
      ctx.set('Authorization', 'Bearer mock-jwt-token-' + mockUser.id)
    );
  }),
  
  rest.delete(`${API_BASE_URL}/logout`, (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json({ message: 'Signed out successfully' })
    );
  }),
  
  rest.post(`${API_BASE_URL}/signup`, async (req, res, ctx) => {
    const { user } = await req.json();
    
    // Simulate user already exists
    if (mockUsers.find(u => u.email === user.email)) {
      return res(
        ctx.status(422),
        ctx.json({
          errors: {
            email: ['has already been taken'],
          },
        })
      );
    }
    
    const newUser = {
      id: mockUsers.length + 1,
      ...user,
      full_name: `${user.first_name} ${user.last_name}`,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    return res(
      ctx.status(201),
      ctx.json({
        user: newUser,
        token: 'mock-jwt-token-' + newUser.id,
      })
    );
  }),
  
  // User management endpoints
  createPaginatedHandler('/users', mockUsers, 'role'),
  
  rest.get(`${API_BASE_URL}/users/:id`, (req, res, ctx) => {
    const { id } = req.params;
    const user = mockUsers.find(u => u.id === Number(id));
    
    if (!user) {
      return res(
        ctx.status(404),
        ctx.json({ error: 'User not found' })
      );
    }
    
    return res(
      ctx.status(200),
      ctx.json({ user })
    );
  }),
  
  rest.post(`${API_BASE_URL}/users`, async (req, res, ctx) => {
    const { user } = await req.json();
    
    const newUser = {
      id: mockUsers.length + 1,
      ...user,
      full_name: `${user.first_name} ${user.last_name}`,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    mockUsers.push(newUser);
    
    return res(
      ctx.status(201),
      ctx.json({ user: newUser })
    );
  }),
  
  rest.patch(`${API_BASE_URL}/users/:id`, async (req, res, ctx) => {
    const { id } = req.params;
    const { user: updates } = await req.json();
    const userIndex = mockUsers.findIndex(u => u.id === Number(id));
    
    if (userIndex === -1) {
      return res(
        ctx.status(404),
        ctx.json({ error: 'User not found' })
      );
    }
    
    const updatedUser = {
      ...mockUsers[userIndex],
      ...updates,
      updated_at: new Date().toISOString(),
    };
    
    if (updates.first_name || updates.last_name) {
      updatedUser.full_name = `${updatedUser.first_name} ${updatedUser.last_name}`;
    }
    
    mockUsers[userIndex] = updatedUser;
    
    return res(
      ctx.status(200),
      ctx.json({ user: updatedUser })
    );
  }),
  
  rest.delete(`${API_BASE_URL}/users/:id`, (req, res, ctx) => {
    const { id } = req.params;
    const userIndex = mockUsers.findIndex(u => u.id === Number(id));
    
    if (userIndex === -1) {
      return res(
        ctx.status(404),
        ctx.json({ error: 'User not found' })
      );
    }
    
    // Check permissions (only admins can delete)
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.includes('mock-jwt-token-1')) {
      return res(
        ctx.status(403),
        ctx.json({ error: 'Insufficient permissions' })
      );
    }
    
    mockUsers.splice(userIndex, 1);
    
    return res(
      ctx.status(200),
      ctx.json({ message: 'User deleted successfully' })
    );
  }),
  
  rest.patch(`${API_BASE_URL}/users/:id/change_password`, async (req, res, ctx) => {
    const { user } = await req.json();
    
    // Simulate current password wrong
    if (user.current_password === 'wrong') {
      return res(
        ctx.status(422),
        ctx.json({
          errors: {
            current_password: ['is incorrect'],
          },
        })
      );
    }
    
    // Simulate password confirmation mismatch
    if (user.password !== user.password_confirmation) {
      return res(
        ctx.status(422),
        ctx.json({
          errors: {
            password_confirmation: ["doesn't match password"],
          },
        })
      );
    }
    
    return res(
      ctx.status(200),
      ctx.json({ message: 'Password updated successfully' })
    );
  }),
  
  // Organization endpoints
  rest.get(`${API_BASE_URL}/organization`, (req, res, ctx) => {
    return res(
      ctx.status(200),
      ctx.json({
        organization: mockUsers[0].organization,
      })
    );
  }),
  
  rest.patch(`${API_BASE_URL}/organization`, async (req, res, ctx) => {
    const { organization: updates } = await req.json();
    
    // Check permissions
    const authHeader = req.headers.get('Authorization');
    if (!authHeader?.includes('mock-jwt-token-1')) {
      return res(
        ctx.status(403),
        ctx.json({ error: 'Only admins can update organization' })
      );
    }
    
    const updatedOrg = {
      ...mockUsers[0].organization,
      ...updates,
      updated_at: new Date().toISOString(),
    };
    
    return res(
      ctx.status(200),
      ctx.json({ organization: updatedOrg })
    );
  }),
  
  // Appointment endpoints
  createPaginatedHandler('/appointments', mockAppointments, 'state'),
  
  rest.get(`${API_BASE_URL}/appointments/:id`, (req, res, ctx) => {
    const { id } = req.params;
    const appointment = mockAppointments.find(a => a.id === Number(id));
    
    if (!appointment) {
      return res(
        ctx.status(404),
        ctx.json({ error: 'Appointment not found' })
      );
    }
    
    return res(
      ctx.status(200),
      ctx.json({ appointment })
    );
  }),
  
  // Error simulation endpoints for testing
  rest.get(`${API_BASE_URL}/simulate/network-error`, (req, res) => {
    return res.networkError('Network connection failed');
  }),
  
  rest.get(`${API_BASE_URL}/simulate/timeout`, (req, res, ctx) => {
    return res(ctx.delay('infinite'));
  }),
];

// Create MSW server instance
export const server = setupServer(...handlers);

// Test setup utilities
export const setupMSW = () => {
  beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
  afterEach(() => server.resetHandlers());
  afterAll(() => server.close());
};

// Utility to override handlers for specific tests
export const mockApiError = (endpoint: string, status: number, error: any) => {
  server.use(
    rest.get(`${API_BASE_URL}${endpoint}`, (req, res, ctx) => {
      return res(ctx.status(status), ctx.json(error));
    })
  );
};

// Example usage in tests:
// import { server, setupMSW, mockApiError } from '@/__tests__/mocks/handlers';
// 
// describe('UserTable', () => {
//   setupMSW();
//   
//   it('handles server errors gracefully', async () => {
//     mockApiError('/users', 500, { error: 'Internal server error' });
//     
//     render(<UserTable />);
//     
//     await waitFor(() => {
//       expect(screen.getByText('Failed to load users')).toBeInTheDocument();
//     });
//   });
// });