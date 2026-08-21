import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    // Test environment
    environment: 'node',

    // Global test timeout
    testTimeout: 10000,

    // Coverage configuration
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'dist/',
        'src/tests/',
        '**/*.test.ts',
        '**/*.spec.ts',
      ],
      lines: 80,
      functions: 80,
      branches: 75,
      statements: 80,
    },

    // Include patterns
    include: ['src/**/*.test.ts', 'src/**/*.spec.ts'],

    // Exclude patterns
    exclude: ['node_modules', 'dist', '.idea', '.git', '.cache'],

    // Setup files
    setupFiles: ['./src/tests/setup.ts'],

    // Globals
    globals: true,

    // Reporters
    reporters: ['verbose'],

    // Bail on first failure
    bail: 0,

    // Isolate test environment
    isolate: true,

    // Threads
    threads: true,
    maxThreads: 4,
    minThreads: 1,
  },

  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
