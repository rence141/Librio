import 'package:supabase_flutter/supabase_flutter.dart';

/// Online model configuration.
///
/// AI requests are routed through Supabase Edge Functions, NOT directly
/// to FreeLLMAPI. This keeps the FreeLLMAPI key server-side only.
///
/// Architecture:
///   Flutter → Supabase Edge Function (/functions/v1/ai-chat) → FreeLLMAPI → LLM
///
/// The FreeLLMAPI key is stored as a Supabase secret (FREELLM_API_KEY)
/// and is NEVER present in the Flutter app.
///
/// SETUP:
/// 1. Deploy the ai-chat Edge Function to Supabase
/// 2. Set FREELLM_API_KEY as a Supabase secret
/// 3. Supabase URL and anon key are initialized in main.dart
class OnlineModelConfig {
  /// Get Supabase URL from the already-initialized Supabase instance.
  /// This works at runtime on all platforms (Android, iOS, web, desktop).
  static String get supabaseUrl {
    try {
      final url = Supabase.instance.client.supabaseUrl;
      if (url.isNotEmpty) {
        return url;
      }
    } catch (e) {
      // Supabase not initialized yet
    }
    return '';
  }

  /// Get Supabase anon key from the already-initialized Supabase instance.
  /// This is the public key — safe to expose.
  /// 
  /// Note: The anon key is stored in the Supabase client's rest client.
  /// We access it via the client's internal state.
  static String get supabaseAnonKey {
    try {
      final client = Supabase.instance.client;
      // The anon key is passed as 'apikey' header in REST requests
      final key = client.rest.headers['apikey'];
      if (key != null && key.isNotEmpty) {
        return key;
      }
    } catch (e) {
      // Supabase not initialized yet or key not available
    }
    return '';
  }

  /// Edge Function endpoint — constructed from Supabase URL
  static String get edgeFunctionUrl => '$supabaseUrl/functions/v1/ai-chat';

  // Available models (server-side controls which one is actually used)
  // The Edge Function can override this — these are client-side suggestions
  // Model names must match FreeLLMAPI's catalog (check /v1/models)
  static const Map<String, String> models = {
    'auto': 'Auto (router picks best)',
    'gemini-2.5-flash': 'Gemini 2.5 Flash',
    'gemini-3.5-flash': 'Gemini 3.5 Flash',
    'gemini-3.6-flash': 'Gemini 3.6 Flash',
    'gpt-oss-120b': 'GPT-OSS 120B',
    'gpt-oss-20b': 'GPT-OSS 20B',
    'qwen3.6-27b': 'Qwen3.6 27B',
    'gemma-4-31b-it': 'Gemma 4 31B',
    'fusion': 'Fusion (panel of models)',
  };

  /// Check if Supabase is properly initialized and configured.
  /// This verifies that:
  /// 1. Supabase instance exists
  /// 2. URL is valid (not empty, not a placeholder)
  /// 3. Anon key is available
  static bool get isConfigured {
    try {
      final url = supabaseUrl;
      final key = supabaseAnonKey;
      
      // Check that URL is valid and not a placeholder
      if (url.isEmpty || url.contains('YOUR_PROJECT')) {
        return false;
      }
      
      // Check that anon key is valid and not a placeholder
      if (key.isEmpty || key.contains('YOUR_ANON_KEY')) {
        return false;
      }
      
      return true;
    } catch (e) {
      // Supabase not initialized
      return false;
    }
  }

  /// Backward compatibility — same as isConfigured since the AI key
  /// is server-side. The check is whether Supabase is configured.
  static bool get hasKey => isConfigured;
}
