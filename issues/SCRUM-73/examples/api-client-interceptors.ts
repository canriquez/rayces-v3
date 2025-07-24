// API Client with Axios Interceptors for JWT and Multi-tenancy
// This example demonstrates how to configure Axios with interceptors
// for authentication and multi-tenant headers

import axios, { AxiosInstance, InternalAxiosRequestConfig } from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1';

// Create axios instance with base configuration
export const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 seconds
});

// Request interceptor for authentication and multi-tenancy
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // Add JWT token if available
    const token = localStorage.getItem('auth_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    // Add organization subdomain for multi-tenancy
    const subdomain = localStorage.getItem('organization_subdomain');
    if (subdomain && config.headers) {
      config.headers['X-Organization-Subdomain'] = subdomain;
    }
    
    // Log outgoing requests in development
    if (process.env.NODE_ENV === 'development') {
      console.log(`[API Request] ${config.method?.toUpperCase()} ${config.url}`, {
        headers: config.headers,
        data: config.data,
      });
    }
    
    return config;
  },
  (error) => {
    console.error('[API Request Error]', error);
    return Promise.reject(error);
  }
);

// Response interceptor for error handling and token management
apiClient.interceptors.response.use(
  (response) => {
    // Log successful responses in development
    if (process.env.NODE_ENV === 'development') {
      console.log(`[API Response] ${response.config.url}`, response.data);
    }
    return response;
  },
  async (error) => {
    const originalRequest = error.config;
    
    // Handle 401 Unauthorized
    if (error.response?.status === 401) {
      // Clear local storage
      localStorage.removeItem('auth_token');
      localStorage.removeItem('organization_subdomain');
      localStorage.removeItem('user_data');
      
      // Redirect to login if not already there
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
      
      return Promise.reject(error);
    }
    
    // Handle 403 Forbidden (insufficient permissions)
    if (error.response?.status === 403) {
      console.error('[API] Insufficient permissions', error.response.data);
      // You might want to show a notification here
    }
    
    // Handle 422 Unprocessable Entity (validation errors)
    if (error.response?.status === 422) {
      console.error('[API] Validation errors', error.response.data);
    }
    
    // Handle network errors
    if (!error.response) {
      console.error('[API] Network error', error.message);
    }
    
    // Log other errors in development
    if (process.env.NODE_ENV === 'development') {
      console.error('[API Response Error]', {
        url: originalRequest?.url,
        status: error.response?.status,
        data: error.response?.data,
      });
    }
    
    return Promise.reject(error);
  }
);

// Helper function to handle API errors consistently
export const handleApiError = (error: any): string => {
  if (error.response?.data?.error) {
    return error.response.data.error;
  }
  if (error.response?.data?.errors) {
    // Handle Rails validation errors format
    const errors = error.response.data.errors;
    return Object.entries(errors)
      .map(([field, messages]) => `${field}: ${(messages as string[]).join(', ')}`)
      .join('; ');
  }
  if (error.message) {
    return error.message;
  }
  return 'An unexpected error occurred';
};

// Example usage:
// import { apiClient, handleApiError } from '@/lib/api/client';
// 
// try {
//   const { data } = await apiClient.get('/users');
//   console.log('Users:', data.users);
// } catch (error) {
//   const errorMessage = handleApiError(error);
//   console.error('Failed to fetch users:', errorMessage);
// }