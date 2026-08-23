/**
 * Monitoring and observability utilities for Librio API
 * Integrates with Sentry for error tracking and performance monitoring
 */

import * as Sentry from '@sentry/node';
import { Request, Response, NextFunction } from 'express';
import { logger } from './logger';

/**
 * Initialize Sentry for error tracking and performance monitoring
 */
export function initializeSentry() {
  const sentryDsn = process.env.SENTRY_DSN;
  const environment = process.env.NODE_ENV || 'development';

  if (!sentryDsn) {
    logger.warn('Sentry DSN not configured. Error tracking disabled.');
    return;
  }

  Sentry.init({
    dsn: sentryDsn,
    environment,
    tracesSampleRate: environment === 'production' ? 0.1 : 1.0,
    maxBreadcrumbs: 50,
    attachStacktrace: true,
    beforeSend(event, hint) {
      // Filter out certain errors
      if (event.exception) {
        const error = hint.originalException;
        // Don't send 404 errors
        if (error instanceof Error && error.message.includes('not found')) {
          return null;
        }
      }
      return event;
    },
  });

  logger.info('Sentry initialized for error tracking');
}

/**
 * Sentry request handler middleware
 * Must be added early in the middleware chain
 */
export function sentryRequestHandler() {
  return Sentry.Handlers.requestHandler();
}

/**
 * Sentry error handler middleware
 * Must be added after all other middleware and route handlers
 */
export function sentryErrorHandler(): any {
  return Sentry.Handlers.errorHandler();
}

/**
 * Capture exception with context
 */
export function captureException(
  error: Error,
  context?: Record<string, any>,
  level: Sentry.SeverityLevel = 'error'
) {
  Sentry.captureException(error, {
    level,
    contexts: context ? { custom: context } : undefined,
  });
}

/**
 * Capture message
 */
export function captureMessage(
  message: string,
  level: Sentry.SeverityLevel = 'info',
  context?: Record<string, any>
) {
  Sentry.captureMessage(message, {
    level,
    contexts: context ? { custom: context } : undefined,
  });
}

/**
 * Add breadcrumb for tracking user actions
 */
export function addBreadcrumb(
  message: string,
  category: string,
  level: Sentry.SeverityLevel = 'info',
  data?: Record<string, any>
) {
  Sentry.addBreadcrumb({
    message,
    category,
    level,
    data,
    timestamp: Date.now() / 1000,
  });
}

/**
 * Set user context for error tracking
 */
export function setUserContext(userId: string, email?: string, username?: string) {
  Sentry.setUser({
    id: userId,
    email,
    username,
  });
}

/**
 * Clear user context
 */
export function clearUserContext() {
  Sentry.setUser(null);
}

/**
 * Set custom context
 */
export function setCustomContext(name: string, context: Record<string, any>) {
  Sentry.setContext(name, context);
}

/**
 * Performance monitoring middleware
 */
export function performanceMonitoring() {
  return (req: Request, res: Response, next: NextFunction) => {
    const startTime = Date.now();
    const startMemory = process.memoryUsage().heapUsed;

    // Capture response time
    res.on('finish', () => {
      const duration = Date.now() - startTime;
      const memoryUsed = process.memoryUsage().heapUsed - startMemory;

      // Log slow requests
      if (duration > 1000) {
        logger.warn({
          message: 'Slow request detected',
          method: req.method,
          path: req.path,
          duration,
          statusCode: res.statusCode,
        });

        addBreadcrumb(
          `Slow request: ${req.method} ${req.path}`,
          'performance',
          'warning',
          { duration, statusCode: res.statusCode }
        );
      }

      // Log memory usage
      if (memoryUsed > 10 * 1024 * 1024) {
        // 10MB
        logger.warn({
          message: 'High memory usage detected',
          method: req.method,
          path: req.path,
          memoryUsed: `${(memoryUsed / 1024 / 1024).toFixed(2)}MB`,
        });
      }
    });

    next();
  };
}

/**
 * Health check for monitoring
 */
export function getHealthMetrics() {
  const memoryUsage = process.memoryUsage();
  const uptime = process.uptime();

  return {
    status: 'healthy',
    uptime,
    memory: {
      heapUsed: `${(memoryUsage.heapUsed / 1024 / 1024).toFixed(2)}MB`,
      heapTotal: `${(memoryUsage.heapTotal / 1024 / 1024).toFixed(2)}MB`,
      external: `${(memoryUsage.external / 1024 / 1024).toFixed(2)}MB`,
      rss: `${(memoryUsage.rss / 1024 / 1024).toFixed(2)}MB`,
    },
    timestamp: new Date().toISOString(),
  };
}

/**
 * Metrics collector for Prometheus
 */
export class MetricsCollector {
  private requestCount = 0;
  private errorCount = 0;
  private totalResponseTime = 0;
  private startTime = Date.now();

  recordRequest(duration: number, statusCode: number) {
    this.requestCount++;
    this.totalResponseTime += duration;

    if (statusCode >= 400) {
      this.errorCount++;
    }
  }

  getMetrics() {
    const uptime = Date.now() - this.startTime;
    const avgResponseTime = this.requestCount > 0 ? this.totalResponseTime / this.requestCount : 0;
    const errorRate = this.requestCount > 0 ? (this.errorCount / this.requestCount) * 100 : 0;

    return {
      requestCount: this.requestCount,
      errorCount: this.errorCount,
      errorRate: `${errorRate.toFixed(2)}%`,
      avgResponseTime: `${avgResponseTime.toFixed(2)}ms`,
      uptime: `${(uptime / 1000 / 60).toFixed(2)}m`,
      timestamp: new Date().toISOString(),
    };
  }

  reset() {
    this.requestCount = 0;
    this.errorCount = 0;
    this.totalResponseTime = 0;
    this.startTime = Date.now();
  }
}

// Global metrics collector instance
export const metricsCollector = new MetricsCollector();
