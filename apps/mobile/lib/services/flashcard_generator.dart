import '../models/flashcard.dart';

/// Parses AI-generated flashcard text into [Flashcard] objects.
///
/// The AI is prompted to output flashcards in this format:
///
/// ```text
/// FLASHCARD 1
/// Q: What is photosynthesis?
/// A: The process by which plants convert light energy into chemical energy.
///
/// FLASHCARD 2
/// Q: What are the four stages of mitosis?
/// A: Prophase, Metaphase, Anaphase, Telophase
/// ```
///
/// This parser is tolerant of minor formatting variations.
class FlashcardGenerator {
  /// Parse AI-generated flashcard text into Flashcard objects.
  static List<ParsedFlashcard> parse(String aiResponse) {
    final cards = <ParsedFlashcard>[];

    // Split by "FLASHCARD" markers (case-insensitive)
    final sections = RegExp(
      r'FLASHCARD\s*\d+',
      caseSensitive: false,
    ).allMatches(aiResponse);

    if (sections.isEmpty) {
      // Fallback: try Q:/A: pairs without FLASHCARD headers
      return _parseQAPairs(aiResponse);
    }

    final matchList = sections.toList();
    for (var i = 0; i < matchList.length; i++) {
      final start = matchList[i].end;
      final end = i + 1 < matchList.length ? matchList[i + 1].start : aiResponse.length;
      final block = aiResponse.substring(start, end).trim();

      final card = _parseBlock(block);
      if (card != null) cards.add(card);
    }

    return cards;
  }

  /// Parse a single flashcard block (text between FLASHCARD markers).
  static ParsedFlashcard? _parseBlock(String block) {
    String? question;
    String? answer;

    // Match Q: ... and A: ... patterns
    final qMatch = RegExp(
      r'(?:^|\n)\s*(?:Q|Question)[:.]\s*(.+?)(?=\n\s*(?:A|Answer)[:.]|\Z)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(block);

    final aMatch = RegExp(
      r'(?:^|\n)\s*(?:A|Answer)[:.]\s*(.+?)(?=\n\s*(?:Q|Question)[:.]|\Z)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(block);

    if (qMatch != null) {
      question = qMatch.group(1)?.trim();
    }
    if (aMatch != null) {
      answer = aMatch.group(1)?.trim();
    }

    // Also try **Front:** / **Back:** format (Gemma often uses this)
    if (question == null) {
      final frontMatch = RegExp(
        r'\*{0,3}Front:?\*{0,3}\s*(.+?)(?=\n|\*{0,3}Back)',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(block);
      if (frontMatch != null) question = frontMatch.group(1)?.trim();
    }
    if (answer == null) {
      final backMatch = RegExp(
        r'\*{0,3}Back:?\*{0,3}\s*(.+?)(?=\n|$)',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(block);
      if (backMatch != null) answer = backMatch.group(1)?.trim();
    }

    if (question == null || answer == null) return null;
    if (question.isEmpty || answer.isEmpty) return null;

    // Determine type: if answer contains commas/list markers, it's enumeration
    FlashcardType type = FlashcardType.identification;
    if (answer.contains(',') && answer.split(',').length >= 3) {
      type = FlashcardType.enumeration;
    }

    return ParsedFlashcard(
      question: question,
      answer: answer,
      type: type,
    );
  }

  /// Fallback: parse Q:/A: pairs without FLASHCARD headers.
  static List<ParsedFlashcard> _parseQAPairs(String text) {
    final cards = <ParsedFlashcard>[];
    final qaPattern = RegExp(
      r'(?:^|\n)\s*(?:Q|Question)[:.]\s*(.+?)\n\s*(?:A|Answer)[:.]\s*(.+?)(?=\n\s*(?:Q|Question)[:.]|\Z)',
      caseSensitive: false,
      dotAll: true,
    );

    for (final match in qaPattern.allMatches(text)) {
      final q = match.group(1)?.trim();
      final a = match.group(2)?.trim();
      if (q != null && a != null && q.isNotEmpty && a.isNotEmpty) {
        FlashcardType type = FlashcardType.identification;
        if (a.contains(',') && a.split(',').length >= 3) {
          type = FlashcardType.enumeration;
        }
        cards.add(ParsedFlashcard(question: q, answer: a, type: type));
      }
    }

    return cards;
  }

  /// Build the prompt to ask the AI to generate flashcards from content.
  static String buildPrompt(String content) {
    return '''Create 3-5 flashcards from the following content. Use this exact format:

FLASHCARD 1
Q: [question]
A: [answer]

FLASHCARD 2
Q: [question]
A: [answer]

Continue for each flashcard. Keep questions and answers concise.

Content to create flashcards from:
$content''';
  }
}

/// A parsed flashcard from AI output (not yet saved to database).
class ParsedFlashcard {
  final String question;
  final String answer;
  final FlashcardType type;

  ParsedFlashcard({
    required this.question,
    required this.answer,
    required this.type,
  });

  /// Convert to a Flashcard model ready to save.
  Flashcard toFlashcard({String deck = 'AI Generated'}) {
    final id = 'fc_${DateTime.now().millisecondsSinceEpoch}_${question.hashCode.abs()}';
    if (type == FlashcardType.identification) {
      return Flashcard.identification(
        id: id,
        question: question,
        answer: answer,
        deck: deck,
      );
    } else {
      return Flashcard.enumeration(
        id: id,
        question: question,
        answer: answer,
        deck: deck,
      );
    }
  }
}
