import 'package:flutter/material.dart';
import '../models/word_result.dart';
import 'word_display.dart';

class SentenceDisplay extends StatelessWidget {
  final List<WordResult> words;
  final void Function(int index)? onWordTap;

  const SentenceDisplay({
    super.key,
    required this.words,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    final tappable = onWordTap != null;

    return Wrap(
      spacing: tappable ? 4 : 8,
      runSpacing: tappable ? 48 : 32,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: List.generate(words.length, (i) {
        return WordDisplay(
          word: words[i],
          tappable: tappable,
          onTap: onWordTap != null ? () => onWordTap!(i) : null,
        );
      }),
    );
  }
}
