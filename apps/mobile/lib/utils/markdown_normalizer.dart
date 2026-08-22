/// Lightweight Markdown normalization for LLM-generated content.
///
/// Repairs common malformed Markdown patterns produced by small local models
/// (especially Gemma 3 1B) WITHOUT destroying legitimate formatting.
///
/// Pipeline: LLM output → normalize → parse → render
///
/// Rules:
/// 1. Remove empty emphasis runs: ****, ***, ** (standalone, not wrapping text)
/// 2. Fix nested list-item emphasis: "* ***Front:**" → "* **Front:**"
/// 3. Remove orphaned trailing asterisks at end of lines
/// 4. Fix mismatched triple-open/double-close: "***text**" → "**text**"
class MarkdownNormalizer {
  /// Normalize LLM-generated Markdown before passing to the parser.
  static String normalize(String input) {
    if (input.isEmpty) return input;

    var result = input;

    // 1. Remove standalone empty emphasis runs
    result = _removeEmptyEmphasis(result);

    // 2. Fix nested list-item emphasis
    result = _fixNestedListItemEmphasis(result);

    // 3. Fix mismatched triple-open/double-close (BEFORE trailing removal)
    result = _fixMismatchedTripleOpen(result);

    // 4. Remove orphaned trailing asterisks (AFTER mismatch fix)
    result = _removeTrailingOrphanAsterisks(result);

    return result;
  }

  /// Remove standalone empty emphasis runs.
  /// ****, ***, ** that are NOT wrapping any text.
  static String _removeEmptyEmphasis(String input) {
    // Remove lines that are only asterisks
    var result = input.replaceAllMapped(
      RegExp(r'^[\s]*\*{2,}[\s]*$', multiLine: true),
      (m) => '',
    );

    // Remove 4+ asterisks between words (never valid Markdown)
    result = result.replaceAllMapped(
      RegExp(r'(?<=\s|^)\*{4,}(?=\s|$)'),
      (m) => '',
    );

    // Remove standalone *** between words (not bold-italic, just orphaned)
    result = result.replaceAllMapped(
      RegExp(r'(?<=\s)\*{3}(?=\s)'),
      (m) => '',
    );

    // Remove standalone ** between words (not bold, just orphaned)
    result = result.replaceAllMapped(
      RegExp(r'(?<=\s)\*{2}(?=\s)'),
      (m) => '',
    );

    return result;
  }

  /// Fix nested list-item emphasis.
  /// "* ***Front:** text" → "* **Front:** text"
  static String _fixNestedListItemEmphasis(String input) {
    return input.replaceAllMapped(
      RegExp(
        r'(^|\n)(\s*[-*+]\s+)\*{3}(.+?)\*{2}(\s|:)',
        multiLine: true,
      ),
      (m) => '${m[1]}${m[2]}**${m[3]}**${m[4]}',
    );
  }

  /// Remove orphaned trailing asterisks at end of lines.
  /// Only removes if there is NO matching opener on the same line.
  static String _removeTrailingOrphanAsterisks(String input) {
    final lines = input.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = RegExp(r'(?<!\*)\*{2,3}\s*$').firstMatch(line);
      if (match != null) {
        // Count emphasis runs BEFORE the trailing one
        final beforeTrailing = line.substring(0, match.start);
        final runs = RegExp(r'\*{2,3}').allMatches(beforeTrailing);
        // If there are ZERO openers before, the trailing is orphaned
        // If there's 1 opener, the trailing is its closer (keep it)
        if (runs.isEmpty) {
          lines[i] = line.substring(0, match.start).trimRight();
        }
      }
    }
    return lines.join('\n');
  }

  /// Fix mismatched triple-open/double-close and vice versa.
  /// Only fixes when the counts DON'T match (e.g. ***text** or **text***).
  /// Preserves valid ***text*** (bold italic).
  static String _fixMismatchedTripleOpen(String input) {
    // ***text** → **text** (triple open, double close, no trailing *)
    // The (?!\*) ensures we don't match ***text*** (valid bold italic)
    var result = input.replaceAllMapped(
      RegExp(r'\*{3}([^\*]+(?:\*[^\*]+)*)\*{2}(?!\*)'),
      (m) => '**${m[1]}**',
    );
    // **text*** → **text** (double open, triple close)
    result = result.replaceAllMapped(
      RegExp(r'(?<!\*)\*{2}([^\*]+(?:\*[^\*]+)*)\*{3}'),
      (m) => '**${m[1]}**',
    );
    return result;
  }
}
