export interface User {
  id: string;
  email: string;
  fullName: string;
  role: 'admin' | 'moderator' | 'viewer' | 'user';
  subscriptionTier: 'free' | 'pro' | 'enterprise';
  createdAt: string;
  lastActive?: string;
}

export interface AuthSession {
  user: User;
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  success: boolean;
  data?: AuthSession;
  error?: string;
}

export interface SignupRequest {
  email: string;
  password: string;
  fullName: string;
}

export interface SignupResponse {
  success: boolean;
  data?: AuthSession;
  error?: string;
}
