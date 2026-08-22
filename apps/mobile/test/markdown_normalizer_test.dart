import 'package:flutter_test/flutter_test.dart';
import 'package:librio/utils/markdown_normalizer.dart';

void main() {
  group('MarkdownNormalizer', () {
    test('preserves simple bold', () {
      expect(MarkdownNormalizer.normalize('**Bold**'), '**Bold**');
    });

    test('preserves simple italic', () {
      expect(MarkdownNormalizer.normalize('*Italic*'), '*Italic*');
    });

    test('preserves bold italic', () {
      expect(
        MarkdownNormalizer.normalize('***Bold italic***'),
        '***Bold italic***',
      );
    });

    test('preserves label bold', () {
      expect(
        MarkdownNormalizer.normalize(
          '**Front:** What are some of his key works?',
        ),
        '**Front:** What are some of his key works?',
      );
    });

    test('fixes nested list-item emphasis', () {
      const input = '* ***Front:** What are some of his key works?';
      const expected = '* **Front:** What are some of his key works?';
      expect(MarkdownNormalizer.normalize(input), expected);
    });

    test('fixes multiple nested list items', () {
      const input =
          '* ***Front:** What are some of his key works?\n* ***Back:** *Noli Me Tangere* and *El Filibusterismo*';
      final result = MarkdownNormalizer.normalize(input);
      expect(result, contains('**Front:**'));
      expect(result, contains('**Back:**'));
      expect(result, isNot(contains('***Front')));
      expect(result, isNot(contains('***Back')));
    });

    test('removes standalone four asterisks', () {
      expect(MarkdownNormalizer.normalize('text **** text'), 'text  text');
    });

    test('removes standalone three asterisks between words', () {
      expect(MarkdownNormalizer.normalize('text *** text'), 'text  text');
    });

    test('removes standalone two asterisks between words', () {
      expect(MarkdownNormalizer.normalize('text ** text'), 'text  text');
    });

    test('removes line of only asterisks', () {
      const input = 'Some text\n****\nMore text';
      final result = MarkdownNormalizer.normalize(input);
      expect(result, isNot(contains('****')));
    });

    test('preserves horizontal rule (---)', () {
      expect(MarkdownNormalizer.normalize('---'), '---');
    });

    test('preserves headings', () {
      expect(MarkdownNormalizer.normalize('# Heading'), '# Heading');
      expect(MarkdownNormalizer.normalize('## Subheading'), '## Subheading');
    });

    test('preserves bullet lists', () {
      const input = '- Item 1\n- Item 2';
      expect(MarkdownNormalizer.normalize(input), input);
    });

    test('preserves numbered lists', () {
      const input = '1. Item 1\n2. Item 2';
      expect(MarkdownNormalizer.normalize(input), input);
    });

    test('fixes mismatched triple-open double-close', () {
      expect(MarkdownNormalizer.normalize('***text**'), '**text**');
    });

    test('preserves italic inside bold in list', () {
      const input =
          '* **Back:** *Noli Me Tangere* and *El Filibusterismo*';
      final result = MarkdownNormalizer.normalize(input);
      expect(result, contains('**Back:**'));
      expect(result, contains('*Noli Me Tangere*'));
      expect(result, contains('*El Filibusterismo*'));
    });

    test('handles empty input', () {
      expect(MarkdownNormalizer.normalize(''), '');
    });

    test('handles plain text without markdown', () {
      expect(
        MarkdownNormalizer.normalize('Just plain text.'),
        'Just plain text.',
      );
    });

    test('removes orphaned trailing asterisks', () {
      expect(
        MarkdownNormalizer.normalize('Some text **'),
        'Some text',
      );
    });

    test('preserves code blocks', () {
      const input = '```\ncode here\n```';
      expect(MarkdownNormalizer.normalize(input), input);
    });

    test('preserves inline code', () {
      const input = 'Use `print()` function';
      expect(MarkdownNormalizer.normalize(input), input);
    });

    test('preserves links', () {
      const input = '[Google](https://google.com)';
      expect(MarkdownNormalizer.normalize(input), input);
    });
  });
}
