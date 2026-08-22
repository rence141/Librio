import { Response } from 'express';

/**
 * Consistent API error codes for guardrail responses.
 * Never expose internal provider credentials, stack traces, or sensitive details.
 */
export const ErrorCode = {
  AUTH_REQUIRED: 'AUTH_REQUIRED',
  INVALID_REQUEST: 'INVALID_REQUEST',
  RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
  QUOTA_EXCEEDED: 'QUOTA_EXCEEDED',
  TOKEN_LIMIT_EXCEEDED: 'TOKEN_LIMIT_EXCEEDED',
  CONCURRENCY_LIMIT_EXCEEDED: 'CONCURRENCY_LIMIT_EXCEEDED',
  MODEL_UNAVAILABLE: 'MODEL_UNAVAILABLE',
  INSUFFICIENT_CREDITS: 'INSUFFICIENT_CREDITS',
  GLOBAL_LIMIT_REACHED: 'GLOBAL_LIMIT_REACHED',
  CONTENT_RESTRICTED: 'CONTENT_RESTRICTED',
  DOCUMENT_TOO_LARGE: 'DOCUMENT_TOO_LARGE',
  STORAGE_QUOTA_EXCEEDED: 'STORAGE_QUOTA_EXCEEDED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
} as const;

export type ErrorCodeType = (typeof ErrorCode)[keyof typeof ErrorCode];

export interface ApiError {
  code: ErrorCodeType;
  message: string;
  retryAfter?: number; // seconds
  details?: Record<string, unknown>;
}

/**
 * Send a consistent error response.
 */
export function sendError(
  res: Response,
  status: number,
  error: ApiError,
): Response {
  return res.status(status).json({ error });
}

/** 401 — Authentication required */
export function authRequired(res: Response): Response {
  return sendError(res, 401, {
    code: ErrorCode.AUTH_REQUIRED,
    message: 'Authentication required for cloud AI usage.',
  });
}

/** 400 — Invalid request */
export function invalidRequest(res: Response, message: string, details?: Record<string, unknown>): Response {
  return sendError(res, 400, {
    code: ErrorCode.INVALID_REQUEST,
    message,
    details,
  });
}

/** 429 — Rate limit exceeded */
export function rateLimitExceeded(res: Response, retryAfter: number): Response {
  return sendError(res, 429, {
    code: ErrorCode.RATE_LIMIT_EXCEEDED,
    message: 'Too many requests. Please try again later.',
    retryAfter,
  });
}

/** 429 — Quota exceeded */
export function quotaExceeded(res: Response, message: string, retryAfter?: number): Response {
  return sendError(res, 429, {
    code: ErrorCode.QUOTA_EXCEEDED,
    message,
    retryAfter,
  });
}

/** 429 — Token limit exceeded */
export function tokenLimitExceeded(res: Response, message: string): Response {
  return sendError(res, 429, {
    code: ErrorCode.TOKEN_LIMIT_EXCEEDED,
    message,
  });
}

/** 429 — Concurrency limit exceeded */
export function concurrencyLimitExceeded(res: Response): Response {
  return sendError(res, 429, {
    code: ErrorCode.CONCURRENCY_LIMIT_EXCEEDED,
    message: 'Too many concurrent AI requests. Please wait for your current request to finish.',
    retryAfter: 30,
  });
}

/** 403 — Insufficient credits */
export function insufficientCredits(res: Response): Response {
  return sendError(res, 403, {
    code: ErrorCode.INSUFFICIENT_CREDITS,
    message: 'Insufficient AI credits for this model. Try a less expensive model or upgrade your plan.',
  });
}

/** 503 — Global spending limit reached (kill switch) */
export function globalLimitReached(res: Response): Response {
  return sendError(res, 503, {
    code: ErrorCode.GLOBAL_LIMIT_REACHED,
    message: 'Cloud AI is temporarily unavailable due to system-wide spending limits. Local AI remains available.',
    retryAfter: 3600,
  });
}

/** 403 — Content restricted */
export function contentRestricted(res: Response, reason: string): Response {
  return sendError(res, 403, {
    code: ErrorCode.CONTENT_RESTRICTED,
    message: `Content restricted: ${reason}`,
  });
}

/** 413 — Document too large */
export function documentTooLarge(res: Response, maxMB: number): Response {
  return sendError(res, 413, {
    code: ErrorCode.DOCUMENT_TOO_LARGE,
    message: `Document exceeds maximum size of ${maxMB} MB.`,
  });
}

/** 413 — Storage quota exceeded */
export function storageQuotaExceeded(res: Response): Response {
  return sendError(res, 413, {
    code: ErrorCode.STORAGE_QUOTA_EXCEEDED,
    message: 'Document storage quota exceeded. Delete old documents to upload new ones.',
  });
}

/** 403 — Forbidden (model not allowed for tier) */
export function forbidden(res: Response, message: string): Response {
  return sendError(res, 403, {
    code: ErrorCode.FORBIDDEN,
    message,
  });
}

/** 503 — Model unavailable */
export function modelUnavailable(res: Response, modelId: string): Response {
  return sendError(res, 503, {
    code: ErrorCode.MODEL_UNAVAILABLE,
    message: `Model '${modelId}' is currently unavailable.`,
  });
}
