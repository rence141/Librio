import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../utils/markdown_normalizer.dart';

/// LLM-tolerant Markdown renderer.
///
/// Pipeline: LLM output → normalize → parse → render
///
/// Wraps [MarkdownBody] with a normalization layer that repairs common
/// malformed Markdown from small local models (Gemma 3 1B).
class LlmMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;

  const LlmMarkdown({
    super.key,
    required this.data,
    this.selectable = true,
    this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = MarkdownNormalizer.normalize(data);
    return MarkdownBody(
      data: normalized,
      selectable: selectable,
      styleSheet: styleSheet,
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
  }
}
