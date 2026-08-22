import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/debug_logger.dart';
import 'online_model_config.dart';

/// Online LLM service using FreeLLMAPI (OpenAI-compatible endpoint).
///
/// Routes through a local proxy that aggregates 28+ free LLM providers
/// with automatic failover and rate-limit management.
class OnlineLlmService {
  static const String _systemPrompt = '''You are Librio, a helpful study tutor. Follow these rules strictly:

1. ACCURACY: Only state facts you are confident about. Do not guess or fabricate information.
2. HONESTY: If you don't know the answer or are unsure, say "I'm not sure about that" or "I don't have enough information to answer that accurately." Never make up answers.
3. CLARITY: Give clear, concise answers. Use simple language.
4. SCOPE: You are a study tutor. Stay on topic with academic subjects. If asked about non-academic topics, briefly answer and redirect to studying.
5. SOURCES: When using provided study materials, base your answer on those materials. If the materials don't contain the answer, say so.
6. NO HALLUCINATION: Do not invent quotes, citations, dates, names, formulas, or facts. If you are not certain, say you are uncertain.
7. CORRECTION: If you realize you made an error, correct it immediately.

Remember: It is better to admit you don't know than to give a wrong answer.''';

  /// Generate a response (non-streaming).
  Future<String> generateResponse(
    String prompt, {
    String model = 'gemini-2.0-flash',
  }) async {
    const tag = 'OnlineLlm';

    if (!OnlineModelConfig.hasKey) {
      return 'Online model not configured. Add your FreeLLMAPI key in online_model_config.dart';
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
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
          'top_p': 0.85,
          'max_tokens': 1024,
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
  Stream<String> streamResponse(
    String prompt, {
    String model = 'gemini-2.0-flash',
  }) async* {
    const tag = 'OnlineLlm';

    if (!OnlineModelConfig.hasKey) {
      yield 'Online model not configured. Add your FreeLLMAPI key in online_model_config.dart';
      return;
    }

    try {
      final url = Uri.parse('${OnlineModelConfig.baseUrl}/chat/completions');

      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer ${OnlineModelConfig.apiKey}';
      request.body = jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'top_p': 0.85,
        'max_tokens': 1024,
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
}
