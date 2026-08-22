import 'package:flutter/foundation.dart';

/// Content topic
class ContentTopic {
  final String id;
  final String title;
  final String description;
  final String subject;
  final int difficulty; // 1-5
  final List<String> concepts;
  final List<String> keywords;
  final DateTime createdAt;

  ContentTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.difficulty,
    required this.concepts,
    required this.keywords,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'subject': subject,
    'difficulty': difficulty,
    'concepts': concepts,
    'keywords': keywords,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Practice problem
class PracticeProblem {
  final String id;
  final String topicId;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final int difficulty; // 1-5
  final DateTime createdAt;

  PracticeProblem({
    required this.id,
    required this.topicId,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.difficulty,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'topicId': topicId,
    'question': question,
    'options': options,
    'correctAnswerIndex': correctAnswerIndex,
    'explanation': explanation,
    'difficulty': difficulty,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Subject pack
class SubjectPack {
  final String id;
  final String title;
  final String subject;
  final String description;
  final List<ContentTopic> topics;
  final List<PracticeProblem> problems;
  final int totalTopics;
  final int totalProblems;
  final DateTime createdAt;

  SubjectPack({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.topics,
    required this.problems,
    required this.totalTopics,
    required this.totalProblems,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'description': description,
    'topics': topics.map((t) => t.toJson()).toList(),
    'problems': problems.map((p) => p.toJson()).toList(),
    'totalTopics': totalTopics,
    'totalProblems': totalProblems,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Content manager
class ContentManager {
  static final ContentManager _instance = ContentManager._internal();

  factory ContentManager() {
    return _instance;
  }

  ContentManager._internal();

  final Map<String, SubjectPack> _packs = {};
  final Map<String, ContentTopic> _topics = {};
  final Map<String, PracticeProblem> _problems = {};

  /// Initialize content manager
  void initialize() {
    if (kDebugMode) {
      print('📚 Content manager initialized');
    }
  }

  /// Add subject pack
  void addSubjectPack(SubjectPack pack) {
    _packs[pack.id] = pack;

    for (final topic in pack.topics) {
      _topics[topic.id] = topic;
    }

    for (final problem in pack.problems) {
      _problems[problem.id] = problem;
    }

    if (kDebugMode) {
      print('📚 Subject pack added: ${pack.title}');
    }
  }

  /// Get subject pack
  SubjectPack? getSubjectPack(String packId) {
    return _packs[packId];
  }

  /// Get all subject packs
  List<SubjectPack> getAllSubjectPacks() {
    return List.unmodifiable(_packs.values);
  }

  /// Get subject packs by subject
  List<SubjectPack> getSubjectPacksBySubject(String subject) {
    return _packs.values
        .where((pack) => pack.subject == subject)
        .toList();
  }

  /// Get topic
  ContentTopic? getTopic(String topicId) {
    return _topics[topicId];
  }

  /// Get topics by subject
  List<ContentTopic> getTopicsBySubject(String subject) {
    return _topics.values
        .where((topic) => topic.subject == subject)
        .toList();
  }

  /// Get problem
  PracticeProblem? getProblem(String problemId) {
    return _problems[problemId];
  }

  /// Get problems by topic
  List<PracticeProblem> getProblemsByTopic(String topicId) {
    return _problems.values
        .where((problem) => problem.topicId == topicId)
        .toList();
  }

  /// Get problems by difficulty
  List<PracticeProblem> getProblemsByDifficulty(int difficulty) {
    return _problems.values
        .where((problem) => problem.difficulty == difficulty)
        .toList();
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalPacks': _packs.length,
      'totalTopics': _topics.length,
      'totalProblems': _problems.length,
      'subjects': _packs.values.map((p) => p.subject).toSet().toList(),
    };
  }

  /// Search content
  List<ContentTopic> searchTopics(String query) {
    final lowerQuery = query.toLowerCase();
    return _topics.values
        .where((topic) =>
            topic.title.toLowerCase().contains(lowerQuery) ||
            topic.description.toLowerCase().contains(lowerQuery) ||
            topic.keywords.any((k) => k.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  /// Get featured content
  List<ContentTopic> getFeaturedContent(int limit) {
    return _topics.values
        .toList()
        .sublist(0, (limit).clamp(0, _topics.length));
  }

  /// Clear all content
  void clearContent() {
    _packs.clear();
    _topics.clear();
    _problems.clear();

    if (kDebugMode) {
      print('🧹 Content cleared');
    }
  }
}
