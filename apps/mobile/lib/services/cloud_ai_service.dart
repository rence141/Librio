import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/debug_logger.dart';

/// Cloud AI service — calls Librio backend (NEVER calls providers directly).
///
/// Architecture:
///   Flutter → Librio Backend → Provider API
///   NOT: Flutter → Provider API
///
/// All cloud usage is server-controlled:
///   - Authentication
///   - Rate limits
///   - Token quotas
///   - Concurrency limits
///   - Global spending caps
///   - Safety checks
///
/// Local AI (LlmService) is separate and unrestricted offline.
class CloudAiService {
  static final CloudAiService _instance = CloudAiService._internal();

  factory CloudAiService() => _instance;

  CloudAiService._internal();

  String? _authToken;
  String _baseUrl = 'http://localhost:3000';

  /// Configure the backend URL.
  void configure({required String baseUrl, String? authToken}) {
    _baseUrl = baseUrl;
    if (authToken != null) _authToken = authToken;
  }

  /// Set the auth token (from login).
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Check if cloud AI is available (global spending cap, etc.).
  Future<bool> isCloudAvailable() async {
    if (_authToken == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/ai/status'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['cloudEnabled'] == true;
      }
      return false;
    } catch (e, st) {
      DebugLogger.error('CloudAi', 'Status check failed', e, st);
      return false;
    }
  }

  /// Generate a response via the cloud backend.
  ///
  /// The client requests a CAPABILITY (fast, advanced, premium), not a specific model.
  /// The backend determines which model the user can access.
  ///
  /// Returns null if the request fails (caller should fall back to local AI).
  Future<CloudAiResponse?> generate({
    required String prompt,
    String capability = 'fast',
    int? maxOutputTokens,
    double? temperature,
    String? systemPrompt,
    String? requestId, // For idempotency / retry
  }) async {
    const tag = 'CloudAi';

    if (_authToken == null) {
      DebugLogger.warning(tag, 'No auth token — cloud AI unavailable');
      return null;
    }

    try {
      final body = <String, dynamic>{
        'prompt': prompt,
        'capability': capability,
      };
      if (maxOutputTokens != null) body['maxOutputTokens'] = maxOutputTokens;
      if (temperature != null) body['temperature'] = temperature;
      if (systemPrompt != null) body['systemPrompt'] = systemPrompt;
      if (requestId != null) body['requestId'] = requestId;

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/ai/generate'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // If backend says to use local model
        if (data['useLocalModel'] == true) {
          DebugLogger.info(tag, 'Backend routed to local model');
          return CloudAiResponse(
            text: '',
            model: data['model'] ?? 'local',
            provider: 'local',
            useLocalModel: true,
            inputTokens: 0,
            outputTokens: 0,
            creditsConsumed: 0,
          );
        }

        return CloudAiResponse(
          text: data['text'] ?? '',
          model: data['model'] ?? 'unknown',
          provider: data['provider'] ?? 'unknown',
          useLocalModel: false,
          inputTokens: data['usage']?['inputTokens'] ?? 0,
          outputTokens: data['usage']?['outputTokens'] ?? 0,
          creditsConsumed: data['usage']?['creditsConsumed'] ?? 0,
        );
      }

      // Handle error responses
      final error = jsonDecode(response.body)?['error'];
      final code = error?['code'] ?? 'UNKNOWN';
      final message = error?['message'] ?? 'Unknown error';
      final retryAfter = error?['retryAfter'];

      DebugLogger.warning(tag, 'Cloud AI error: $code - $message (status ${response.statusCode})');

      return CloudAiResponse(
        text: '',
        model: '',
        provider: '',
        useLocalModel: false,
        inputTokens: 0,
        outputTokens: 0,
        creditsConsumed: 0,
        error: CloudAiError(
          code: code,
          message: message,
          retryAfter: retryAfter,
          statusCode: response.statusCode,
        ),
      );
    } on SocketException catch (e) {
      DebugLogger.warning(tag, 'Network error — falling back to local: $e');
      return null;
    } catch (e, st) {
      DebugLogger.error(tag, 'Generate failed', e, st);
      return null;
    }
  }

  /// Get available models for the user's tier.
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    if (_authToken == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/ai/models'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['models'] ?? []);
      }
    } catch (e, st) {
      DebugLogger.error('CloudAi', 'getModels failed', e, st);
    }
    return [];
  }

  /// Get current usage and limits.
  Future<Map<String, dynamic>?> getUsage() async {
    if (_authToken == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/ai/usage'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e, st) {
      DebugLogger.error('CloudAi', 'getUsage failed', e, st);
    }
    return null;
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_authToken',
    };
  }
}

/// Response from cloud AI generation.
class CloudAiResponse {
  final String text;
  final String model;
  final String provider;
  final bool useLocalModel;
  final int inputTokens;
  final int outputTokens;
  final int creditsConsumed;
  final CloudAiError? error;

  CloudAiResponse({
    required this.text,
    required this.model,
    required this.provider,
    required this.useLocalModel,
    required this.inputTokens,
    required this.outputTokens,
    required this.creditsConsumed,
    this.error,
  });

  bool get hasError => error != null;
}

/// Error from cloud AI backend.
class CloudAiError {
  final String code;
  final String message;
  final int? retryAfter;
  final int statusCode;

  CloudAiError({
    required this.code,
    required this.message,
    this.retryAfter,
    required this.statusCode,
  });

  /// Whether this is a rate-limit error (should retry later).
  bool get isRateLimit => code == 'RATE_LIMIT_EXCEEDED';

  /// Whether this is a quota error (should wait for reset).
  bool get isQuotaExceeded =>
      code == 'QUOTA_EXCEEDED' ||
      code == 'TOKEN_LIMIT_EXCEEDED' ||
      code == 'INSUFFICIENT_CREDITS';

  /// Whether this is a global limit (cloud disabled, use local).
  bool get isGlobalLimit => code == 'GLOBAL_LIMIT_REACHED';

  /// Whether this is a concurrency error (wait and retry).
  bool get isConcurrencyLimit => code == 'CONCURRENCY_LIMIT_EXCEEDED';

  /// Whether this is a content restriction.
  bool get isContentRestricted => code == 'CONTENT_RESTRICTED';
}
