import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/word_result.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// IPA lookup for common tech words.
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
  'using': '/ˈjuː.zɪŋ/',
  'need': '/niːd/',
  'not': '/nɒt/',
  'the': '/ðə/',
  'this': '/ðɪs/',
  'we': '/wiː/',
  'is': '/ɪz/',
  'to': '/tuː/',
  'a': '/eɪ/',
  'an': '/æn/',
};

class WordDisplay extends StatefulWidget {
  final WordResult word;
  final VoidCallback? onTap;
  final bool tappable;

  const WordDisplay({
    super.key,
    required this.word,
    this.onTap,
    this.tappable = false,
  });

  @override
  State<WordDisplay> createState() => _WordDisplayState();
}

class _WordDisplayState extends State<WordDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnim;
  late Animation<double> _bgOpacityAnim;
  bool _showTip = false;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.06), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeInOut,
    ));
    _bgOpacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;

    HapticFeedback.selectionClick();
    _tapController.forward(from: 0);

    setState(() => _showTip = true);
    widget.onTap!();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _showTip = false);
    });
  }

  String? get _ipa {
    final key = widget.word.target.toLowerCase();
    return widget.word.ipa ?? _ipaMap[key];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final word = widget.word;

    Color textColor;
    FontWeight weight = FontWeight.w400;
    TextDecoration? decoration;
    double baseScale = 1.0;

    switch (word.state) {
      case WordState.unspoken:
        textColor = colors.textMuted;
      case WordState.current:
        textColor = colors.textPrimary;
        baseScale = 1.05;
      case WordState.correct:
        textColor = colors.success;
        weight = FontWeight.w500;
      case WordState.wrong:
        textColor = colors.error;
        weight = FontWeight.w500;
        decoration = TextDecoration.lineThrough;
    }

    final textWidget = AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      style: AppTextStyles.body(textColor).copyWith(
        fontWeight: weight,
        decoration: decoration,
        decorationColor: colors.error,
      ),
      child: Text(word.target),
    );

    final content = AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: baseScale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          textWidget,
          if (word.state == WordState.current)
            Container(
              margin: const EdgeInsets.only(top: 2),
              height: 2,
              width: word.target.length * 10.0,
              color: colors.accent,
            ),
        ],
      ),
    );

    if (!widget.tappable || widget.onTap == null) {
      return content;
    }

    // Tappable version with press animation + tooltip
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _tapController,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // IPA tooltip — floats above the word
              AnimatedOpacity(
                opacity: _showTip ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: AnimatedSlide(
                  offset: _showTip ? Offset.zero : const Offset(0, 0.3),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: colors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      _ipa ?? word.target,
                      style: AppTextStyles.caption(colors.textSecondary),
                    ),
                  ),
                ),
              ),
              // Word with scale + bg highlight animation
              Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (word.state == WordState.wrong
                            ? colors.error
                            : colors.accent)
                        .withValues(alpha: _bgOpacityAnim.value * 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: content,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
