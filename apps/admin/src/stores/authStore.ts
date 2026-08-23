import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { User, AuthSession } from '@/types/auth';
import { apiClient } from '@/services/api';

interface AuthState {
  user: User | null;
  session: AuthSession | null;
  isLoading: boolean;
  error: string | null;
  isAuthenticated: boolean;

  // Actions
  login: (email: string, password: string) => Promise<void>;
  signup: (email: string, password: string, fullName: string) => Promise<void>;
  logout: () => Promise<void>;
  setSession: (session: AuthSession) => void;
  clearError: () => void;
  checkAuth: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      session: null,
      isLoading: false,
      error: null,
      isAuthenticated: false,

      login: async (email: string, password: string) => {
        set({ isLoading: true, error: null });
        try {
          const response = await apiClient.login(email, password);
          const session = response.data.data as AuthSession;
          apiClient.setToken(session.accessToken);
          set({
            user: session.user,
            session,
            isAuthenticated: true,
            isLoading: false,
          });
        } catch (error: any) {
          const message = error.response?.data?.error || 'Login failed';
          set({ error: message, isLoading: false });
          throw error;
        }
      },

      signup: async (email: string, password: string, fullName: string) => {
        set({ isLoading: true, error: null });
        try {
          const response = await apiClient.signup(email, password, fullName);
          const session = response.data.data as AuthSession;
          apiClient.setToken(session.accessToken);
          set({
            user: session.user,
            session,
            isAuthenticated: true,
            isLoading: false,
          });
        } catch (error: any) {
          const message = error.response?.data?.error || 'Signup failed';
          set({ error: message, isLoading: false });
          throw error;
        }
      },

      logout: async () => {
        set({ isLoading: true });
        try {
          await apiClient.logout();
        } catch (error) {
          console.error('Logout error:', error);
        } finally {
          set({
            user: null,
            session: null,
            isAuthenticated: false,
            isLoading: false,
          });
        }
      },

      setSession: (session: AuthSession) => {
        apiClient.setToken(session.accessToken);
        set({
          user: session.user,
          session,
          isAuthenticated: true,
        });
      },

      clearError: () => set({ error: null }),

      checkAuth: () => {
        const state = get();
        if (state.session && state.user) {
          const now = Date.now() / 1000;
          if (state.session.expiresAt > now) {
            set({ isAuthenticated: true });
          } else {
            set({ isAuthenticated: false, session: null, user: null });
          }
        }
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        session: state.session,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);
