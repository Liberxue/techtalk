/// Abstract LLM interface (Strategy pattern).
///
/// Implementations can be swapped at runtime — e.g. [MockLlmService] for
/// offline use, [ClaudeLlmService] when an API key is configured.
abstract class LlmService {
  /// Generate interview feedback based on user's answer.
  Future<InterviewFeedback> generateFeedback({
    required String question,
    required String userAnswer,
    required List<String> keyPhrases,
    required String idealAnswer,
    List<CommonFix> commonFixes = const [],
  });

  /// Generate a follow-up interview question.
  Future<String> generateFollowUp({
    required String scenario,
    required String previousAnswer,
  });

  /// Generate pronunciation tips for a word.
  Future<String> getPronunciationTip(String word);

  /// Summarize / split content into practice-ready sentences.
  Future<List<String>> summarizeContent(String rawText);

  /// Whether this service requires an API key to function.
  bool get requiresApiKey;
}

/// Structured feedback returned by [LlmService.generateFeedback].
class InterviewFeedback {
  final int score;
  final String correct;
  final String? improve;
  final String? nativeAlt;

  const InterviewFeedback({
    required this.score,
    required this.correct,
    this.improve,
    this.nativeAlt,
  });
}

/// A common grammar / phrasing fix used during feedback generation.
class CommonFix {
  final String wrong;
  final String correct;

  const CommonFix({required this.wrong, required this.correct});
}
