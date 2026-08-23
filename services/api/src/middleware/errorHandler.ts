import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';
import {
  AppError,
  isAppError,
  getUserFriendlyMessage,
  getErrorCode,
  getStatusCode,
} from '../utils/errors';

/**
 * Global error handling middleware
 * Catches all errors and returns structured error responses
 */
export function errorHandler(
  error: unknown,
  req: Request,
  res: Response,
  next: NextFunction
) {
  // Log the error
  const statusCode = getStatusCode(error);
  const message = getUserFriendlyMessage(error);
  const code = getErrorCode(error);

  // Log error details
  if (isAppError(error)) {
    logger.warn({
      statusCode,
      code,
      message,
      path: req.path,
      method: req.method,
      details: error.details,
    });
  } else if (error instanceof Error) {
    logger.error({
      statusCode: 500,
      code: 'UNKNOWN_ERROR',
      message: error.message,
      stack: error.stack,
      path: req.path,
      method: req.method,
    });
  } else {
    logger.error({
      statusCode: 500,
      code: 'UNKNOWN_ERROR',
      message: 'Unknown error occurred',
      path: req.path,
      method: req.method,
    });
  }

  // Send error response
  res.status(statusCode).json({
    success: false,
    error: {
      code,
      message,
      ...(isAppError(error) && error.details && { details: error.details }),
    },
    timestamp: new Date().toISOString(),
    path: req.path,
  });
}

/**
 * Async error wrapper for route handlers
 * Catches errors in async functions and passes to error handler
 */
export function asyncHandler(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<any>
) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

/**
 * 404 handler
 */
export function notFoundHandler(req: Request, res: Response) {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: `Route ${req.method} ${req.path} not found`,
    },
    timestamp: new Date().toISOString(),
    path: req.path,
  });
}
