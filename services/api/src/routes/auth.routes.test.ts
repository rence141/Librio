import { describe, it, expect, beforeEach, vi } from 'vitest';
import request from 'supertest';
import express, { Express } from 'express';
import authRoutes from './auth.routes';
import { AuthService } from '../services/auth.service';

// Mock the auth service
vi.mock('../services/auth.service');
vi.mock('../services/supabase.service', () => ({
  supabaseService: {
    getUserProfile: vi.fn(),
  },
}));

describe('Auth Routes', () => {
  let app: Express;

  beforeEach(() => {
    app = express();
    app.use(express.json());
    app.use('/auth', authRoutes);
  });

  describe('POST /auth/signup', () => {
    it('should successfully sign up a new user', async () => {
      const response = await request(app)
        .post('/auth/signup')
        .send({
          email: 'test@example.com',
          password: 'TestPassword123',
          fullName: 'Test User',
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('accessToken');
      expect(response.body.data).toHaveProperty('refreshToken');
      expect(response.body.data.user.email).toBe('test@example.com');
    });

    it('should reject signup without email', async () => {
      const response = await request(app)
        .post('/auth/signup')
        .send({
          password: 'TestPassword123',
          fullName: 'Test User',
        });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    it('should reject signup without password', async () => {
      const response = await request(app)
        .post('/auth/signup')
        .send({
          email: 'test@example.com',
          fullName: 'Test User',
        });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    it('should handle signup errors gracefully', async () => {
      const response = await request(app)
        .post('/auth/signup')
        .send({
          email: 'invalid-email',
          password: 'short',
          fullName: 'Test User',
        });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('POST /auth/login', () => {
    it('should successfully login with valid credentials', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
          password: 'TestPassword123',
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('accessToken');
      expect(response.body.data).toHaveProperty('refreshToken');
    });

    it('should reject login without email', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          password: 'TestPassword123',
        });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    it('should reject login without password', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'test@example.com',
        });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    it('should reject login with invalid credentials', async () => {
      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'WrongPassword123',
        });

      expect(response.status).toBe(401);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('POST /auth/refresh', () => {
    it('should successfully refresh access token', async () => {
      const response = await request(app)
        .post('/auth/refresh')
        .send({
          refreshToken: 'valid_refresh_token',
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('accessToken');
    });

    it('should reject refresh without token', async () => {
      const response = await request(app)
        .post('/auth/refresh')
        .send({});

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    it('should reject invalid refresh token', async () => {
      const response = await request(app)
        .post('/auth/refresh')
        .send({
          refreshToken: 'invalid_token',
        });

      expect(response.status).toBe(401);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('POST /auth/google', () => {
    it('should successfully verify Google token', async () => {
      const response = await request(app)
        .post('/auth/google')
        .send({
          idToken: 'valid_google_id_token',
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body.data).toHaveProperty('accessToken');
      expect(response.body.data).toHaveProperty('refreshToken');
    });

    it('should reject Google sign-in without token', async () => {
      const response = await request(app)
        .post('/auth/google')
        .send({});

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    it('should reject invalid Google token', async () => {
      const response = await request(app)
        .post('/auth/google')
        .send({
          idToken: 'invalid_token',
        });

      expect(response.status).toBe(401);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('POST /auth/request-password-reset', () => {
    it('should successfully request password reset', async () => {
      const response = await request(app)
        .post('/auth/request-password-reset')
        .send({
          email: 'test@example.com',
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('message');
    });

    it('should reject password reset without email', async () => {
      const response = await request(app)
        .post('/auth/request-password-reset')
        .send({});

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });
  });

  describe('POST /auth/confirm-password-reset', () => {
    it('should successfully confirm password reset', async () => {
      const response = await request(app)
        .post('/auth/confirm-password-reset')
        .send({
          token: 'reset_token',
          newPassword: 'NewPassword123',
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('success', true);
    });

    it('should reject password reset without token', async () => {
      const response = await request(app)
        .post('/auth/confirm-password-reset')
        .send({
          newPassword: 'NewPassword123',
        });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });

    it('should reject password reset without password', async () => {
      const response = await request(app)
        .post('/auth/confirm-password-reset')
        .send({
          token: 'reset_token',
        });

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty('error');
    });
  });
});
