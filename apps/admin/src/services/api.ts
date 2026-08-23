import axios, { AxiosInstance, AxiosError } from 'axios';
import { AuthSession } from '@/types/auth';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

class ApiClient {
  private client: AxiosInstance;
  private token: string | null = null;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add token to requests
    this.client.interceptors.request.use((config) => {
      if (this.token) {
        config.headers.Authorization = `Bearer ${this.token}`;
      }
      return config;
    });

    // Handle errors
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError) => {
        if (error.response?.status === 401) {
          // Token expired, clear and redirect to login
          this.clearToken();
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );

    // Load token from localStorage
    if (typeof window !== 'undefined') {
      const session = localStorage.getItem('authSession');
      if (session) {
        try {
          const parsed = JSON.parse(session) as AuthSession;
          this.token = parsed.accessToken;
        } catch (e) {
          console.error('Failed to parse auth session');
        }
      }
    }
  }

  setToken(token: string) {
    this.token = token;
    if (typeof window !== 'undefined') {
      const session = localStorage.getItem('authSession');
      if (session) {
        const parsed = JSON.parse(session);
        parsed.accessToken = token;
        localStorage.setItem('authSession', JSON.stringify(parsed));
      }
    }
  }

  clearToken() {
    this.token = null;
    if (typeof window !== 'undefined') {
      localStorage.removeItem('authSession');
    }
  }

  // Auth endpoints
  async login(email: string, password: string) {
    return this.client.post('/auth/login', { email, password });
  }

  async signup(email: string, password: string, fullName: string) {
    return this.client.post('/auth/signup', { email, password, fullName });
  }

  async logout() {
    this.clearToken();
    return this.client.post('/auth/logout');
  }

  // Admin endpoints
  async getUsers(limit = 100, offset = 0) {
    return this.client.get('/admin/users', { params: { limit, offset } });
  }

  async getUserById(id: string) {
    return this.client.get(`/admin/users/${id}`);
  }

  async updateUser(id: string, data: any) {
    return this.client.put(`/admin/users/${id}`, data);
  }

  async deleteUser(id: string) {
    return this.client.delete(`/admin/users/${id}`);
  }

  async getContent(limit = 100, offset = 0) {
    return this.client.get('/admin/content', { params: { limit, offset } });
  }

  async getContentById(id: string) {
    return this.client.get(`/admin/content/${id}`);
  }

  async updateContent(id: string, data: any) {
    return this.client.put(`/admin/content/${id}`, data);
  }

  async deleteContent(id: string) {
    return this.client.delete(`/admin/content/${id}`);
  }

  async getAnalytics(startDate?: string, endDate?: string) {
    return this.client.get('/admin/analytics', {
      params: { startDate, endDate },
    });
  }

  async getSystemHealth() {
    return this.client.get('/admin/system/health');
  }

  async getSystemMetrics() {
    return this.client.get('/admin/system/metrics');
  }

  async getAuditLogs(limit = 100, offset = 0) {
    return this.client.get('/admin/audit-logs', { params: { limit, offset } });
  }
}

export const apiClient = new ApiClient();
