import 'package:flutter/foundation.dart';

/// Problem attempt record
class ProblemAttempt {
  final String problemId;
  final bool correct;
  final int timeSpent; // in seconds
  final DateTime attemptedAt;
  
  ProblemAttempt({
    required this.problemId,
    required this.correct,
    required this.timeSpent,
    required this.attemptedAt,
  });
  
  Map<String, dynamic> toJson() => {
    'problemId': problemId,
    'correct': correct,
    'timeSpent': timeSpent,
    'attemptedAt': attemptedAt.toIso8601String(),
  };
}

/// Topic progress
class TopicProgress {
  final String topicId;
  final String topicName;
  final int totalProblems;
  final int solvedProblems;
  final int correctProblems;
  final DateTime lastAttemptedAt;
  
  TopicProgress({
    required this.topicId,
    required this.topicName,
    required this.totalProblems,
    required this.solvedProblems,
    required this.correctProblems,
    required this.lastAttemptedAt,
  });
  
  double get progressPercentage => (solvedProblems / totalProblems) * 100;
  double get accuracyPercentage => solvedProblems > 0 ? (correctProblems / solvedProblems) * 100 : 0;
  
  Map<String, dynamic> toJson() => {
    'topicId': topicId,
    'topicName': topicName,
    'totalProblems': totalProblems,
    'solvedProblems': solvedProblems,
    'correctProblems': correctProblems,
    'lastAttemptedAt': lastAttemptedAt.toIso8601String(),
    'progressPercentage': progressPercentage,
    'accuracyPercentage': accuracyPercentage,
  };
}

/// Subject progress
class SubjectProgress {
  final String subject;
  final List<TopicProgress> topics;
  
  SubjectProgress({
    required this.subject,
    required this.topics,
  });
  
  int get totalProblems => topics.fold(0, (sum, t) => sum + t.totalProblems);
  int get solvedProblems => topics.fold(0, (sum, t) => sum + t.solvedProblems);
  int get correctProblems => topics.fold(0, (sum, t) => sum + t.correctProblems);
  
  double get progressPercentage => totalProblems > 0 ? (solvedProblems / totalProblems) * 100 : 0;
  double get accuracyPercentage => solvedProblems > 0 ? (correctProblems / solvedProblems) * 100 : 0;
  
  Map<String, dynamic> toJson() => {
    'subject': subject,
    'topics': topics.map((t) => t.toJson()).toList(),
    'totalProblems': totalProblems,
    'solvedProblems': solvedProblems,
    'correctProblems': correctProblems,
    'progressPercentage': progressPercentage,
    'accuracyPercentage': accuracyPercentage,
  };
}

/// Progress tracker service
class ProgressTracker {
  static final ProgressTracker _instance = ProgressTracker._internal();
  
  factory ProgressTracker() {
    return _instance;
  }
  
  ProgressTracker._internal();
  
  final Map<String, ProblemAttempt> _attempts = {};
  final Map<String, TopicProgress> _topicProgress = {};
  
  /// Record a problem attempt
  Future<void> recordAttempt({
    required String problemId,
    required bool correct,
    required int timeSpent,
  }) async {
    _attempts[problemId] = ProblemAttempt(
      problemId: problemId,
      correct: correct,
      timeSpent: timeSpent,
      attemptedAt: DateTime.now(),
    );
    
    if (kDebugMode) {
      print('📊 Recorded attempt: $problemId (${correct ? "✅" : "❌"})');
    }
  }
  
  /// Get problem attempt
  ProblemAttempt? getAttempt(String problemId) {
    return _attempts[problemId];
  }
  
  /// Get all attempts
  List<ProblemAttempt> getAllAttempts() {
    return _attempts.values.toList();
  }
  
  /// Update topic progress
  void updateTopicProgress(TopicProgress progress) {
    _topicProgress[progress.topicId] = progress;
    
    if (kDebugMode) {
      print('📈 Updated topic progress: ${progress.topicName} (${progress.progressPercentage.toStringAsFixed(1)}%)');
    }
  }
  
  /// Get topic progress
  TopicProgress? getTopicProgress(String topicId) {
    return _topicProgress[topicId];
  }
  
  /// Get all topic progress
  List<TopicProgress> getAllTopicProgress() {
    return _topicProgress.values.toList();
  }
  
  /// Get subject progress
  SubjectProgress getSubjectProgress(String subject, List<TopicProgress> topics) {
    return SubjectProgress(
      subject: subject,
      topics: topics,
    );
  }
  
  /// Get overall statistics
  Map<String, dynamic> getOverallStats() {
    final allAttempts = _attempts.values.toList();
    final totalAttempts = allAttempts.length;
    final correctAttempts = allAttempts.where((a) => a.correct).length;
    final totalTimeSpent = allAttempts.fold(0, (sum, a) => sum + a.timeSpent);
    
    return {
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'accuracy': totalAttempts > 0 ? (correctAttempts / totalAttempts) * 100 : 0,
      'totalTimeSpent': totalTimeSpent,
      'averageTimePerProblem': totalAttempts > 0 ? totalTimeSpent ~/ totalAttempts : 0,
      'topicsStarted': _topicProgress.length,
    };
  }
  
  /// Clear all progress (for testing)
  void clearProgress() {
    _attempts.clear();
    _topicProgress.clear();
    
    if (kDebugMode) {
      print('🗑️ Progress cleared');
    }
  }
}
