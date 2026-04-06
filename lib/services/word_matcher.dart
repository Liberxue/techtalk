import 'dart:math';

class WordMatcher {
  static double similarity(String a, String b) {
    a = a.toLowerCase().trim();
    b = b.toLowerCase().trim();
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final distance = _levenshtein(a, b);
    final maxLen = max(a.length, b.length);
    return 1.0 - (distance / maxLen);
  }

  static int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = min(
          min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
          dp[i - 1][j - 1] + cost,
        );
      }
    }
    return dp[m][n];
  }

  /// Compare spoken words against target sentence, returns results per word.
  static List<MatchResult> compare(String target, String spoken) {
    final targetWords = target
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final spokenWords = spoken
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final results = <MatchResult>[];

    for (var i = 0; i < targetWords.length; i++) {
      if (i < spokenWords.length) {
        final sim = similarity(targetWords[i], spokenWords[i]);
        results.add(MatchResult(
          targetWord: targetWords[i],
          spokenWord: spokenWords[i],
          similarity: sim,
          isCorrect: sim >= 0.75,
        ));
      } else {
        results.add(MatchResult(
          targetWord: targetWords[i],
          spokenWord: null,
          similarity: 0.0,
          isCorrect: false,
        ));
      }
    }

    return results;
  }
}

class MatchResult {
  final String targetWord;
  final String? spokenWord;
  final double similarity;
  final bool isCorrect;

  const MatchResult({
    required this.targetWord,
    this.spokenWord,
    required this.similarity,
    required this.isCorrect,
  });
}
