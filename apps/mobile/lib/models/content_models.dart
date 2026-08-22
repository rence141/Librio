/// Content models for Librio app

/// Represents a content pack (subject area)
class ContentPack {
  final String id;
  final String name;
  final String subject; // Alias for name
  final String description;
  final List<ContentTopic> topics;

  ContentPack({
    required this.id,
    required this.name,
    required this.description,
    required this.topics,
  }) : subject = name;

  factory ContentPack.fromJson(Map<String, dynamic> json) {
    return ContentPack(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      topics: (json['topics'] as List?)
              ?.map((t) => ContentTopic.fromJson(t))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'topics': topics.map((t) => t.toJson()).toList(),
    };
  }
}

/// Represents a topic within a content pack
class ContentTopic {
  final String id;
  final String title;
  final String name; // Alias for title
  final String description;
  final List<PracticeProblem> problems;
  final int difficulty;

  ContentTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.problems,
    this.difficulty = 1,
  }) : name = title;

  factory ContentTopic.fromJson(Map<String, dynamic> json) {
    return ContentTopic(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      problems: (json['problems'] as List?)
              ?.map((p) => PracticeProblem.fromJson(p))
              .toList() ??
          [],
      difficulty: json['difficulty'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'problems': problems.map((p) => p.toJson()).toList(),
      'difficulty': difficulty,
    };
  }
}

/// Represents a practice problem
class PracticeProblem {
  final String id;
  final String question;
  final String answer;
  final List<String> hints;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final int difficulty;

  PracticeProblem({
    required this.id,
    required this.question,
    required this.answer,
    required this.hints,
    required this.explanation,
    List<String>? options,
    int? correctAnswerIndex,
    this.difficulty = 1,
  })  : options = options ?? [answer],
        correctAnswerIndex = correctAnswerIndex ?? 0;

  factory PracticeProblem.fromJson(Map<String, dynamic> json) {
    return PracticeProblem(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      hints: List<String>.from(json['hints'] ?? []),
      explanation: json['explanation'] ?? '',
      difficulty: json['difficulty'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'hints': hints,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }
}

/// Sample content packs for testing
class ContentPacks {
  static final mathematicsPack = ContentPack(
    id: 'math',
    name: 'Mathematics',
    description: 'Learn mathematics fundamentals',
    topics: [
      ContentTopic(
        id: 'algebra',
        title: 'Algebra',
        description: 'Basic algebra concepts',
        problems: [
          PracticeProblem(
            id: 'prob1',
            question: 'What is 2 + 2?',
            answer: '4',
            hints: ['Count on your fingers', 'Think of 2 apples + 2 apples'],
            explanation: 'When you add 2 and 2, you get 4',
            difficulty: 1,
          ),
        ],
      ),
    ],
  );

  static final sciencePack = ContentPack(
    id: 'science',
    name: 'Science',
    description: 'Explore science topics',
    topics: [
      ContentTopic(
        id: 'physics',
        title: 'Physics',
        description: 'Physics fundamentals',
        problems: [
          PracticeProblem(
            id: 'prob2',
            question: 'What is the speed of light?',
            answer: '299,792,458 m/s',
            hints: ['It\'s approximately 300,000 km/s', 'It\'s denoted by c'],
            explanation: 'The speed of light is a fundamental constant',
            difficulty: 2,
          ),
        ],
      ),
    ],
  );

  static List<ContentPack> getAllPacks() {
    return [mathematicsPack, sciencePack];
  }
}
