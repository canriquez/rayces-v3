import { AxiosError } from 'axios';

export interface ApiError {
  error: string;
  errors?: Record<string, string[]>;
  status: number;
}

export function isApiError(error: unknown): error is AxiosError<ApiError> {
  return (
    error instanceof Error &&
    'isAxiosError' in error &&
    error.isAxiosError === true
  );
}

export function getErrorMessage(error: unknown): string {
  if (isApiError(error)) {
    if (error.response?.data?.error) {
      return error.response.data.error;
    }
    if (error.response?.data?.errors) {
      const errors = error.response.data.errors;
      return Object.entries(errors)
        .map(([field, messages]) => `${field}: ${messages.join(', ')}`)
        .join('; ');
    }
  }
  
  if (error instanceof Error) {
    return error.message;
  }
  
  return 'An unexpected error occurred';
}

export function getFieldErrors(error: unknown): Record<string, string> | null {
  if (isApiError(error) && error.response?.data?.errors) {
    const errors = error.response.data.errors;
    const fieldErrors: Record<string, string> = {};
    
    Object.entries(errors).forEach(([field, messages]) => {
      fieldErrors[field] = messages.join(', ');
    });
    
    return fieldErrors;
  }
  
  return null;
}