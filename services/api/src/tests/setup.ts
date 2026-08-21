import { beforeAll, afterAll, beforeEach, afterEach, vi } from 'vitest';

/**
 * Global test setup and teardown
 */

// Mock environment variables
process.env.JWT_SECRET = 'test-secret-key';
process.env.JWT_REFRESH_SECRET = 'test-refresh-secret-key';
process.env.SUPABASE_URL = 'https://test.supabase.co';
process.env.SUPABASE_ANON_KEY = 'test-anon-key';
process.env.SUPABASE_SERVICE_KEY = 'test-service-key';

// Global test setup
beforeAll(() => {
  console.log('🧪 Starting test suite...');
});

// Global test teardown
afterAll(() => {
  console.log('✅ Test suite completed');
});

// Before each test
beforeEach(() => {
  // Clear all mocks
  vi.clearAllMocks();
});

// After each test
afterEach(() => {
  // Cleanup
});

// Mock console methods to reduce noise
global.console = {
  ...console,
  log: vi.fn(),
  debug: vi.fn(),
  info: vi.fn(),
  warn: vi.fn(),
  error: vi.fn(),
};
