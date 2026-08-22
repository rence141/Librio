import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/debug_logger.dart';
import 'online_model_config.dart';

/// Online LLM service using FreeLLMAPI (OpenAI-compatible endpoint).
///
/// Routes through a local proxy that aggregates 28+ free LLM providers
/// with automatic failover and rate-limit management.
/// Supports vision models for image understanding.
class OnlineLlmService {
  static const String _systemPrompt = '''
You are Librio, a helpful, intelligent study tutor.

Your job is to understand the user's actual input and respond to what they are asking or showing. Do not follow a generic greeting behavior when the user has provided meaningful content.

CORE RULES:

1. ACCURACY
- Only state information you are reasonably confident is correct.
- Never invent facts, names, dates, formulas, quotations, sources, or citations.
- If information is uncertain, clearly say so.

2. HONESTY
- If you do not know something, say:
  "I'm not sure about that."
- If there is insufficient information, say:
  "I don't have enough information to answer that accurately."
- Never fill gaps by guessing.

3. CLARITY
- Answer directly.
- Use simple, natural language.
- Avoid unnecessary introductions and repetition.
- Match the level of explanation to the user's question.

4. CONTEXT FIRST
- Always consider the user's latest message, attached files/images, and relevant conversation context before responding.
- Do not respond with a generic greeting when the user has already provided a question, image, document, text, or other meaningful input.

5. STUDY TUTOR ROLE
- Your primary purpose is helping with academic learning.
- You may briefly answer reasonable non-academic questions when useful, but naturally redirect toward studying when appropriate.
- Do not refuse a question merely because it is not explicitly academic.

6. PROVIDED MATERIALS
- When the user provides notes, documents, screenshots, images, or study materials, use them as context.
- Clearly distinguish between information found in the provided material and your own general knowledge.
- Never claim that something appears in the material if it does not.

IMAGE UNDERSTANDING — CRITICAL:

When an image is attached to the user's message, the image is part of the user's input and MUST be considered before generating the response.

Follow this process:

A. FIRST inspect and understand the image.
B. Identify relevant text, questions, UI elements, diagrams, charts, tables, documents, errors, or other visible information.
C. Determine whether the image itself contains something the user expects you to understand.
D. Combine the image with the user's accompanying text and conversation context.
E. Respond to the actual content instead of producing a generic greeting.

IMAGE RESPONSE RULES:

- Image upload does NOT mean the user wants a greeting.
- NEVER respond with:
  "Hello! I'm Librio, your study tutor..."
  or another generic introduction when an image contains meaningful content.
- If the image contains a question, answer it.
- If it contains homework, solve it or explain how to solve it.
- If it contains study material, explain or summarize it.
- If it contains a diagram, explain the diagram.
- If it contains a chart or table, interpret the relevant information.
- If it contains an error message, help diagnose the error.
- If it contains a screenshot of an application or website, analyze the visible UI/content when relevant.
- If it contains text, read and use that text as context.
- If the user asks what is shown in the image, describe what is actually visible.
- Do not invent details that cannot be seen.

IF IMAGE INTENT IS UNCLEAR:

Do not give a generic greeting.

Instead, briefly acknowledge what you can actually identify and ask a specific question.

Example:
"I can see a screenshot of a study conversation about strategic management. What would you like me to analyze or explain?"

IMPORTANT:
Do not ask this question if the user's accompanying message already tells you what they want.

RESPONSE PRIORITY:

When generating a response, prioritize information in this order:

1. The user's explicit request
2. Relevant information visible in uploaded images/files
3. Relevant conversation context
4. Reliable general knowledge
5. If none is sufficient, honestly state that you do not have enough information

GREETING RULE:

Only greet the user when a greeting is appropriate.

If the user uploads an image containing meaningful content, DO NOT greet first. Analyze the content and respond to it directly.

CORRECTION:
- If you discover that a previous response was incorrect, acknowledge the mistake and provide the corrected information.
- Do not defend or repeat an incorrect answer.

FINAL PRINCIPLE:

Understand first. Respond second.

Never let a generic assistant introduction override the user's actual input.
It is always better to say "I don't know" than to fabricate an answer.
''';

  /// Build the user message content — supports text + images (vision format).
  /// Images are sent as base64-encoded data URLs in the OpenAI vision format.
  List<Map<String, dynamic>> _buildUserContent(String prompt, List<String> imagePaths) {
    final content = <Map<String, dynamic>>[];

    // Add images first (vision models process them as part of the message)
    for (final path in imagePaths) {
      if (_isImagePath(path)) {
        try {
          final bytes = File(path).readAsBytesSync();
          final base64Str = base64Encode(bytes);
          final ext = path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
          content.add({
            'type': 'image_url',
            'image_url': {'url': 'data:image/$ext;base64,$base64Str'},
          });
        } catch (e) {
          DebugLogger.error('OnlineLlm', 'Failed to read image: $path', e, null);
        }
      } else {
        // Non-image file — include filename as text context
        final filename = path.split('/').last.split('\\').last;
        content.add({
          'type': 'text',
          'text': '[Attached file: $filename]',
        });
      }
    }

    // Add the text prompt (even if empty — images need context)
    final text = prompt.trim().isEmpty
        ? 'Please analyze the image(s) above and respond appropriately based on what you see.'
        : prompt;
    content.add({'type': 'text', 'text': text});

    return content;
  }

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  /// Generate a response (non-streaming).
  Future<String> generateResponse(
    String prompt, {
    String model = 'gemini-2.0-flash',
    List<String> imagePaths = const [],
  }) async {
    const tag = 'OnlineLlm';

    if (!OnlineModelConfig.hasKey) {
      return 'Online model not configured. Add your FreeLLMAPI key in online_model_config.dart';
    }

    try {
      final url = Uri.parse('${OnlineModelConfig.baseUrl}/chat/completions');

      final userContent = _buildUserContent(prompt, imagePaths);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${OnlineModelConfig.apiKey}',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': userContent},
          ],
          'temperature': 0.3,
          'top_p': 0.85,
          'max_tokens': 2048,
        }),
      );

      if (response.statusCode != 200) {
        DebugLogger.error(tag, 'API error: ${response.statusCode}',
            Exception(response.body), null);
        return 'Error: ${response.statusCode}';
      }

      final data = jsonDecode(response.body);
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        return 'No response from model.';
      }

      final text = choices[0]['message']['content'] ?? '';
      DebugLogger.success(tag, 'Response: ${text.length} chars');
      return text;
    } catch (e, st) {
      DebugLogger.error(tag, 'Request failed', e, st);
      return 'Error connecting to FreeLLMAPI: $e';
    }
  }

  /// Stream response (token by token via SSE).
  /// Supports image attachments via OpenAI vision format.
  Stream<String> streamResponse(
    String prompt, {
    String model = 'gemini-2.0-flash',
    List<String> imagePaths = const [],
  }) async* {
    const tag = 'OnlineLlm';

    if (!OnlineModelConfig.hasKey) {
      yield 'Online model not configured. Add your FreeLLMAPI key in online_model_config.dart';
      return;
    }

    try {
      final url = Uri.parse('${OnlineModelConfig.baseUrl}/chat/completions');

      final userContent = _buildUserContent(prompt, imagePaths);

      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer ${OnlineModelConfig.apiKey}';
      request.body = jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': userContent},
        ],
        'temperature': 0.3,
        'top_p': 0.85,
        'max_tokens': 2048,
        'stream': true,
      });

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        DebugLogger.error(tag, 'Stream error: ${response.statusCode}',
            Exception(body), null);
        yield 'Error: ${response.statusCode}';
        client.close();
        return;
      }

      DebugLogger.info(tag, 'Streaming from FreeLLMAPI...');

      await for (final chunk in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (chunk.startsWith('data: ')) {
          final jsonStr = chunk.substring(6);
          if (jsonStr.trim() == '[DONE]') break;
          try {
            final data = jsonDecode(jsonStr);
            final choices = data['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'];
              if (delta != null) {
                final text = delta['content'];
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              }
            }
          } catch (_) {
            // Skip malformed chunks
          }
        }
      }

      client.close();
      DebugLogger.success(tag, 'Stream complete');
    } catch (e, st) {
      DebugLogger.error(tag, 'Stream failed', e, st);
      yield 'Error connecting to FreeLLMAPI: $e';
    }
  }

  /// Generate a short conversation title from the first user message.
  /// Returns 3-7 words, no quotes.
  Future<String> generateTitle(String userMessage, {String model = 'gemini-3.6-flash'}) async {
    const tag = 'OnlineLlm';

    if (!OnlineModelConfig.hasKey) {
      return _fallbackTitle(userMessage);
    }

    try {
      final url = Uri.parse('${OnlineModelConfig.baseUrl}/chat/completions');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${OnlineModelConfig.apiKey}',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': 'Generate a concise conversation title from the user\'s message. Rules: 3-7 words max, describe the main topic, no quotes, no "Chat" or "Conversation", use Title Case. Return ONLY the title, nothing else.'
            },
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.3,
          'max_tokens': 30,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final title = (choices[0]['message']['content'] ?? '').trim();
          if (title.isNotEmpty) {
            // Clean up: remove quotes, limit length
            final cleaned = title.replaceAll('"', '').replaceAll("'", '').replaceAll('`', '').trim();
            DebugLogger.info(tag, 'Generated title: $cleaned');
            return cleaned;
          }
        }
      }
    } catch (e) {
      DebugLogger.error(tag, 'Title generation failed', e, null);
    }

    return _fallbackTitle(userMessage);
  }

  /// Fallback: derive a title from the first few words of the message
  String _fallbackTitle(String userMessage) {
    final words = userMessage.trim().split(RegExp(r'\s+'));
    if (words.length <= 7) return userMessage.trim();
    return words.take(7).join(' ');
  }
}
