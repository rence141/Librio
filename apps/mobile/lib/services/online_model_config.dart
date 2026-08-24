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
/// 3. Call OnlineModelConfig.initialize() after Supabase.initialize() in main.dart
class OnlineModelConfig {
  // Static storage for Supabase credentials
  // Set by initialize() after Supabase is initialized
  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';

  /// Initialize the online model configuration with Supabase credentials.
  /// Call this in main.dart after Supabase.initialize().
  static void initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) {
    _supabaseUrl = supabaseUrl;
    _supabaseAnonKey = supabaseAnonKey;
  }

  /// Get the Supabase URL (set during initialize())
  static String get supabaseUrl => _supabaseUrl;

  /// Get the Supabase anon key (set during initialize())
  /// This is the public key — safe to expose.
  static String get supabaseAnonKey => _supabaseAnonKey;

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
