import { User } from './user';

export interface ApiResponse<T> {
  data: T;
  meta?: {
    total: number;
    page: number;
    per_page: number;
  };
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    total: number;
    page: number;
    per_page: number;
    total_pages: number;
  };
}

export interface ApiError {
  error: string;
  errors?: Record<string, string[]>;
  status: number;
}

// API response types
export interface UsersResponse {
  data: User[];
  meta: {
    current_page: number;
    total_pages: number;
    total_count: number;
    per_page: number;
  };
}

export interface UserResponse {
  data: User;
}

// API request types
export interface GetUsersParams {
  page?: number;
  per_page?: number;
  role?: User['role'];
  search?: string;
}

export interface PaginationParams {
  page?: number;
  per_page?: number;
}

// Type guards
export function isApiError(error: unknown): error is ApiError {
  return (
    typeof error === 'object' &&
    error !== null &&
    'error' in error &&
    typeof (error as ApiError).error === 'string'
  );
}

export function isPaginatedResponse<T>(
  response: unknown
): response is PaginatedResponse<T> {
  return (
    typeof response === 'object' &&
    response !== null &&
    'data' in response &&
    Array.isArray((response as PaginatedResponse<T>).data) &&
    'meta' in response &&
    typeof (response as PaginatedResponse<T>).meta === 'object' &&
    (response as PaginatedResponse<T>).meta !== null &&
    'total' in (response as PaginatedResponse<T>).meta &&
    'page' in (response as PaginatedResponse<T>).meta &&
    typeof (response as PaginatedResponse<T>).meta.total === 'number' &&
    typeof (response as PaginatedResponse<T>).meta.page === 'number'
  );
}