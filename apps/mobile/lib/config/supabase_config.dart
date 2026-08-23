import '../services/online_model_config.dart';

/// Supabase configuration for Librio.
///
/// The Supabase URL and anon key are safe to include in the client app.
/// The anon key is a public key — it only allows access to data permitted
/// by Row Level Security policies.
///
/// The FreeLLMAPI key is NEVER stored here — it's a server-side Supabase
/// secret accessed only by the Edge Function.
class SupabaseConfig {
  // Supabase project URL
  static String get supabaseUrl => OnlineModelConfig.supabaseUrl;

  // Supabase anon key (public — safe to expose)
  static String get supabaseAnonKey => OnlineModelConfig.supabaseAnonKey;

  // Edge Function endpoint
  static String get aiChatFunctionUrl => OnlineModelConfig.edgeFunctionUrl;
}
