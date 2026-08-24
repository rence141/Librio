import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/ai_plans.dart';
import '../utils/debug_logger.dart';

/// Service to track and manage AI usage for the current user.
/// 
/// This service provides client-side usage tracking for UX purposes.
/// Server-side enforcement is mandatory and happens in the Edge Function.
class AiUsageService {
  static final AiUsageService _instance = AiUsageService._internal();

  factory AiUsageService() {
    return _instance;
  }

  AiUsageService._internal();

  final _supabase = Supabase.instance.client;
  AiUsageSnapshot? _cachedUsage;
  DateTime? _cacheTime;
  static const _cacheValidityDuration = Duration(seconds: 30);

  /// Get current AI usage for the authenticated user
  /// 
  /// Returns cached data if available and fresh (< 30 seconds old).
  /// Otherwise fetches from the server.
  Future<AiUsageSnapshot?> getCurrentUsage() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        DebugLogger.warning('AiUsageService', 'No authenticated user');
        return null;
      }

      // Return cached data if fresh
      if (_cachedUsage != null && _cacheTime != null) {
        final age = DateTime.now().difference(_cacheTime!);
        if (age < _cacheValidityDuration) {
          return _cachedUsage;
        }
      }

      // Fetch from server
      final response = await _supabase
          .from('ai_usage')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100);

      if (response.isEmpty) {
        // User has no usage yet
        _cachedUsage = AiUsageSnapshot(
          currentPlan: AiPlan.free,
          requestsThisMinute: 0,
          requestsThisHour: 0,
          messagesThisDay: 0,
          concurrentRequests: 0,
          imageAnalysisThisDay: 0,
          documentAnalysisThisDay: 0,
          totalInputTokensThisDay: 0,
          totalOutputTokensThisDay: 0,
          lastResetTime: DateTime.now().toUtc(),
        );
        _cacheTime = DateTime.now();
        return _cachedUsage;
      }

      // Calculate current usage from recent records
      final now = DateTime.now().toUtc();
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final todayStart = DateTime.utc(now.year, now.month, now.day);

      int requestsThisMinute = 0;
      int requestsThisHour = 0;
      int messagesThisDay = 0;
      int totalInputTokens = 0;
      int totalOutputTokens = 0;
      int imageAnalysis = 0;
      int documentAnalysis = 0;
      int concurrentRequests = 0;

      for (final record in response) {
        final createdAt = DateTime.parse(record['created_at'] as String);
        final success = record['success'] as bool? ?? true;
        
        // Only count successful requests
        if (!success) continue;
        
        if (createdAt.isAfter(oneMinuteAgo)) {
          requestsThisMinute++;
        }
        if (createdAt.isAfter(oneHourAgo)) {
          requestsThisHour++;
        }
        if (createdAt.isAfter(todayStart)) {
          messagesThisDay++;
          totalInputTokens += (record['input_tokens'] as int?) ?? 0;
          totalOutputTokens += (record['output_tokens'] as int?) ?? 0;
          
          final requestType = record['request_type'] as String?;
          if (requestType == 'image_analysis') {
            imageAnalysis++;
          } else if (requestType == 'document_analysis') {
            documentAnalysis++;
          }
        }
      }
      
      // Note: Concurrent requests tracking would require checking request status
      // For now, we set it to 0 as it's not tracked client-side
      // The server enforces concurrent limits in the Edge Function

      // Get user's plan from profile
      final profileResponse = await _supabase
          .from('user_profiles')
          .select('subscription_tier')
          .eq('id', user.id)
          .single();

      final planString = profileResponse['subscription_tier'] as String? ?? 'free';
      final plan = AiPlans.fromString(planString).plan;

      _cachedUsage = AiUsageSnapshot(
        currentPlan: plan,
        requestsThisMinute: requestsThisMinute,
        requestsThisHour: requestsThisHour,
        messagesThisDay: messagesThisDay,
        concurrentRequests: concurrentRequests,
        imageAnalysisThisDay: imageAnalysis,
        documentAnalysisThisDay: documentAnalysis,
        totalInputTokensThisDay: totalInputTokens,
        totalOutputTokensThisDay: totalOutputTokens,
        lastResetTime: todayStart,
      );
      _cacheTime = DateTime.now();

      DebugLogger.info('AiUsageService', 
        'Usage: ${messagesThisDay} messages, ${totalInputTokens} input tokens, plan: $planString');

      return _cachedUsage;
    } catch (e, st) {
      DebugLogger.error('AiUsageService', 'Failed to get usage: $e', e, st);
      // Return default free plan usage instead of null
      // This prevents "Unable to load usage info" error
      return AiUsageSnapshot(
        currentPlan: AiPlan.free,
        requestsThisMinute: 0,
        requestsThisHour: 0,
        messagesThisDay: 0,
        concurrentRequests: 0,
        imageAnalysisThisDay: 0,
        documentAnalysisThisDay: 0,
        totalInputTokensThisDay: 0,
        totalOutputTokensThisDay: 0,
        lastResetTime: DateTime.now().toUtc(),
      );
    }
  }

  /// Invalidate the usage cache (call after making a request)
  void invalidateCache() {
    _cachedUsage = null;
    _cacheTime = null;
  }

  /// Get cached usage without fetching (returns null if not cached)
  AiUsageSnapshot? getCachedUsage() {
    return _cachedUsage;
  }

  /// Check if user can make an AI request (client-side check for UX)
  /// 
  /// NOTE: Server-side enforcement in Edge Function is mandatory.
  /// This is for UI feedback only.
  Future<bool> canMakeRequest() async {
    final usage = await getCurrentUsage();
    return usage?.canMakeRequest() ?? false;
  }

  /// Get reason why user cannot make a request (if applicable)
  Future<String?> getBlockReason() async {
    final usage = await getCurrentUsage();
    return usage?.getBlockReason();
  }

  /// Get context usage percentage (0-100)
  Future<double> getContextUsagePercent() async {
    final usage = await getCurrentUsage();
    return usage?.contextUsagePercent ?? 0;
  }

  /// Check if context is getting full
  Future<bool> isContextWarning() async {
    final usage = await getCurrentUsage();
    return usage?.isContextWarning ?? false;
  }

  /// Get context warning message
  Future<String?> getContextWarning() async {
    final usage = await getCurrentUsage();
    return usage?.getContextWarning();
  }
}
