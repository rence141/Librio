import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/debug_logger.dart';

/// Analytics service for tracking user events and behavior
/// Uses Firebase Analytics for production analytics
class AnalyticsService {
  static const String _tag = 'AnalyticsService';
  
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Initialize analytics
  Future<void> initialize() async {
    try {
      // Enable analytics collection
      await _analytics.logAppOpen();
      DebugLogger.success(_tag, 'Analytics initialized');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to initialize analytics', e);
    }
  }

  /// Log user signup event
  Future<void> logSignup({
    required String method,
    required bool success,
    String? errorCode,
  }) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      
      if (!success && errorCode != null) {
        await logEvent(
          'signup_failed',
          parameters: {
            'method': method,
            'error_code': errorCode,
          },
        );
      }
      
      DebugLogger.info(_tag, 'Signup event logged: $method');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to log signup event', e);
    }
  }

  /// Log user login event
  Future<void> logLogin({
    required String method,
    required bool success,
    String? errorCode,
  }) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      
      if (!success && errorCode != null) {
        await logEvent(
          'login_failed',
          parameters: {
            'method': method,
            'error_code': errorCode,
          },
        );
      }
      
      DebugLogger.info(_tag, 'Login event logged: $method');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to log login event', e);
    }
  }

  /// Log custom event
  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      
      DebugLogger.info(_tag, 'Event logged: $name');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to log event: $name', e);
    }
  }

  /// Log flashcard creation
  Future<void> logFlashcardCreated({
    required String type,
    required String source,
  }) async {
    try {
      await logEvent(
        'flashcard_created',
        parameters: {
          'type': type,
          'source': source,
        },
      );
      
      DebugLogger.info(_tag, 'Flashcard created event logged');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to log flashcard created event', e);
    }
  }

  /// Log flashcard review started
  Future<void> logReviewStarted({
    required String deckId,
    required int cardCount,
  }) async {
    try {
      await logEvent(
        'review_started',
        parameters: {
          'deck_id': deckId,
          'card_count': cardCount,
        },
      );
      
      DebugLogger.info(_tag, 'Review started event logged');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to log review started event', e);
    }
  }

  /// Log flashcard review completed
  Future<void> logReviewCompleted({
    required String deckId,
    required int cardsReviewed,
    required int correctCount,
    required int duration,
  }) async {
    try {
      final accuracy = cardsReviewed > 0 ? (correctCount / cardsReviewed) * 100 : 0;
      
      await logEvent(
        'review_completed',
        parameters: {
          'deck_id': deckId,
          'cards_reviewed': cardsReviewed,
          'correct_count': correctCount,
          'accuracy': accuracy.toStringAsFixed(2),
          'duration_seconds': duration,
        },
      );
      
      DebugLogger.info(_tag, 'Review completed event logged');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to log review completed event', e);
    }
  }

  /// Log error event
  Future<void> logError({
    required String code,
    required String message,
    String? context,
  }) async {
    try {
      await logEvent(
        'error_occurred',
        parameters: {
          'error_code': code,
          'error_message': message,
          if (context != null) 'context': context,
        },
      );
      
      DebugLogger.info(_tag, 'Error event logged: $code');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to log error event', e);
    }
  }

  /// Log network error
  Future<void> logNetworkError({
    required String endpoint,
    required String errorType,
    int? statusCode,
  }) async {
    try {
      await logEvent(
        'network_error',
        parameters: {
          'endpoint': endpoint,
          'error_type': errorType,
          if (statusCode != null) 'status_code': statusCode,
        },
      );
      
      DebugLogger.info(_tag, 'Network error logged: $endpoint');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to log network error', e);
    }
  }

  /// Set user ID for analytics
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserProperty(name: 'user_id', value: userId);
      DebugLogger.info(_tag, 'User ID set: $userId');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to set user ID', e);
    }
  }

  /// Set user properties
  Future<void> setUserProperties({
    String? subscription,
    String? language,
    String? theme,
  }) async {
    try {
      if (subscription != null) {
        await _analytics.setUserProperty(
          name: 'subscription_tier',
          value: subscription,
        );
      }
      
      if (language != null) {
        await _analytics.setUserProperty(
          name: 'language',
          value: language,
        );
      }
      
      if (theme != null) {
        await _analytics.setUserProperty(
          name: 'theme',
          value: theme,
        );
      }
      
      DebugLogger.info(_tag, 'User properties set');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to set user properties', e);
    }
  }

  /// Clear user ID (on logout)
  Future<void> clearUserId() async {
    try {
      await _analytics.setUserProperty(name: 'user_id', value: null);
      DebugLogger.info(_tag, 'User ID cleared');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to clear user ID', e);
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      DebugLogger.info(_tag, 'Screen view logged: $screenName');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to log screen view', e);
    }
  }

  /// Log app performance
  Future<void> logPerformance({
    required String operation,
    required int duration,
    bool success = true,
    String? errorCode,
  }) async {
    try {
      await logEvent(
        'performance_metric',
        parameters: {
          'operation': operation,
          'duration_ms': duration,
          'success': success,
          if (errorCode != null) 'error_code': errorCode,
        },
      );
      
      DebugLogger.info(_tag, 'Performance metric logged: $operation');
    } catch (e) {
      DebugLogger.error(_tag, 'Failed to log performance metric', e);
    }
  }
}
