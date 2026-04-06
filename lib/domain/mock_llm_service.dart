import 'dart:math';

import '../services/word_matcher.dart';
import 'llm_service.dart';

/// IPA lookup for common tech / English words.
/// Mirrors the map in `lib/widgets/tappable_word.dart`.
const _ipaMap = <String, String>{
  'latency': '/ˈleɪ.tən.si/',
  'throughput': '/ˈθruː.pʊt/',
  'idempotent': '/ˌaɪ.dɛmˈpoʊ.tənt/',
  'consensus': '/kənˈsɛn.səs/',
  'distributed': '/dɪˈstrɪb.juː.tɪd/',
  'introduces': '/ˌɪn.trəˈdjuː.sɪz/',
  'breaking': '/ˈbreɪ.kɪŋ/',
  'change': '/tʃeɪndʒ/',
  'reduce': '/rɪˈdjuːs/',
  'sufficient': '/səˈfɪʃ.ənt/',
  'consider': '/kənˈsɪd.ər/',
  'operation': '/ˌɒp.əˈreɪ.ʃən/',
  'requires': '/rɪˈkwaɪərz/',
  'ownership': '/ˈoʊ.nɚ.ʃɪp/',
  'memory': '/ˈmɛm.ə.ri/',
  'compiler': '/kəmˈpaɪ.lər/',
  'garbage': '/ˈɡɑːr.bɪdʒ/',
  'reference': '/ˈrɛf.ər.əns/',
  'borrowing': '/ˈbɒr.oʊ.ɪŋ/',
  'variable': '/ˈvɛr.i.ə.bəl/',
  'function': '/ˈfʌŋk.ʃən/',
  'pointer': '/ˈpɔɪn.tər/',
  'mutable': '/ˈmjuː.tə.bəl/',
  'immutable': '/ɪˈmjuː.tə.bəl/',
  'algorithm': '/ˈæl.ɡə.rɪ.ðəm/',
  'database': '/ˈdeɪ.tə.beɪs/',
  'cache': '/kæʃ/',
  'binary': '/ˈbaɪ.nə.ri/',
  'optimization': '/ˌɒp.tɪ.maɪˈzeɪ.ʃən/',
  'architecture': '/ˈɑːr.kɪ.tɛk.tʃər/',
  'performance': '/pərˈfɔːr.məns/',
  'application': '/ˌæp.lɪˈkeɪ.ʃən/',
  'implementation': '/ˌɪm.plɪ.mɛnˈteɪ.ʃən/',
  'infrastructure': '/ˈɪn.frə.strʌk.tʃər/',
  'authentication': '/ɔːˌθɛn.tɪˈkeɪ.ʃən/',
  'the': '/ðə/',
  'this': '/ðɪs/',
  'that': '/ðæt/',
  'with': '/wɪð/',
  'have': '/hæv/',
  'from': '/frɒm/',
};

/// Offline mock implementation of [LlmService].
///
/// All methods run locally without network access, using the same heuristic
/// scoring logic that was originally embedded in `interview_screen.dart`.
class MockLlmService implements LlmService {
  @override
  bool get requiresApiKey => false;

  // ---------------------------------------------------------------------------
  // generateFeedback — ported from _InterviewScreenState._generateFeedback
  // ---------------------------------------------------------------------------
  @override
  Future<InterviewFeedback> generateFeedback({
    required String question,
    required String userAnswer,
    required List<String> keyPhrases,
    required String idealAnswer,
    List<CommonFix> commonFixes = const [],
  }) async {
    final answerLower = userAnswer.toLowerCase();
    final answerWords = answerLower.split(RegExp(r'\s+'));

    // --- Key-phrase matching ---
    int phrasesHit = 0;
    final hitPhrases = <String>[];
    for (final phrase in keyPhrases) {
      if (answerLower.contains(phrase.toLowerCase())) {
        phrasesHit++;
        hitPhrases.add(phrase);
      }
    }

    // --- Score ---
    final lengthBonus = (answerWords.length / 30).clamp(0.0, 0.2);
    final phraseRatio =
        keyPhrases.isEmpty ? 0.5 : phrasesHit / keyPhrases.length;
    final rawScore = (phraseRatio * 0.7 + lengthBonus + 0.15) * 100;
    final score = rawScore.round().clamp(30, 98);

    // --- Grammar / pronunciation fix ---
    String? grammarFix;
    for (final fix in commonFixes) {
      if (answerLower.contains(fix.wrong.toLowerCase())) {
        grammarFix = "'${fix.wrong}' → '${fix.correct}'";
        break;
      }
    }

    String? pronFix;
    final idealWords = idealAnswer.toLowerCase().split(RegExp(r'\s+'));
    for (final aw in answerWords) {
      if (aw.length < 4) continue;
      for (final iw in idealWords) {
        if (iw.length < 4) continue;
        final sim = WordMatcher.similarity(aw, iw);
        if (sim > 0.6 && sim < 0.85) {
          pronFix = "check pronunciation of '$iw'";
          break;
        }
      }
      if (pronFix != null) break;
    }

    // --- "Correct" summary ---
    String correct;
    if (hitPhrases.length >= 3) {
      correct = 'covered key concepts: ${hitPhrases.take(3).join(", ")}';
    } else if (hitPhrases.isNotEmpty) {
      correct = 'mentioned ${hitPhrases.first}';
    } else if (answerWords.length > 15) {
      correct = 'detailed explanation with good structure';
    } else {
      correct = 'concise answer';
    }

    // --- "Improve" suggestion ---
    String? improve = grammarFix ?? pronFix;
    final missedPhrases = keyPhrases
        .where((p) => !answerLower.contains(p.toLowerCase()))
        .take(2)
        .toList();
    improve ??= missedPhrases.isNotEmpty
        ? 'try mentioning: ${missedPhrases.join(", ")}'
        : null;

    // --- Native alternative ---
    String? nativeAlt;
    for (final fix in commonFixes) {
      if (!answerLower.contains(fix.wrong.toLowerCase())) {
        nativeAlt = "native phrasing: '${fix.correct}'";
        break;
      }
    }
    nativeAlt ??=
        "compare: '${idealAnswer.substring(0, min(60, idealAnswer.length))}...'";

    return InterviewFeedback(
      score: score,
      correct: correct,
      improve: improve,
      nativeAlt: nativeAlt,
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
    return 'Can you elaborate on that?';
  }

  // ---------------------------------------------------------------------------
  // getPronunciationTip
  // ---------------------------------------------------------------------------
  @override
  Future<String> getPronunciationTip(String word) async {
    final clean = word.toLowerCase().trim();
    final ipa = _ipaMap[clean];
    if (ipa != null) {
      return '$clean  $ipa';
    }
    return '$clean — no IPA data available. Try listening to the word.';
  }

  // ---------------------------------------------------------------------------
  // summarizeContent
  // ---------------------------------------------------------------------------
  @override
  Future<List<String>> summarizeContent(String rawText) async {
    // Split by sentence-ending punctuation, keep non-empty results.
    return rawText
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
