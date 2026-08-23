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
/// 3. Set SUPABASE_URL and SUPABASE_ANON_KEY below (or in env)
class OnlineModelConfig {
  // Supabase project URL (e.g. https://xxxxx.supabase.co)
  // Replace with your Supabase project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );

  // Supabase anon key (safe to expose — it's the public key)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );

  // Edge Function endpoint — constructed from Supabase URL
  static String get edgeFunctionUrl => '$supabaseUrl/functions/v1/ai-chat';

  // Available models (server-side controls which one is actually used)
  // The Edge Function can override this — these are client-side suggestions
  static const Map<String, String> models = {
    'gemini-2.0-flash': 'Gemini 2.0 Flash',
    'gemini-2.5-flash': 'Gemini 2.5 Flash',
    'gemini-2.5-pro': 'Gemini 2.5 Pro',
    'llama-3.3-70b': 'Llama 3.3 70B',
    'deepseek-r1': 'DeepSeek R1',
    'qwen3-32b': 'Qwen3 32B',
    'gpt-oss-120b': 'GPT-OSS 120B',
    'mistral-large': 'Mistral Large',
  };

  // Check if Supabase is configured
  static bool get isConfigured =>
      !supabaseUrl.contains('YOUR_PROJECT') &&
      !supabaseAnonKey.contains('YOUR_ANON_KEY');

  // Kept for backward compatibility — always true now since the key
  // is server-side. The check is whether Supabase is configured.
  static bool get hasKey => isConfigured;
}
