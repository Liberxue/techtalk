import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/practice_cubit.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../models/word_result.dart';
import '../widgets/sentence_display.dart';
import '../widgets/amplitude_bar.dart';
import '../widgets/language_selector.dart';
import '../widgets/lottie_animation.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PracticeCubit>(
      create: (_) => PracticeCubit(),
      child: const _PracticeView(),
    );
  }
}

class _PracticeView extends StatelessWidget {
  const _PracticeView();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final padding = MediaQuery.of(context).padding;

    return BlocBuilder<PracticeCubit, PracticeState>(
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              // Top strip — extra left padding on macOS for traffic lights
              Container(
                padding: EdgeInsets.only(
                  top: Platform.isMacOS ? 38 : padding.top,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.border, width: 0.5),
                  ),
                ),
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: Platform.isMacOS ? 80 : 24,
                      right: 24,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.go('/'),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text('←',
                                style:
                                    AppTextStyles.label(colors.textPrimary)),
                          ),
                        ),
                        const Spacer(),
                        LanguageSelector(
                          selected: state.language,
                          languages: const ['EN', 'JP', 'KR', 'DE'],
                          onChanged: (lang) {
                            HapticFeedback.selectionClick();
                            context.read<PracticeCubit>().setLanguage(lang);
                          },
                        ),
                        const Spacer(),
                        Text(
                          '${state.currentIndex + 1}/${state.totalSentences}',
                          style: AppTextStyles.caption(colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Sentence area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSentenceArea(context, colors, state),
                ),
              ),

              // Voice-reactive organic waveform during recording
              if (state.phase == PracticePhase.recording)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AmplitudeBar(amplitude: state.amplitude),
                ),

              // Bottom controls
              _buildBottomControls(context, colors, padding, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSentenceArea(
      BuildContext context, AppColorScheme colors, PracticeState state) {
    final cubit = context.read<PracticeCubit>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Lottie: mic pulse before recording
        if (state.phase == PracticePhase.before) ...[
          AppLottieAnimation(
            asset: 'assets/animations/mic_pulse.json',
            width: 80,
            height: 80,
            colorOverride: colors.accent,
          )
              .animate()
              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
              .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 400.ms,
                  curve: Curves.easeOutBack),
          const SizedBox(height: 24),
        ],

        // Lottie: success check on result (score >= 70)
        if (state.phase == PracticePhase.result) ...[
          if (state.score >= 70)
            AppLottieAnimation(
              asset: 'assets/animations/success_check.json',
              width: 56,
              height: 56,
              repeat: false,
              colorOverride: colors.success,
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.elasticOut),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: state.score),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, _) {
                  return Text(
                    '$value',
                    style: AppTextStyles.display(colors.accent),
                  );
                },
              ),
              Text('/100', style: AppTextStyles.label(colors.textMuted)),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // Sentence
        SentenceDisplay(
          words: state.words,
          onWordTap: state.phase == PracticePhase.before ||
                  state.phase == PracticePhase.result
              ? (i) {
                  HapticFeedback.selectionClick();
                  cubit.speakWord(state.words[i].target);
                }
              : null,
        ),

        const SizedBox(height: 32),

        // Before: hint text
        if (state.phase == PracticePhase.before) ...[
          Text(
            'tap any word to hear · tap record to begin',
            style: AppTextStyles.caption(colors.textMuted),
          ),
          if (state.errorText != null) ...[
            const SizedBox(height: 12),
            Text(state.errorText!, style: AppTextStyles.caption(colors.error)),
          ],
        ],

        // Recording: wrong word flash with entrance animation
        if (state.phase == PracticePhase.recording &&
            state.wrongWordFlash != null)
          Text(
            state.wrongWordFlash!,
            style: AppTextStyles.headline(colors.error),
          )
              .animate(onPlay: (c) => c.forward())
              .fadeIn(duration: 150.ms)
              .slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 250.ms,
                  curve: Curves.easeOut)
              .then(delay: 1000.ms)
              .fadeOut(duration: 300.ms),

        // Result: wrong words list
        if (state.phase == PracticePhase.result) ...[
          const SizedBox(height: 8),
          ...state.words
              .where((w) => w.state == WordState.wrong)
              .map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        cubit.speakWord(w.target);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(w.target,
                              style: AppTextStyles.caption(colors.error)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('→',
                                style:
                                    AppTextStyles.caption(colors.textMuted)),
                          ),
                          Text('play',
                              style: AppTextStyles.caption(colors.accent)),
                        ],
                      ),
                    ),
                  )),
        ],
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context, AppColorScheme colors,
      EdgeInsets padding, PracticeState state) {
    final cubit = context.read<PracticeCubit>();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: padding.bottom + 24,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (state.phase) {
          PracticePhase.before => SizedBox(
              key: const ValueKey('before'),
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  cubit.startRecording();
                },
                style: TextButton.styleFrom(
                  backgroundColor: colors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('● record',
                    style: AppTextStyles.label(Colors.white)),
              ),
            ),
          PracticePhase.recording => SizedBox(
              key: const ValueKey('recording'),
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  cubit.finishRecording();
                },
                style: TextButton.styleFrom(
                  backgroundColor: colors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('■ stop',
                    style: AppTextStyles.label(Colors.white)),
              ),
            ),
          PracticePhase.result => Row(
              key: const ValueKey('result'),
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        cubit.retry();
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colors.border),
                        ),
                      ),
                      child: Text('retry ↺',
                          style:
                              AppTextStyles.label(colors.textSecondary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        cubit.next();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: colors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('next →',
                          style: AppTextStyles.label(Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }
}
