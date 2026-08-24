/// AI usage plans and rate limits for Libro.
/// 
/// This is the single source of truth for all AI usage limits.
/// Server-side enforcement is mandatory; client-side checks are for UX only.

enum AiPlan {
  free,
  paid,
}

class AiPlanLimits {
  final AiPlan plan;
  
  // Rate limits (per time window)
  final int requestsPerMinute;
  final int requestsPerHour;
  final int messagesPerDay;
  
  // Token limits
  final int maxInputTokens;
  final int maxOutputTokens;
  
  // Concurrency
  final int maxConcurrentRequests;
  
  // Special features
  final int imageAnalysisPerDay;
  final int documentAnalysisPerDay;

  const AiPlanLimits({
    required this.plan,
    required this.requestsPerMinute,
    required this.requestsPerHour,
    required this.messagesPerDay,
    required this.maxInputTokens,
    required this.maxOutputTokens,
    required this.maxConcurrentRequests,
    required this.imageAnalysisPerDay,
    required this.documentAnalysisPerDay,
  });

  /// Get display name for the plan
  String get displayName => plan == AiPlan.free ? 'Free' : 'Paid';

  /// Get description of the plan
  String get description {
    if (plan == AiPlan.free) {
      return 'Free plan: $messagesPerDay messages/day, $requestsPerHour requests/hour';
    }
    return 'Paid plan: $messagesPerDay messages/day, $requestsPerHour requests/hour';
  }
}

/// Centralized AI plan configuration
class AiPlans {
  static const AiPlanLimits free = AiPlanLimits(
    plan: AiPlan.free,
    requestsPerMinute: 5,
    requestsPerHour: 30,
    messagesPerDay: 100,
    maxInputTokens: 16000,
    maxOutputTokens: 2000,
    maxConcurrentRequests: 1,
    imageAnalysisPerDay: 5,
    documentAnalysisPerDay: 3,
  );

  static const AiPlanLimits paid = AiPlanLimits(
    plan: AiPlan.paid,
    requestsPerMinute: 15,
    requestsPerHour: 100,
    messagesPerDay: 500,
    maxInputTokens: 32000,
    maxOutputTokens: 4000,
    maxConcurrentRequests: 3,
    imageAnalysisPerDay: 30,
    documentAnalysisPerDay: 20,
  );

  /// Get plan limits by plan type
  static AiPlanLimits get(AiPlan plan) {
    return plan == AiPlan.free ? free : paid;
  }

  /// Get plan limits by string (for API responses)
  static AiPlanLimits fromString(String planName) {
    return planName.toLowerCase() == 'paid' ? paid : free;
  }
}

/// Current usage snapshot for a user
class AiUsageSnapshot {
  final AiPlan currentPlan;
  final int requestsThisMinute;
  final int requestsThisHour;
  final int messagesThisDay;
  final int concurrentRequests;
  final int imageAnalysisThisDay;
  final int documentAnalysisThisDay;
  final int totalInputTokensThisDay;
  final int totalOutputTokensThisDay;
  final DateTime lastResetTime;

  const AiUsageSnapshot({
    required this.currentPlan,
    required this.requestsThisMinute,
    required this.requestsThisHour,
    required this.messagesThisDay,
    required this.concurrentRequests,
    required this.imageAnalysisThisDay,
    required this.documentAnalysisThisDay,
    required this.totalInputTokensThisDay,
    required this.totalOutputTokensThisDay,
    required this.lastResetTime,
  });

  /// Get the plan limits for this user
  AiPlanLimits get planLimits => AiPlans.get(currentPlan);

  /// Get context usage percentage (0-100)
  double get contextUsagePercent {
    final maxTokens = planLimits.maxInputTokens;
    if (maxTokens == 0) return 0;
    return ((totalInputTokensThisDay / maxTokens) * 100).clamp(0, 100);
  }

  /// Check if user can make another request
  bool canMakeRequest() {
    final limits = planLimits;
    
    // Check per-minute limit
    if (requestsThisMinute >= limits.requestsPerMinute) return false;
    
    // Check per-hour limit
    if (requestsThisHour >= limits.requestsPerHour) return false;
    
    // Check daily message limit
    if (messagesThisDay >= limits.messagesPerDay) return false;
    
    // Check concurrent request limit
    if (concurrentRequests >= limits.maxConcurrentRequests) return false;
    
    return true;
  }

  /// Get reason why user cannot make a request (if applicable)
  String? getBlockReason() {
    final limits = planLimits;
    
    if (requestsThisMinute >= limits.requestsPerMinute) {
      return 'You\'ve reached your AI limit for this minute.\nPlease wait a moment and try again.';
    }
    
    if (requestsThisHour >= limits.requestsPerHour) {
      return 'You\'ve reached your AI limit for this hour.\nPlease wait a moment and try again.';
    }
    
    if (messagesThisDay >= limits.messagesPerDay) {
      return 'You\'ve reached today\'s AI usage limit.\nYour limit will reset tomorrow.';
    }
    
    if (concurrentRequests >= limits.maxConcurrentRequests) {
      return 'You have too many AI requests running.\nPlease wait for one to finish.';
    }
    
    return null;
  }

  /// Check if context is getting full
  bool get isContextWarning => contextUsagePercent >= 75;
  bool get isContextCritical => contextUsagePercent >= 90;

  /// Get context warning message
  String? getContextWarning() {
    if (contextUsagePercent >= 90) {
      return 'Context is almost full (${contextUsagePercent.toStringAsFixed(0)}%).\nConsider starting a new chat.';
    }
    if (contextUsagePercent >= 75) {
      return 'Context usage is high (${contextUsagePercent.toStringAsFixed(0)}%).';
    }
    return null;
  }
}
