import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/debug_logger.dart';
import 'online_model_config.dart';

/// Online LLM service using Google Gemini API.
///
/// Provides cloud-based AI responses when the user selects an online model.
/// Falls back gracefully on network errors.
class OnlineLlmService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  static const String _systemPrompt = '''You are Librio, a helpful study tutor. Follow these rules strictly:

1. ACCURACY: Only state facts you are confident about. Do not guess or fabricate information.
2. HONESTY: If you don't know the answer or are unsure, say "I'm not sure about that" or "I don't have enough information to answer that accurately." Never make up answers.
3. CLARITY: Give clear, concise answers. Use simple language.
4. SCOPE: You are a study tutor. Stay on topic with academic subjects. If asked about non-academic topics, briefly answer and redirect to studying.
5. SOURCES: When using provided study materials, base your answer on those materials. If the materials don't contain the answer, say so.
6. NO HALLUCINATION: Do not invent quotes, citations, dates, names, formulas, or facts. If you are not certain, say you are uncertain.
7. CORRECTION: If you realize you made an error, correct it immediately.

Remember: It is better to admit you don't know than to give a wrong answer.''';

  /// Generate a response from Gemini (non-streaming).
  Future<String> generateResponse(
    String prompt, {
    String model = 'gemini-2.0-flash',
  }) async {
    const tag = 'OnlineLlm';

    if (!OnlineModelConfig.hasGeminiKey) {
      return 'Online model not configured. Add your Gemini API key in online_model_config.dart';
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/models/$model:generateContent?key=${OnlineModelConfig.geminiApiKey}',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': _systemPrompt}
            ]
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topP': 0.85,
            'topK': 20,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode != 200) {
        DebugLogger.error(tag, 'Gemini API error: ${response.statusCode}',
            Exception(response.body), null);
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error']?['message'] ?? 'Unknown error';
        return 'Error: $errorMsg';
      }

      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return 'No response from Gemini.';
      }

      final content = candidates[0]['content']['parts'] as List;
      final text = content.map((p) => p['text'] ?? '').join('');
      DebugLogger.success(tag, 'Gemini response: ${text.length} chars');
      return text;
    } catch (e, st) {
      DebugLogger.error(tag, 'Gemini request failed', e, st);
      return 'Error connecting to Gemini: $e';
    }
  }

  /// Stream response from Gemini (token by token via SSE).
  Stream<String> streamResponse(
    String prompt, {
    String model = 'gemini-2.0-flash',
  }) async* {
    const tag = 'OnlineLlm';

    if (!OnlineModelConfig.hasGeminiKey) {
      yield 'Online model not configured. Add your Gemini API key in online_model_config.dart';
      return;
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/models/$model:streamGenerateContent?alt=sse&key=${OnlineModelConfig.geminiApiKey}',
      );

      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': _systemPrompt}
          ]
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topP': 0.85,
          'topK': 20,
          'maxOutputTokens': 1024,
        },
      });

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        DebugLogger.error(tag, 'Gemini stream error: ${response.statusCode}',
            Exception(body), null);
        yield 'Error: ${response.statusCode}';
        client.close();
        return;
      }

      DebugLogger.info(tag, 'Streaming from Gemini...');

      await for (final chunk in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (chunk.startsWith('data: ')) {
          final jsonStr = chunk.substring(6);
          if (jsonStr.trim() == '[DONE]') break;
          try {
            final data = jsonDecode(jsonStr);
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'];
              if (content != null) {
                final parts = content['parts'] as List?;
                if (parts != null) {
                  for (final part in parts) {
                    final text = part['text'];
                    if (text != null && text.isNotEmpty) {
                      yield text;
                    }
                  }
                }
              }
            }
          } catch (_) {
            // Skip malformed chunks
          }
        }
      }

      client.close();
      DebugLogger.success(tag, 'Gemini stream complete');
    } catch (e, st) {
      DebugLogger.error(tag, 'Gemini stream failed', e, st);
      yield 'Error connecting to Gemini: $e';
    }
  }
}
