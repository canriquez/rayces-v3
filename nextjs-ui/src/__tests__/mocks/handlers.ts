// Mock Service Worker (MSW) Handlers for Testing
// Mocks all API endpoints for unit testing with realistic response data and error scenarios

import { http, HttpResponse } from 'msw';
import type { User, Organization } from '@/types/user';

// Mock data generators
const mockOrganization: Organization = {
  id: 1,
  name: 'Rayces Organization',
  subdomain: 'rayces',
  phone: '+54 11 4567-8900',
  address: '123 Main St',
  active: true,
  created_at: '2025-01-01T00:00:00Z',
  updated_at: '2025-01-01T00:00:00Z',
  email: 'admin@rayces.com',
  settings: {},
};

const mockUsers: User[] = [
  {
    id: 1,
    email: 'admin@rayces.com',
    first_name: 'Admin',
    last_name: 'User',
    full_name: 'Admin User',
    phone: '+54 11 4567-8900',
    role: 'admin',
    created_at: '2025-01-01T00:00:00Z',
    updated_at: '2025-01-01T00:00:00Z',
    organization: mockOrganization,
  },
  {
    id: 2,
    email: 'professional@rayces.com',
    first_name: 'John',
    last_name: 'Therapist',
    full_name: 'John Therapist',
    phone: '+54 11 4567-8901',
    role: 'professional',
    created_at: '2025-01-02T00:00:00Z',
    updated_at: '2025-01-02T00:00:00Z',
  },
  {
    id: 3,
    email: 'secretary@rayces.com',
    first_name: 'Jane',
    last_name: 'Secretary',
    full_name: 'Jane Secretary',
    phone: '+54 11 4567-8902',
    role: 'staff',
    created_at: '2025-01-03T00:00:00Z',
    updated_at: '2025-01-03T00:00:00Z',
  },
  {
    id: 4,
    email: 'parent@rayces.com',
    first_name: 'Mary',
    last_name: 'Parent',
    full_name: 'Mary Parent',
    phone: '+54 11 4567-8903',
    role: 'guardian',
    created_at: '2025-01-04T00:00:00Z',
    updated_at: '2025-01-04T00:00:00Z',
  },
];

// Base URL for API
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1';

// Handler factory for common patterns
const createPaginatedHandler = <T>(endpoint: string, data: T[], filterKey?: string) => {
  return http.get(`${API_BASE_URL}${endpoint}`, ({ request }) => {
    const url = new URL(request.url);
    const page = Number(url.searchParams.get('page')) || 1;
    const perPage = Number(url.searchParams.get('per_page')) || 20;
    const filter = filterKey ? url.searchParams.get(filterKey) : null;
    
    let filtered = data;
    if (filter && filterKey) {
      filtered = data.filter((item) => (item as Record<string, unknown>)[filterKey] === filter);
    }
    
    const start = (page - 1) * perPage;
    const end = start + perPage;
    const paginated = filtered.slice(start, end);
    
    return HttpResponse.json({
      data: paginated,
      meta: {
        current_page: page,
        total_pages: Math.ceil(filtered.length / perPage),
        total_count: filtered.length,
        per_page: perPage,
      },
    });
  });
};

// Define all API handlers
export const handlers = [
  // Authentication endpoints
  http.post(`${API_BASE_URL.replace('/api/v1', '')}/login`, async ({ request }) => {
    const body = await request.json() as { user: { email: string; password: string } };
    const { user } = body;
    
    // Simulate validation error
    if (!user?.email || !user?.password) {
      return HttpResponse.json(
        {
          errors: {
            email: !user?.email ? ['is required'] : [],
            password: !user?.password ? ['is required'] : [],
          },
        },
        { status: 422 }
      );
    }
    
    // Simulate invalid credentials
    if (user.password === 'wrong') {
      return HttpResponse.json(
        { error: 'Invalid email or password' },
        { status: 401 }
      );
    }
    
    // Success response
    const mockUser = mockUsers.find(u => u.email === user.email) || mockUsers[0];
    return HttpResponse.json(
      {
        status: {
          code: 200,
          message: "Logged in successfully."
        },
        data: mockUser,
        token: 'mock-jwt-token-' + mockUser.id,
      },
      { 
        status: 200,
        headers: {
          'Authorization': 'Bearer mock-jwt-token-' + mockUser.id,
        },
      }
    );
  }),
  
  http.delete(`${API_BASE_URL.replace('/api/v1', '')}/logout`, () => {
    return HttpResponse.json(
      { message: 'Signed out successfully' },
      { status: 200 }
    );
  }),
  
  http.post(`${API_BASE_URL}/signup`, async ({ request }) => {
    const body = await request.json() as { user: any };
    const { user } = body;
    
    // Simulate user already exists
    if (mockUsers.find(u => u.email === user.email)) {
      return HttpResponse.json(
        {
          errors: {
            email: ['has already been taken'],
          },
        },
        { status: 422 }
      );
    }
    
    const newUser = {
      id: mockUsers.length + 1,
      ...user,
      full_name: `${user.first_name} ${user.last_name}`,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    return HttpResponse.json(
      {
        user: newUser,
        token: 'mock-jwt-token-' + newUser.id,
      },
      { status: 201 }
    );
  }),
  
  // User management endpoints
  createPaginatedHandler('/users', mockUsers, 'role'),
  
  http.get(`${API_BASE_URL}/users/:id`, ({ params }) => {
    const { id } = params;
    const user = mockUsers.find(u => u.id === Number(id));
    
    if (!user) {
      return HttpResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }
    
    return HttpResponse.json({ data: user });
  }),
  
  http.post(`${API_BASE_URL}/users`, async ({ request }) => {
    const body = await request.json() as { user: any };
    const { user } = body;
    
    const newUser: User = {
      id: mockUsers.length + 1,
      ...user,
      full_name: `${user.first_name} ${user.last_name}`,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    mockUsers.push(newUser);
    
    return HttpResponse.json(
      { data: newUser },
      { status: 201 }
    );
  }),
  
  http.patch(`${API_BASE_URL}/users/:id`, async ({ params, request }) => {
    const { id } = params;
    const body = await request.json() as { user: any };
    const { user: updates } = body;
    const userIndex = mockUsers.findIndex(u => u.id === Number(id));
    
    if (userIndex === -1) {
      return HttpResponse.json(
        { error: 'User not found' },
        { status: 404 }
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
    
    return HttpResponse.json({ data: updatedUser });
  }),
  
  http.delete(`${API_BASE_URL}/users/:id`, ({ params, request }) => {
    const { id } = params;
    const userIndex = mockUsers.findIndex(u => u.id === Number(id));
    
    if (userIndex === -1) {
      return HttpResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }
    
    // Check permissions (only admins can delete)
    const authHeader = request.headers.get('Authorization');
    if (!authHeader?.includes('mock-jwt-token-1')) {
      return HttpResponse.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      );
    }
    
    mockUsers.splice(userIndex, 1);
    
    return HttpResponse.json({ message: 'User deleted successfully' });
  }),
  
  http.patch(`${API_BASE_URL}/users/:id/change_password`, async ({ request }) => {
    const body = await request.json() as { user: any };
    const { user } = body;
    
    // Simulate current password wrong
    if (user.current_password === 'wrong') {
      return HttpResponse.json(
        {
          errors: {
            current_password: ['is incorrect'],
          },
        },
        { status: 422 }
      );
    }
    
    // Simulate password confirmation mismatch
    if (user.password !== user.password_confirmation) {
      return HttpResponse.json(
        {
          errors: {
            password_confirmation: ["doesn't match password"],
          },
        },
        { status: 422 }
      );
    }
    
    return HttpResponse.json({ message: 'Password updated successfully' });
  }),
  
  // Organization endpoints
  http.get(`${API_BASE_URL}/organization`, () => {
    return HttpResponse.json({
      data: mockOrganization,
    });
  }),
  
  http.patch(`${API_BASE_URL}/organization`, async ({ request }) => {
    const body = await request.json() as { organization: Record<string, unknown> };
    const { organization: updates } = body;
    
    // Check permissions
    const authHeader = request.headers.get('Authorization');
    if (!authHeader?.includes('mock-jwt-token-1')) {
      return HttpResponse.json(
        { error: 'Only admins can update organization' },
        { status: 403 }
      );
    }
    
    const updatedOrg = {
      ...mockOrganization,
      ...updates,
      updated_at: new Date().toISOString(),
    };
    
    return HttpResponse.json({ data: updatedOrg });
  }),
  
  // Error simulation endpoints for testing
  http.get(`${API_BASE_URL}/simulate/network-error`, () => {
    return HttpResponse.error();
  }),
];

// Utility to override handlers for specific tests
export const mockApiError = (endpoint: string, status: number, error: { error?: string; errors?: Record<string, string[]> }) => {
  return http.get(`${API_BASE_URL}${endpoint}`, () => {
    return HttpResponse.json(error, { status });
  });
};

// Export for use in tests
export { mockUsers, mockOrganization };