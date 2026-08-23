import 'package:flutter/material.dart';
import '../utils/debug_logger.dart';

/// Custom exception classes for Librio
abstract class AppException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  AppException({
    required this.message,
    required this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Authentication errors
class AuthenticationException extends AppException {
  AuthenticationException({
    String message = 'Authentication failed',
    String code = 'AUTH_ERROR',
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

class InvalidCredentialsException extends AppException {
  InvalidCredentialsException({
    String message = 'Invalid email or password',
    dynamic originalError,
  }) : super(
    message: message,
    code: 'INVALID_CREDENTIALS',
    originalError: originalError,
  );
}

class TokenExpiredException extends AppException {
  TokenExpiredException({
    String message = 'Session expired. Please login again.',
    dynamic originalError,
  }) : super(
    message: message,
    code: 'TOKEN_EXPIRED',
    originalError: originalError,
  );
}

/// Network errors
class NetworkException extends AppException {
  NetworkException({
    String message = 'Network error. Please check your connection.',
    String code = 'NETWORK_ERROR',
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

class TimeoutException extends AppException {
  TimeoutException({
    String message = 'Request timed out. Please try again.',
    dynamic originalError,
  }) : super(
    message: message,
    code: 'TIMEOUT',
    originalError: originalError,
  );
}

/// Validation errors
class ValidationException extends AppException {
  ValidationException({
    required String message,
    String code = 'VALIDATION_ERROR',
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

class InvalidEmailException extends AppException {
  InvalidEmailException({
    String message = 'Invalid email format',
    dynamic originalError,
  }) : super(
    message: message,
    code: 'INVALID_EMAIL',
    originalError: originalError,
  );
}

class WeakPasswordException extends AppException {
  WeakPasswordException({
    String message = 'Password must be at least 8 characters',
    dynamic originalError,
  }) : super(
    message: message,
    code: 'WEAK_PASSWORD',
    originalError: originalError,
  );
}

/// Server errors
class ServerException extends AppException {
  ServerException({
    String message = 'Server error. Please try again later.',
    String code = 'SERVER_ERROR',
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

/// Unknown errors
class UnknownException extends AppException {
  UnknownException({
    String message = 'An unexpected error occurred',
    dynamic originalError,
  }) : super(
    message: message,
    code: 'UNKNOWN_ERROR',
    originalError: originalError,
  );
}

/// Error handler utility
class ErrorHandler {
  static const String _tag = 'ErrorHandler';

  /// Convert exception to user-friendly message
  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is Exception) {
      return error.toString();
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Get error code
  static String getErrorCode(dynamic error) {
    if (error is AppException) {
      return error.code;
    }
    return 'UNKNOWN_ERROR';
  }

  /// Log error
  static void logError(
    dynamic error, {
    String? tag,
    StackTrace? stackTrace,
  }) {
    final errorTag = tag ?? _tag;
    final message = getUserMessage(error);
    final code = getErrorCode(error);

    DebugLogger.error(
      errorTag,
      '[$code] $message',
      error,
      stackTrace,
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
    VoidCallback? onAction,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAction?.call();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackbar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.red,
        action: action,
      ),
    );
  }

  /// Show retry dialog
  static Future<bool> showRetryDialog(
    BuildContext context, {
    required String title,
    required String message,
    String retryLabel = 'Retry',
    String cancelLabel = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(retryLabel),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error is NetworkException || error is TimeoutException) {
      return true;
    }

    final message = getUserMessage(error).toLowerCase();
    return message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout');
  }

  /// Check if error is authentication-related
  static bool isAuthError(dynamic error) {
    if (error is AuthenticationException ||
        error is InvalidCredentialsException ||
        error is TokenExpiredException) {
      return true;
    }

    final code = getErrorCode(error);
    return code.contains('AUTH') || code.contains('TOKEN');
  }

  /// Check if error is validation-related
  static bool isValidationError(dynamic error) {
    if (error is ValidationException ||
        error is InvalidEmailException ||
        error is WeakPasswordException) {
      return true;
    }

    final code = getErrorCode(error);
    return code.contains('VALIDATION') ||
        code.contains('INVALID') ||
        code.contains('WEAK');
  }
}

/// Retry helper for network operations
class RetryHelper {
  static const int defaultMaxRetries = 3;
  static const Duration defaultDelay = Duration(seconds: 1);

  /// Retry an async operation
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration delay = defaultDelay,
    bool Function(dynamic error)? retryIf,
  }) async {
    int attempts = 0;

    while (true) {
      try {
        return await operation();
      } catch (error) {
        attempts++;

        // Check if we should retry
        final shouldRetry = retryIf?.call(error) ?? ErrorHandler.isNetworkError(error);

        if (!shouldRetry || attempts >= maxRetries) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay * attempts);
      }
    }
  }

  /// Retry with exponential backoff
  static Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = const Duration(milliseconds: 100),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? retryIf,
  }) async {
    int attempts = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (error) {
        attempts++;

        // Check if we should retry
        final shouldRetry = retryIf?.call(error) ?? ErrorHandler.isNetworkError(error);

        if (!shouldRetry || attempts >= maxRetries) {
          rethrow;
        }

        // Wait with exponential backoff
        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).toInt(),
        );
      }
    }
  }
}
