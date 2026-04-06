import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm_service.dart';
import 'mock_llm_service.dart';

/// Claude API implementation of [LlmService].
///
/// Falls back to [MockLlmService] when the API response cannot be parsed.
class ClaudeLlmService implements LlmService {
  final String apiKey;
  final String model;

  /// Fallback used when parsing fails.
  final MockLlmService _fallback = MockLlmService();

  ClaudeLlmService({
    required this.apiKey,
    this.model = 'claude-sonnet-4-20250514',
  });

  @override
  bool get requiresApiKey => true;

  // ---------------------------------------------------------------------------
  // Internal: call the Claude Messages API
  // ---------------------------------------------------------------------------
  Future<String> _chat(String systemPrompt, String userMessage) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 1024,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Claude API error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = body['content'] as List<dynamic>;
    return (content.first as Map<String, dynamic>)['text'] as String;
  }

  /// Try to extract the first JSON object or array from [text].
  dynamic _extractJson(String text) {
    // Try the whole string first.
    try {
      return jsonDecode(text);
    } catch (_) {}

    // Look for { ... } or [ ... ] substrings.
    final objMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (objMatch != null) {
      try {
        return jsonDecode(objMatch.group(0)!);
      } catch (_) {}
    }
    final arrMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
    if (arrMatch != null) {
      try {
        return jsonDecode(arrMatch.group(0)!);
      } catch (_) {}
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // generateFeedback
  // ---------------------------------------------------------------------------
  @override
  Future<InterviewFeedback> generateFeedback({
    required String question,
    required String userAnswer,
    required List<String> keyPhrases,
    required String idealAnswer,
    List<CommonFix> commonFixes = const [],
  }) async {
    try {
      const systemPrompt =
          'You are an English pronunciation and interview coach. '
          'Evaluate the user\'s answer to the interview question. '
          'Return ONLY valid JSON with this shape: '
          '{"score": int 0-100, "correct": string, "improve": string|null, "nativeAlt": string|null}';

      final userMessage =
          'Question: $question\n\nUser answer: $userAnswer\n\n'
          'Key phrases expected: ${keyPhrases.join(", ")}\n\n'
          'Ideal answer: $idealAnswer';

      final raw = await _chat(systemPrompt, userMessage);
      final json = _extractJson(raw);

      if (json is Map<String, dynamic>) {
        return InterviewFeedback(
          score: (json['score'] as num).toInt().clamp(0, 100),
          correct: json['correct'] as String? ?? 'good answer',
          improve: json['improve'] as String?,
          nativeAlt: json['nativeAlt'] as String?,
        );
      }
    } catch (_) {
      // Fall through to mock.
    }

    return _fallback.generateFeedback(
      question: question,
      userAnswer: userAnswer,
      keyPhrases: keyPhrases,
      idealAnswer: idealAnswer,
      commonFixes: commonFixes,
    );
  }

  // ---------------------------------------------------------------------------
  // generateFollowUp
  // ---------------------------------------------------------------------------
  @override
  Future<String> generateFollowUp({
    required String scenario,
    required String previousAnswer,
  }) async {
    try {
      const systemPrompt =
          'You are a technical interviewer. Based on the candidate\'s answer, '
          'ask a natural follow-up question. Return only the question text.';

      final userMessage =
          'Scenario: $scenario\n\nCandidate\'s answer: $previousAnswer';

      return await _chat(systemPrompt, userMessage);
    } catch (_) {
      return _fallback.generateFollowUp(
        scenario: scenario,
        previousAnswer: previousAnswer,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // getPronunciationTip
  // ---------------------------------------------------------------------------
  @override
  Future<String> getPronunciationTip(String word) async {
    try {
      const systemPrompt =
          'Provide the IPA pronunciation and a brief tip for the given word. '
          'Keep the response to one or two sentences.';

      return await _chat(systemPrompt, word);
    } catch (_) {
      return _fallback.getPronunciationTip(word);
    }
  }

  // ---------------------------------------------------------------------------
  // summarizeContent
  // ---------------------------------------------------------------------------
  @override
  Future<List<String>> summarizeContent(String rawText) async {
    try {
      const systemPrompt =
          'Split this text into clear, standalone sentences suitable for '
          'read-aloud practice. Return ONLY a JSON array of strings.';

      final raw = await _chat(systemPrompt, rawText);
      final json = _extractJson(raw);

      if (json is List) {
        return json.cast<String>();
      }
    } catch (_) {
      // Fall through to mock.
    }

    return _fallback.summarizeContent(rawText);
  }
}
