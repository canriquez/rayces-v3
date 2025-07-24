import { apiClient } from './client';
import axios from 'axios';
import type {
  UsersResponse,
  UserResponse,
  GetUsersParams,
} from '@/types/api';
import type {
  LoginCredentials,
  LoginResponse,
  CreateUserData,
  UpdateUserData,
  ChangePasswordData,
  Organization,
} from '@/types/user';

// Create a separate axios instance for auth endpoints that don't use /api/v1
const authClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL?.replace('/api/v1', '') || 'http://localhost:4000',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000,
});

// Auth endpoints
export const authApi = {
  login: async (credentials: LoginCredentials): Promise<LoginResponse> => {
    const subdomain = typeof window !== 'undefined' ? localStorage.getItem('organization_subdomain') : 'rayces';
    const { data } = await authClient.post('/login', { 
      user: credentials 
    }, {
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Organization-Subdomain': subdomain || 'rayces'
      }
    });
    return data;
  },
  
  logout: async (): Promise<void> => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null;
    const subdomain = typeof window !== 'undefined' ? localStorage.getItem('organization_subdomain') : 'rayces';
    await authClient.delete('/logout', {
      headers: {
        'Authorization': token ? `Bearer ${token}` : '',
        'X-Organization-Subdomain': subdomain || 'rayces'
      }
    });
  },
  
  getCurrentUser: async (): Promise<UserResponse> => {
    const { data } = await apiClient.get('/me');
    return data;
  },
};

// User endpoints
export const userApi = {
  getUsers: async (params: GetUsersParams = {}): Promise<UsersResponse> => {
    const { data } = await apiClient.get('/users', { params });
    return data;
  },
  
  getUser: async (id: number): Promise<UserResponse> => {
    const { data } = await apiClient.get(`/users/${id}`);
    return data;
  },
  
  createUser: async (userData: CreateUserData): Promise<UserResponse> => {
    const { data } = await apiClient.post('/users', { user: userData });
    return data;
  },
  
  updateUser: async ({ id, ...userData }: UpdateUserData & { id: number }): Promise<UserResponse> => {
    const { data } = await apiClient.patch(`/users/${id}`, { user: userData });
    return data;
  },
  
  deleteUser: async (id: number): Promise<void> => {
    await apiClient.delete(`/users/${id}`);
  },
  
  changePassword: async ({ id, ...passwords }: ChangePasswordData & { id: number }): Promise<void> => {
    await apiClient.patch(`/users/${id}/change_password`, { user: passwords });
  },
};

// Organization API endpoints
export const organizationApi = {
  getOrganization: async (): Promise<{ organization: Organization }> => {
    const response = await apiClient.get<{ organization: Organization }>('/organization');
    return response.data;
  },
  
  updateOrganization: async (updates: Partial<Organization>): Promise<{ organization: Organization }> => {
    const response = await apiClient.patch<{ organization: Organization }>('/organization', { organization: updates });
    return response.data;
  },
};