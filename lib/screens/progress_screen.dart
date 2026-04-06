import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../services/tts_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final TtsService _tts = TtsService();
  bool _weakWordsExpanded = false;

  final List<_WeakWord> _weakWords = const [
    _WeakWord(word: 'latency', ipa: '/ˈleɪtənsi/', lastScore: 67),
    _WeakWord(word: 'throughput', ipa: '/ˈθruːpʊt/', lastScore: 72),
    _WeakWord(word: 'idempotent', ipa: '/ˌaɪdɛmˈpoʊtənt/', lastScore: 58),
  ];

  @override
  void initState() {
    super.initState();
    _tts.init();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: padding.top + 16,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Progress',
                style: AppTextStyles.body(colors.textPrimary),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: padding.bottom + 80),
              children: AnimateList(
                interval: 60.ms,
                effects: [
                  FadeEffect(duration: 300.ms, curve: Curves.easeOut),
                  SlideEffect(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  ),
                ],
                children: [
                  _metricRow('STREAK', '12 days', true, colors),
                  _divider(colors),
                  _metricRow('TOTAL XP', '2,840', true, colors),
                  _divider(colors),
                  _metricRow('SESSIONS', '47', true, colors),
                  _divider(colors),
                  _metricRow('AVG SCORE', '81/100', true, colors),
                  _divider(colors),
                  _metricRow('BEST SCENE', 'System Design', false, colors),
                  _divider(colors),
                  _weakWordsRow(colors),
                  _divider(colors),
                  _metricRow('TARGET LANG', 'EN → JP', false, colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(
    String label,
    String value,
    bool primary,
    AppColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.caption(colors.textMuted)
                .copyWith(letterSpacing: 1.0),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: primary
                  ? AppTextStyles.headline(colors.textPrimary)
                  : AppTextStyles.label(colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weakWordsRow(AppColorScheme colors) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _weakWordsExpanded = !_weakWordsExpanded);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'WEAK WORDS',
                  style: AppTextStyles.caption(colors.textMuted)
                      .copyWith(letterSpacing: 1.0),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _weakWords.map((w) => w.word).join(' · '),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label(colors.textSecondary),
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: _weakWords
                      .map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    w.word,
                                    style: AppTextStyles.label(
                                        colors.textPrimary),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    w.ipa,
                                    style: AppTextStyles.caption(
                                        colors.textMuted),
                                  ),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _tts.speakWord(w.word);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    child: Text(
                                      'play',
                                      style: AppTextStyles.caption(
                                          colors.accent),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '${w.lastScore}%',
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.caption(
                                        colors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              crossFadeState: _weakWordsExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(AppColorScheme colors) {
    return Divider(
      height: 0.5,
      indent: 24,
      endIndent: 24,
      color: colors.border,
    );
  }
}

class _WeakWord {
  final String word;
  final String ipa;
  final int lastScore;

  const _WeakWord({
    required this.word,
    required this.ipa,
    required this.lastScore,
  });
}
