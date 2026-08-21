import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase service for backend integration
class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Initialize Supabase
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  /// Get current user
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  // ============ AUTHENTICATION ============

  /// Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName ?? '',
      },
    );

    // Create user profile
    if (response.user != null) {
      await _createUserProfile(
        userId: response.user!.id,
        fullName: fullName,
        email: email,
      );
    }

    return response;
  }

  /// Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Create user profile
  static Future<void> _createUserProfile({
    required String userId,
    String? fullName,
    String? email,
  }) async {
    try {
      await _client.from('user_profiles').insert({
        'id': userId,
        'full_name': fullName,
        'email': email,
        'subscription_tier': 'free',
        'storage_limit_mb': 1000,
      });
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  // ============ DOCUMENTS (RAG) ============

  /// Add document with embedding
  static Future<void> addDocument({
    required String title,
    required String content,
    required List<double> embedding,
    required String source,
    required String category,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from('documents').insert({
      'user_id': userId,
      'title': title,
      'content': content,
      'embedding': embedding,
      'source': source,
      'category': category,
      'metadata': metadata ?? {},
    });
  }

  /// Search documents by similarity
  static Future<List<Map<String, dynamic>>> searchDocuments({
    required List<double> embedding,
    int limit = 5,
    String? category,
    double threshold = 0.5,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final response = await _client.rpc(
        'search_documents',
        params: {
          'query_embedding': embedding,
          'match_count': limit,
          'filter_category': category,
          'similarity_threshold': threshold,
        },
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error searching documents: $e');
      return [];
    }
  }

  /// Get documents by category
  static Future<List<Map<String, dynamic>>> getDocumentsByCategory(
    String category,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('documents')
        .select()
        .eq('user_id', userId)
        .eq('category', category)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get all documents
  static Future<List<Map<String, dynamic>>> getAllDocuments() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('documents')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Delete document
  static Future<void> deleteDocument(String documentId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('documents')
        .delete()
        .eq('id', documentId)
        .eq('user_id', userId);
  }

  /// Get document count
  static Future<int> getDocumentCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('documents')
        .select('id', const FetchOptions(count: CountOption.exact))
        .eq('user_id', userId);

    return response.length;
  }

  // ============ BENCHMARKS ============

  /// Save benchmark result
  static Future<void> saveBenchmark({
    required String deviceName,
    required String modelId,
    required int loadTimeMs,
    required int ttftMs,
    required double decodeSpeed,
    required int peakRamMb,
    double? batteryDrainPercentPerHour,
    int? totalInferenceTimeMs,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from('benchmarks').insert({
      'user_id': userId,
      'device_name': deviceName,
      'model_id': modelId,
      'load_time_ms': loadTimeMs,
      'ttft_ms': ttftMs,
      'decode_speed_tokens_per_sec': decodeSpeed,
      'peak_ram_mb': peakRamMb,
      'battery_drain_percent_per_hour': batteryDrainPercentPerHour,
      'total_inference_time_ms': totalInferenceTimeMs,
      'metadata': metadata ?? {},
    });
  }

  /// Get benchmarks for device
  static Future<List<Map<String, dynamic>>> getBenchmarksForDevice(
    String deviceName,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('benchmarks')
        .select()
        .eq('user_id', userId)
        .eq('device_name', deviceName)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get all benchmarks
  static Future<List<Map<String, dynamic>>> getAllBenchmarks() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('benchmarks')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ============ SESSIONS (RAG CONTEXT) ============

  /// Create session
  static Future<String> createSession({
    required String title,
    Map<String, dynamic>? context,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client.from('sessions').insert({
      'user_id': userId,
      'title': title,
      'context': context ?? {},
    }).select();

    return response.first['id'] as String;
  }

  /// Get session
  static Future<Map<String, dynamic>?> getSession(String sessionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  /// Update session context
  static Future<void> updateSessionContext(
    String sessionId,
    Map<String, dynamic> context,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client
        .from('sessions')
        .update({'context': context})
        .eq('id', sessionId)
        .eq('user_id', userId);
  }

  /// Get all sessions
  static Future<List<Map<String, dynamic>>> getAllSessions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('sessions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ============ MESSAGES (CONVERSATION HISTORY) ============

  /// Add message to session
  static Future<void> addMessage({
    required String sessionId,
    required String role,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from('messages').insert({
      'session_id': sessionId,
      'user_id': userId,
      'role': role,
      'content': content,
      'metadata': metadata ?? {},
    });
  }

  /// Get messages for session
  static Future<List<Map<String, dynamic>>> getSessionMessages(
    String sessionId,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('messages')
        .select()
        .eq('session_id', sessionId)
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // ============ REAL-TIME SUBSCRIPTIONS ============

  /// Listen to document changes
  static RealtimeChannel listenToDocuments(
    Function(RealtimeMessage) onDocumentChange,
  ) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _client
        .from('documents')
        .on(
          RealtimeListenTypes.all,
          (payload) => onDocumentChange(payload),
        )
        .eq('user_id', userId)
        .subscribe();
  }

  /// Listen to session messages
  static RealtimeChannel listenToSessionMessages(
    String sessionId,
    Function(RealtimeMessage) onMessageChange,
  ) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _client
        .from('messages')
        .on(
          RealtimeListenTypes.all,
          (payload) => onMessageChange(payload),
        )
        .eq('session_id', sessionId)
        .eq('user_id', userId)
        .subscribe();
  }

  /// Unsubscribe from channel
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  // ============ USER PROFILE ============

  /// Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  /// Update user profile
  static Future<void> updateUserProfile({
    String? fullName,
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bio != null) updates['bio'] = bio;

    await _client
        .from('user_profiles')
        .update(updates)
        .eq('id', userId);
  }

  // ============ UTILITY ============

  /// Get storage usage
  static Future<Map<String, dynamic>?> getStorageUsage() async {
    final profile = await getUserProfile();
    if (profile == null) return null;

    return {
      'used_mb': profile['storage_used_mb'] ?? 0,
      'limit_mb': profile['storage_limit_mb'] ?? 1000,
      'percentage': ((profile['storage_used_mb'] ?? 0) /
              (profile['storage_limit_mb'] ?? 1000) *
              100)
          .toStringAsFixed(1),
    };
  }

  /// Get database stats
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final docCount = await getDocumentCount();
    final sessions = await getAllSessions();
    final benchmarks = await getAllBenchmarks();

    return {
      'documents': docCount,
      'sessions': sessions.length,
      'benchmarks': benchmarks.length,
      'user_id': userId,
    };
  }
}
