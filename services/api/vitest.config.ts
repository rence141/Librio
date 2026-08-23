import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    // Test environment
    environment: 'node',
    
    // Global test timeout
    testTimeout: 10000,
    
    // Hook timeout
    hookTimeout: 10000,
    
    // Coverage configuration
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        'dist/',
        '**/*.test.ts',
        '**/*.spec.ts',
        '**/index.ts',
      ],
      lines: 70,
      functions: 70,
      branches: 70,
      statements: 70,
    },
    
    // Include test files
    include: ['src/**/*.test.ts', 'src/**/*.spec.ts'],
    
    // Exclude files
    exclude: ['node_modules', 'dist', '.idea', '.git', '.cache'],
    
    // Mock reset
    mockReset: true,
    restoreMocks: true,
    clearMocks: true,
    
    // Globals
    globals: true,
  },
  
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
