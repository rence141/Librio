/// Flashcard model for spaced repetition review
enum FlashcardType { multipleChoice, enumeration, identification }

class Flashcard {
  final String id;
  final String question;
  final String answer;
  final List<String> options; // for multiple choice
  final int correctOptionIndex; // for multiple choice
  final FlashcardType type;
  final String deck;
  final DateTime createdAt;
  final DateTime updatedAt;
  int reviewCount;
  int correctCount;
  DateTime? lastReviewed;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.options = const [],
    this.correctOptionIndex = 0,
    required this.type,
    this.deck = 'Default',
    required this.createdAt,
    required this.updatedAt,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.lastReviewed,
  });

  factory Flashcard.multipleChoice({
    required String id,
    required String question,
    required List<String> options,
    required int correctOptionIndex,
    String deck = 'Default',
  }) {
    return Flashcard(
      id: id,
      question: question,
      answer: options.isNotEmpty ? options[correctOptionIndex] : '',
      options: options,
      correctOptionIndex: correctOptionIndex,
      type: FlashcardType.multipleChoice,
      deck: deck,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Flashcard.identification({
    required String id,
    required String question,
    required String answer,
    String deck = 'Default',
  }) {
    return Flashcard(
      id: id,
      question: question,
      answer: answer,
      type: FlashcardType.identification,
      deck: deck,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Flashcard.enumeration({
    required String id,
    required String question,
    required String answer,
    String deck = 'Default',
  }) {
    return Flashcard(
      id: id,
      question: question,
      answer: answer,
      type: FlashcardType.enumeration,
      deck: deck,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'options': options.join('|||'),
      'correct_option_index': correctOptionIndex,
      'type': type.name,
      'deck': deck,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'review_count': reviewCount,
      'correct_count': correctCount,
      'last_reviewed': lastReviewed?.toIso8601String(),
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      options: (json['options'] as String? ?? '').split('|||').where((s) => s.isNotEmpty).toList(),
      correctOptionIndex: json['correct_option_index'] as int? ?? 0,
      type: FlashcardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FlashcardType.identification,
      ),
      deck: json['deck'] as String? ?? 'Default',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      reviewCount: json['review_count'] as int? ?? 0,
      correctCount: json['correct_count'] as int? ?? 0,
      lastReviewed: json['last_reviewed'] != null
          ? DateTime.parse(json['last_reviewed'] as String)
          : null,
    );
  }
}
