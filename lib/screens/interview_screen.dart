import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/interview_cubit.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../models/interview_scenario.dart';
import '../widgets/amplitude_bar.dart';
import '../widgets/language_selector.dart';
import '../widgets/lottie_animation.dart';

class InterviewScreen extends StatelessWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InterviewCubit>(
      create: (_) => InterviewCubit(),
      child: const _InterviewView(),
    );
  }
}

class _InterviewView extends StatefulWidget {
  const _InterviewView();

  @override
  State<_InterviewView> createState() => _InterviewViewState();
}

class _InterviewViewState extends State<_InterviewView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitTyped() {
    final text = _inputController.text.trim();
    final cubit = context.read<InterviewCubit>();
    final state = cubit.state;
    if (text.isEmpty || state.isTyping || !state.awaitingAnswer) return;

    HapticFeedback.mediumImpact();
    _inputController.clear();
    FocusScope.of(context).unfocus();
    cubit.submitAnswer(text);
  }

  void _showScenarioPicker() {
    final colors = AppColors.of(context);
    final cubit = context.read<InterviewCubit>();
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return BlocBuilder<InterviewCubit, InterviewState>(
          bloc: cubit,
          builder: (_, state) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                bottom: MediaQuery.of(sheetCtx).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 16),
                    child: Text('SCENARIO',
                        style: AppTextStyles.micro(colors.textMuted)),
                  ),
                  ...interviewScenarios.map((s) {
                    final isActive = s.name == state.scenario.name;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        cubit.setScenario(s);
                        Navigator.pop(sheetCtx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        color: isActive ? colors.surface : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: AppTextStyles.label(
                                      isActive
                                          ? colors.accent
                                          : colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.turns.length} questions \u00b7 ${s.description}',
                                    style:
                                        AppTextStyles.caption(colors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              Text('\u2713',
                                  style: AppTextStyles.label(colors.accent)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final padding = MediaQuery.of(context).padding;

    return BlocConsumer<InterviewCubit, InterviewState>(
      listener: (context, state) {
        _scrollToBottom();
      },
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              // Top strip
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
                          onTap: () {
                            context.read<InterviewCubit>().stopTts();
                            context.go('/');
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text('\u2190',
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
                            context.read<InterviewCubit>().setLanguage(lang);
                          },
                        ),
                        const Spacer(),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _showScenarioPicker,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.scenario.name,
                                style: AppTextStyles.caption(colors.textMuted),
                              ),
                              const SizedBox(width: 4),
                              Text('\u25be',
                                  style:
                                      AppTextStyles.caption(colors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: state.started
                    ? _buildChat(colors, state)
                    : _buildStart(colors, state),
              ),

              // Input area
              if (state.started && state.awaitingAnswer && !state.isThinking)
                _buildInput(colors, padding, state),
            ],
          ),
        );
      },
    );
  }

  // --- Start screen ---
  Widget _buildStart(AppColorScheme colors, InterviewState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.scenario.name,
              style: AppTextStyles.headline(colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.scenario.turns.length} questions \u00b7 ${state.scenario.description}',
              style: AppTextStyles.caption(colors.textMuted),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.read<InterviewCubit>().startInterview();
                },
                style: TextButton.styleFrom(
                  backgroundColor: colors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'begin interview \u2192',
                  style: AppTextStyles.label(Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _showScenarioPicker,
              child: Text(
                'change scenario',
                style: AppTextStyles.caption(colors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Chat area ---
  Widget _buildChat(AppColorScheme colors, InterviewState state) {
    final extraItems =
        (state.isRecording && state.partialText.isNotEmpty ? 1 : 0) +
            (state.isThinking ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: state.messages.length + extraItems,
      itemBuilder: (context, index) {
        if (index < state.messages.length) {
          return _buildMessage(state.messages[index], colors);
        }
        // Extra items after messages
        if (state.isRecording && state.partialText.isNotEmpty) {
          return _buildLivePreview(colors, state);
        }
        if (state.isThinking) {
          return _buildThinking(colors);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLivePreview(AppColorScheme colors, InterviewState state) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('YOU', style: AppTextStyles.micro(colors.textMuted)),
          const SizedBox(height: 4),
          Text(
            state.partialText,
            style: AppTextStyles.label(colors.textMuted)
                .copyWith(height: 1.7, fontStyle: FontStyle.italic),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildThinking(AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FEEDBACK', style: AppTextStyles.micro(colors.textMuted)),
          const SizedBox(height: 8),
          Text(
            'analyzing...',
            style: AppTextStyles.caption(colors.textMuted),
          ),
        ],
      ),
    );
  }

  // --- Message rendering ---
  Widget _buildMessage(InterviewMessage msg, AppColorScheme colors) {
    switch (msg.role) {
      case 'interviewer':
        return _buildInterviewerMsg(msg, colors);
      case 'you':
        return _buildUserMsg(msg, colors);
      case 'feedback':
        return _buildFeedback(msg, colors);
      case 'summary':
        return _buildSummaryMsg(msg, colors);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInterviewerMsg(InterviewMessage msg, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('INTERVIEWER',
                  style: AppTextStyles.micro(colors.textMuted)),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<InterviewCubit>().speakSentence(msg.text);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text('\u25b6',
                      style: AppTextStyles.caption(colors.accent)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            msg.text,
            style:
                AppTextStyles.label(colors.textPrimary).copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMsg(InterviewMessage msg, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('YOU', style: AppTextStyles.micro(colors.textMuted)),
          const SizedBox(height: 4),
          Text(
            msg.text,
            style: AppTextStyles.label(colors.textSecondary)
                .copyWith(height: 1.7),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedback(InterviewMessage msg, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('FEEDBACK',
                    style: AppTextStyles.micro(colors.textMuted)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: ((msg.score ?? 0) >= 70
                            ? colors.success
                            : colors.amber)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${msg.score}/100',
                    style: AppTextStyles.captionMedium(
                      (msg.score ?? 0) >= 70
                          ? colors.success
                          : colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (msg.correct != null) ...[
              Text(
                '\u2713 ${msg.correct}',
                style: AppTextStyles.caption(colors.success),
              ),
              const SizedBox(height: 6),
            ],
            if (msg.improve != null) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  final match =
                      RegExp(r"'(\w+)'").firstMatch(msg.improve ?? '');
                  if (match != null) {
                    context
                        .read<InterviewCubit>()
                        .speakWord(match.group(1)!);
                  }
                },
                child: Text(
                  '\u2192 ${msg.improve}',
                  style: AppTextStyles.caption(colors.error),
                ),
              ),
              const SizedBox(height: 6),
            ],
            if (msg.nativeAlt != null)
              Text(
                msg.nativeAlt!,
                style: AppTextStyles.caption(colors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMsg(InterviewMessage msg, AppColorScheme colors) {
    final score = msg.score ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.accent, width: 1),
        ),
        child: Column(
          children: [
            if (score >= 70)
              AppLottieAnimation(
                asset: 'assets/animations/success_check.json',
                width: 48,
                height: 48,
                repeat: false,
                colorOverride: colors.success,
              ),
            const SizedBox(height: 12),
            Text('INTERVIEW COMPLETE',
                style: AppTextStyles.micro(colors.textMuted)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: score),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, _) {
                    return Text(
                      '$value',
                      style: AppTextStyles.display(colors.accent),
                    );
                  },
                ),
                Text('/100',
                    style: AppTextStyles.label(colors.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              score >= 80
                  ? 'excellent performance'
                  : score >= 60
                      ? 'good effort, keep practicing'
                      : 'needs more practice',
              style: AppTextStyles.caption(colors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.read<InterviewCubit>().reset();
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colors.border),
                        ),
                      ),
                      child: Text('retry \u21ba',
                          style:
                              AppTextStyles.caption(colors.textSecondary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.go('/');
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: colors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('done',
                          style: AppTextStyles.caption(Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Input bar ---
  Widget _buildInput(
      AppColorScheme colors, EdgeInsets padding, InterviewState state) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isRecording) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AmplitudeBar(
                amplitude: state.partialText.isEmpty ? 0.05 : 0.6,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  maxLines: 4,
                  minLines: 1,
                  enabled: !state.isRecording,
                  style: AppTextStyles.label(colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: state.isRecording
                        ? 'listening...'
                        : 'type or tap \u25cf to speak...',
                    hintStyle: AppTextStyles.label(colors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _submitTyped(),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: state.isRecording
                    ? () => context.read<InterviewCubit>().stopRecording()
                    : () {
                        HapticFeedback.mediumImpact();
                        context.read<InterviewCubit>().startRecording();
                      },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    state.isRecording ? '\u25a0' : '\u25cf',
                    style: AppTextStyles.headline(colors.error),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
