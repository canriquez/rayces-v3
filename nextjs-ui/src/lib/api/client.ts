import axios, { AxiosInstance, InternalAxiosRequestConfig, AxiosError } from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1';

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
    const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null;
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    // Add organization subdomain for multi-tenancy
    const subdomain = typeof window !== 'undefined' ? localStorage.getItem('organization_subdomain') : null;
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
      // Don't clear auth for login/logout endpoints
      const isAuthEndpoint = originalRequest?.url?.includes('/login') || 
                           originalRequest?.url?.includes('/logout');
      
      if (!isAuthEndpoint && typeof window !== 'undefined') {
        // Clear auth store - let Zustand handle the state update
        const authStore = (await import('@/stores/authStore')).useAuthStore.getState();
        authStore.logout();
        
        // Redirect to login if not already there
        if (window.location.pathname !== '/login') {
          window.location.href = '/login';
        }
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
export const handleApiError = (error: unknown): string => {
  if (error instanceof AxiosError) {
    // Check for error message in response data first
    if (error.response?.data?.error) {
      return error.response.data.error;
    }
    
    // Check for plain text error message (like Devise errors)
    if (error.response?.data && typeof error.response.data === 'string') {
      return error.response.data;
    }
    
    // Check for errors object (Rails validation errors)
    if (error.response?.data?.errors) {
      const errors = error.response.data.errors;
      // If errors is an array of strings
      if (Array.isArray(errors)) {
        return errors.join(', ');
      }
      // If errors is an object with field keys
      if (typeof errors === 'object') {
        return Object.entries(errors)
          .map(([field, messages]) => `${field}: ${(messages as string[]).join(', ')}`)
          .join('; ');
      }
    }
    
    // Check for message in response data
    if (error.response?.data?.message) {
      return error.response.data.message;
    }
    
    // Fallback to axios error message
    if (error.message) {
      return error.message;
    }
  }
  
  if (error instanceof Error) {
    return error.message;
  }
  
  return 'An unexpected error occurred';
};