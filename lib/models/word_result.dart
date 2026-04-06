enum WordState {
  unspoken,
  current,
  correct,
  wrong,
}

class WordResult {
  final String target;
  String? spoken;
  final String? ipa;
  WordState state;
  double similarity;

  WordResult({
    required this.target,
    this.spoken,
    this.ipa,
    this.state = WordState.unspoken,
    this.similarity = 0.0,
  });
}
