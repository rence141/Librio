import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/debug_logger.dart';
import 'online_model_config.dart';

/// Response wrapper that includes token usage data
class AiResponse {
  final String text;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final String? model;
  final int? remaining;

  AiResponse({
    required this.text,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    this.model,
    this.remaining,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    // Parse usage data if available
    int? inputTokens = json['usage']?['inputTokens'] as int?;
    int? outputTokens = json['usage']?['outputTokens'] as int?;
    
    // Fallback: estimate tokens if not provided
    // Rough estimate: ~4 characters per token
    if (outputTokens == null && json['text'] != null) {
      final text = json['text'] as String;
      outputTokens = (text.length / 4).ceil();
    }
    
    // Estimate input tokens if not provided (assume ~100 chars per prompt)
    if (inputTokens == null) {
      inputTokens = 50; // Conservative estimate for typical prompts
    }
    
    return AiResponse(
      text: json['text'] ?? '',
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: json['usage']?['totalTokens'] as int?,
      model: json['model'] as String?,
      remaining: json['remaining'] as int?,
    );
  }
}

/// Online LLM service via Supabase Edge Function.
///
/// Architecture:
///   Flutter → Supabase Edge Function → FreeLLMAPI → LLM
///
/// The FreeLLMAPI key is NEVER stored in the Flutter app.
/// All AI requests go through the Supabase Edge Function which:
///   - Authenticates the user
///   - Enforces rate limits
///   - Injects the Librio system prompt
///   - Calls FreeLLMAPI server-side
///   - Returns the response to the client
class OnlineLlmService {
  // System prompt is now server-side (in the Edge Function).
  // It's kept here only for reference — the Edge Function injects it.
  // Do NOT send the system prompt from the client to avoid bypassing
  // server-side guardrails.

  /// Build the user message content — supports text + images (vision format).
  /// Images are sent as base64-encoded data URLs in the OpenAI vision format.
  List<Map<String, dynamic>> _buildUserContent(String prompt, List<String> imagePaths) {
    final content = <Map<String, dynamic>>[];

    // Add images first (vision models process them as part of the message)
    for (final path in imagePaths) {
      if (_isImagePath(path)) {
        try {
          final bytes = File(path).readAsBytesSync();
          final base64Str = base64Encode(bytes);
          final ext = path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
          content.add({
            'type': 'image_url',
            'image_url': {'url': 'data:image/$ext;base64,$base64Str'},
          });
        } catch (e) {
          DebugLogger.error('OnlineLlm', 'Failed to read image: $path', e, null);
        }
      } else {
        // Non-image file — include filename as text context
        final filename = path.split('/').last.split('\\').last;
        content.add({
          'type': 'text',
          'text': '[Attached file: $filename]',
        });
      }
    }

    // Add the text prompt (even if empty — images need context)
    final text = prompt.trim().isEmpty
        ? 'Please analyze the image(s) above and respond appropriately based on what you see.'
        : prompt;
    content.add({'type': 'text', 'text': text});

    return content;
  }

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  /// Generate a response with token usage data.
  /// Returns AiResponse which includes text and token counts.
  Future<AiResponse> generateResponseWithUsage(
    String prompt, {
    String model = 'gemini-2.0-flash',
    List<String> imagePaths = const [],
    List<Map<String, String>>? conversationContext,
    String? authToken,
  }) async {
    const tag = 'OnlineLlm';

    if (!OnlineModelConfig.isConfigured) {
      final errorMsg = _getConfigurationErrorMessage();
      return AiResponse(text: errorMsg);
    }

    try {
      final url = Uri.parse(OnlineModelConfig.edgeFunctionUrl);

      final body = <String, dynamic>{
        'prompt': prompt,
        'model': model,
      };

      if (imagePaths.isNotEmpty) {
        body['imageContent'] = _buildUserContent(prompt, imagePaths);
      }

      if (conversationContext != null && conversationContext.isNotEmpty) {
        body['conversationContext'] = conversationContext;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(url, headers: headers, body: jsonEncode(body));

      if (response.statusCode == 401) {
        DebugLogger.error(tag, 'Authentication required', null, null);
        return AiResponse(text: 'Please sign in to use AI features.');
      }

      if (response.statusCode == 429) {
        final data = jsonDecode(response.body);
        final message = data['error']?['message'] ?? 'You\'ve reached your AI usage limit.';
        DebugLogger.error(tag, 'Rate limited: $message', null, null);
        return AiResponse(text: message);
      }

      if (response.statusCode != 200) {
        DebugLogger.error(tag, 'Edge Function error: ${response.statusCode}',
            Exception(response.body), null);
        final data = jsonDecode(response.body);
        final message = data['error']?['message'] ?? 'Unable to process your request. Please try again.';
        return AiResponse(text: message);
      }

      final data = jsonDecode(response.body);
      DebugLogger.success(tag, 'Response: ${data['text']?.length ?? 0} chars');
      DebugLogger.info(tag, 'Usage data: ${data['usage']}');
      return AiResponse.fromJson(data);
    } catch (e, st) {
      DebugLogger.error(tag, 'Request failed', e, st);
      return AiResponse(text: 'Unable to connect to AI service. Please check your internet connection and try again.');
    }
  }

  /// Generate a response (non-streaming).
  /// Calls the Supabase Edge Function which handles auth, rate limiting,
  /// system prompt injection, and FreeLLMAPI communication.
  Future<String> generateResponse(
    String prompt, {
    String model = 'gemini-2.0-flash',
    List<String> imagePaths = const [],
    List<Map<String, String>>? conversationContext,
    String? authToken,
  }) async {
    const tag = 'OnlineLlm';

    if (!OnlineModelConfig.isConfigured) {
      return _getConfigurationErrorMessage();
    }

    try {
      final url = Uri.parse(OnlineModelConfig.edgeFunctionUrl);

      // Build request body — the Edge Function adds the system prompt
      final body = <String, dynamic>{
        'prompt': prompt,
        'model': model,
      };

      // Add image content if present
      if (imagePaths.isNotEmpty) {
        body['imageContent'] = _buildUserContent(prompt, imagePaths);
      }

      // Add conversation context if provided
      if (conversationContext != null && conversationContext.isNotEmpty) {
        body['conversationContext'] = conversationContext;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Add auth token if available
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(url, headers: headers, body: jsonEncode(body));

      if (response.statusCode == 401) {
        DebugLogger.error(tag, 'Authentication required', null, null);
        return 'Error: Authentication required. Please sign in to use AI features.';
      }

      if (response.statusCode == 429) {
        final data = jsonDecode(response.body);
        final message = data['error']?['message'] ?? 'Rate limit exceeded.';
        DebugLogger.error(tag, 'Rate limited: $message', null, null);
        return 'Error: $message';
      }

      if (response.statusCode != 200) {
        DebugLogger.error(tag, 'Edge Function error: ${response.statusCode}',
            Exception(response.body), null);
        final data = jsonDecode(response.body);
        final message = data['error']?['message'] ?? 'Request failed.';
        return 'Error: $message';
      }

      final data = jsonDecode(response.body);
      final text = data['text'] ?? '';
      DebugLogger.success(tag, 'Response: ${text.length} chars');
      // Token usage is available in data['usage'] if needed by caller
      return text;
    } catch (e, st) {
      DebugLogger.error(tag, 'Request failed', e, st);
      return 'Error connecting to AI service: $e';
    }
  }

  /// Stream response (token by token).
  /// Currently fetches the full response from the Edge Function and
  /// yields it in chunks to simulate streaming.
  /// True SSE streaming can be added later by updating the Edge Function.
  Stream<String> streamResponse(
    String prompt, {
    String model = 'gemini-2.0-flash',
    List<String> imagePaths = const [],
    List<Map<String, String>>? conversationContext,
    String? authToken,
  }) async* {
    const tag = 'OnlineLlm';

    if (!OnlineModelConfig.isConfigured) {
      yield _getConfigurationErrorMessage();
      return;
    }

    try {
      final url = Uri.parse(OnlineModelConfig.edgeFunctionUrl);

      final body = <String, dynamic>{
        'prompt': prompt,
        'model': model,
      };

      if (imagePaths.isNotEmpty) {
        body['imageContent'] = _buildUserContent(prompt, imagePaths);
      }

      if (conversationContext != null && conversationContext.isNotEmpty) {
        body['conversationContext'] = conversationContext;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(url, headers: headers, body: jsonEncode(body));

      if (response.statusCode == 401) {
        yield 'Error: Authentication required. Please sign in to use AI features.';
        return;
      }

      if (response.statusCode == 429) {
        final data = jsonDecode(response.body);
        final message = data['error']?['message'] ?? 'Rate limit exceeded.';
        yield 'Error: $message';
        return;
      }

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        final message = data['error']?['message'] ?? 'Request failed.';
        yield 'Error: $message';
        return;
      }

      DebugLogger.info(tag, 'Response received from Edge Function');

      final data = jsonDecode(response.body);
      final fullText = data['text'] ?? '';

      // Yield in word chunks to simulate streaming
      final words = fullText.split(' ');
      for (int i = 0; i < words.length; i++) {
        if (i == 0) {
          yield words[i];
        } else {
          yield ' ${words[i]}';
        }
        // Small delay to simulate streaming UX
        await Future.delayed(const Duration(milliseconds: 10));
      }

      DebugLogger.success(tag, 'Stream complete');
    } catch (e, st) {
      DebugLogger.error(tag, 'Stream failed', e, st);
      yield 'Error connecting to AI service: $e';
    }
  }

  /// Generate a short conversation title from the first user message.
  /// Returns 3-7 words, no quotes.
  Future<String> generateTitle(
    String userMessage, {
    String model = 'gemini-2.0-flash',
    String? authToken,
  }) async {
    const tag = 'OnlineLlm';

    if (!OnlineModelConfig.isConfigured) {
      return _fallbackTitle(userMessage);
    }

    try {
      final url = Uri.parse(OnlineModelConfig.edgeFunctionUrl);

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'prompt': userMessage,
          'generateTitle': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = (data['title'] ?? '').trim();
        if (title.isNotEmpty) {
          final cleaned = title.replaceAll('"', '').replaceAll("'", '').replaceAll('`', '').trim();
          DebugLogger.info(tag, 'Generated title: $cleaned');
          return cleaned;
        }
      }
    } catch (e) {
      DebugLogger.error(tag, 'Title generation failed', e, null);
    }

    return _fallbackTitle(userMessage);
  }

  /// Fallback: derive a title from the first few words of the message
  String _fallbackTitle(String userMessage) {
    final words = userMessage.trim().split(RegExp(r'\s+'));
    if (words.length <= 7) return userMessage.trim();
    return words.take(7).join(' ');
  }

  /// Generate a helpful error message when Supabase is not configured
  String _getConfigurationErrorMessage() {
    final url = OnlineModelConfig.supabaseUrl;
    final key = OnlineModelConfig.supabaseAnonKey;

    if (url.isEmpty) {
      return '❌ Supabase URL not configured. Check that Supabase is initialized in main.dart with a valid URL.';
    }

    if (key.isEmpty) {
      return '❌ Supabase anon key not configured. Check that Supabase is initialized in main.dart with a valid anon key.';
    }

    return '❌ Supabase configuration incomplete. Please ensure Supabase is properly initialized before using the online model.';
  }
}
