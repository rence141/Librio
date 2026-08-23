/// Context window tracker for managing token limits per conversation
class ContextWindow {
  // Default context limits per tier (tokens)
  static const int freeTierLimit = 10000;
  static const int premiumTierLimit = 50000;
  static const int enterpriseTierLimit = 200000;

  final String conversationId;
  int totalTokensUsed = 0;
  int maxTokens;
  final List<TokenUsageRecord> history = [];

  ContextWindow({
    required this.conversationId,
    this.maxTokens = freeTierLimit,
  });

  /// Add tokens from a response
  void addUsage(int inputTokens, int outputTokens) {
    final total = inputTokens + outputTokens;
    totalTokensUsed += total;
    history.add(TokenUsageRecord(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: total,
      timestamp: DateTime.now(),
    ));
  }

  /// Get remaining tokens
  int get remainingTokens => (maxTokens - totalTokensUsed).clamp(0, maxTokens);

  /// Check if context limit is exceeded
  bool get isLimitExceeded => totalTokensUsed >= maxTokens;

  /// Get usage percentage (0.0 to 1.0)
  double get usagePercentage => totalTokensUsed / maxTokens;

  /// Get human-readable status
  String get statusMessage {
    if (isLimitExceeded) {
      return 'Context limit exceeded. Start a new conversation.';
    }
    final percent = (usagePercentage * 100).toStringAsFixed(0);
    return '$percent% context used ($totalTokensUsed / $maxTokens tokens)';
  }

  /// Get warning level (0 = ok, 1 = warning, 2 = critical)
  int get warningLevel {
    if (isLimitExceeded) return 2;
    if (usagePercentage >= 0.8) return 1;
    return 0;
  }
}

/// Record of token usage in a single exchange
class TokenUsageRecord {
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final DateTime timestamp;

  TokenUsageRecord({
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.timestamp,
  });
}
