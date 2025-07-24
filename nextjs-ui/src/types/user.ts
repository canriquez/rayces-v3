export interface Organization {
  id: number;
  name: string;
  subdomain: string;
  phone?: string;
  address?: string;
  active: boolean;
  created_at: string;
  updated_at: string;
  email?: string;
  settings?: Record<string, unknown>;
}

export interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  full_name: string;
  phone?: string;
  role: 'admin' | 'professional' | 'staff' | 'guardian';
  organization?: Organization;
  created_at: string;
  updated_at: string;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface LoginResponse {
  status: {
    code: number;
    message: string;
  };
  data: User;
  token: string;
}

export interface CreateUserData {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  phone?: string;
  role: User['role'];
}

export interface UpdateUserData {
  first_name?: string;
  last_name?: string;
  phone?: string;
  role?: User['role'];
}

export interface ChangePasswordData {
  current_password: string;
  password: string;
  password_confirmation: string;
}

// Type guards
export function isUser(obj: unknown): obj is User {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    'id' in obj &&
    'email' in obj &&
    'role' in obj &&
    typeof (obj as User).id === 'number' &&
    typeof (obj as User).email === 'string' &&
    typeof (obj as User).role === 'string' &&
    ['admin', 'professional', 'staff', 'guardian'].includes((obj as User).role)
  );
}

export function hasRole(user: User | null, roles: User['role'][]): boolean {
  return user ? roles.includes(user.role) : false;
}

export function isAdmin(user: User | null): boolean {
  return hasRole(user, ['admin']);
}

export function isProfessional(user: User | null): boolean {
  return hasRole(user, ['professional']);
}

export function isStaff(user: User | null): boolean {
  return hasRole(user, ['staff']);
}

export function isGuardian(user: User | null): boolean {
  return hasRole(user, ['guardian']);
}

export function canManageUsers(user: User | null): boolean {
  return hasRole(user, ['admin', 'staff']);
}