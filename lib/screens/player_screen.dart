import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/player_cubit.dart';
import '../models/audio_content.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../services/tts_service.dart';
import '../widgets/tappable_word.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final ScrollController _scroll = ScrollController();
  final TtsService _wordTts = TtsService();
  final Map<int, GlobalKey> _lineKeys = {};

  @override
  void initState() {
    super.initState();
    _wordTts.init();
  }

  @override
  void dispose() {
    WordPopup.dismiss();
    _scroll.dispose();
    _wordTts.dispose();
    super.dispose();
  }

  void _scrollToLine(int idx) {
    final key = _lineKeys[idx];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: 600.ms,
      curve: Curves.easeOutCubic,
      alignment: 0.38,
    );
  }

  /// Read a full sentence aloud (independent of playback).
  void _speakSentence(String text) {
    HapticFeedback.mediumImpact();
    _wordTts.stop();
    _wordTts.speakSentence(text);
  }

  /// Show word popup at tap position.
  void _showWordPopup(String word, Offset globalPos) {
    HapticFeedback.selectionClick();
    WordPopup.show(
      context: context,
      word: word,
      position: globalPos,
      tts: _wordTts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final safePad = MediaQuery.of(context).padding;
    final screenH = MediaQuery.of(context).size.height;

    return BlocConsumer<PlayerCubit, PlayerState>(
      listenWhen: (p, c) => p.currentSentence != c.currentSentence,
      listener: (_, state) {
        Future.delayed(80.ms, () => _scrollToLine(state.currentSentence));
      },
      builder: (context, state) {
        if (!state.hasContent) {
          return const Scaffold(body: SizedBox.shrink());
        }
        final content = state.content!;
        final cubit = context.read<PlayerCubit>();

        return Scaffold(
          body: Column(
            children: [
              _buildHeader(context, colors, content, state, cubit, safePad),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent, colors.background,
                      colors.background, Colors.transparent,
                    ],
                    stops: const [0.0, 0.15, 0.80, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.only(
                      left: 28, right: 28,
                      top: screenH * 0.25,
                      bottom: screenH * 0.25,
                    ),
                    itemCount: state.sentences.length,
                    itemBuilder: (_, i) {
                      _lineKeys[i] ??= GlobalKey();
                      return KeyedSubtree(
                        key: _lineKeys[i],
                        child: _LyricLine(
                          text: state.sentences[i],
                          index: i,
                          currentIndex: state.currentSentence,
                          isPlaying: state.isPlaying,
                          highlightStart: state.highlightStart,
                          highlightEnd: state.highlightEnd,
                          onLineTap: () => _speakSentence(state.sentences[i]),
                          onLineDoubleTap: () {
                            HapticFeedback.heavyImpact();
                            cubit.jumpTo(i);
                          },
                          onWordTap: _showWordPopup,
                        ),
                      );
                    },
                  ),
                ),
              ),
              _buildControls(context, colors, state, cubit, safePad),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colors,
      AudioContent content, PlayerState state, PlayerCubit cubit,
      EdgeInsets safePad) {
    return Padding(
      padding: EdgeInsets.only(
        top: safePad.top + 8, left: 24, right: 24, bottom: 4,
      ),
      child: Column(children: [
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colors.border, borderRadius: BorderRadius.circular(2),
          ),
        ),
        Row(children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              WordPopup.dismiss();
              Navigator.of(context).pop();
            },
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: colors.textSecondary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content.title,
                    style: AppTextStyles.captionMedium(colors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(content.source,
                    style: AppTextStyles.caption(colors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              const speeds = [0.5, 0.75, 1.0, 1.25, 1.5];
              final idx = speeds.indexOf(state.speed);
              cubit.setSpeed(speeds[(idx + 1) % speeds.length]);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surface, borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${state.speed}x',
                  style: AppTextStyles.caption(colors.accent)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildControls(BuildContext context, AppColorScheme colors,
      PlayerState state, PlayerCubit cubit, EdgeInsets safePad) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        boxShadow: [BoxShadow(
          color: colors.textPrimary.withValues(alpha: 0.03),
          blurRadius: 12, offset: const Offset(0, -4),
        )],
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 10, bottom: safePad.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hint text
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'tap line to hear · double-tap to play from there',
              style: AppTextStyles.caption(colors.textMuted)
                  .copyWith(fontSize: 10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${state.currentSentence + 1} / ${state.sentences.length}',
              style: AppTextStyles.caption(colors.textMuted),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: state.progress, minHeight: 2,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation(colors.accent),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Btn(Icons.skip_previous_rounded, 26, colors.textSecondary, () {
                HapticFeedback.selectionClick(); cubit.previous();
              }),
              const SizedBox(width: 40),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  if (state.isIdle && state.hasContent) {
                    cubit.play(state.content!,
                        fromSentence: state.currentSentence);
                  } else {
                    cubit.togglePlayPause();
                  }
                },
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: colors.accent, shape: BoxShape.circle,
                    boxShadow: state.isPlaying
                        ? [BoxShadow(
                            color: colors.accent.withValues(alpha: 0.25),
                            blurRadius: 16, offset: const Offset(0, 4),
                          )]
                        : [],
                  ),
                  child: Icon(
                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 40),
              _Btn(Icons.skip_next_rounded, 26, colors.textSecondary, () {
                HapticFeedback.selectionClick(); cubit.next();
              }),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── LYRIC LINE with selectable words ───

class _LyricLine extends StatefulWidget {
  final String text;
  final int index;
  final int currentIndex;
  final bool isPlaying;
  final int highlightStart;
  final int highlightEnd;
  final VoidCallback onLineTap;
  final VoidCallback onLineDoubleTap;
  final void Function(String word, Offset globalPos) onWordTap;

  const _LyricLine({
    required this.text,
    required this.index,
    required this.currentIndex,
    required this.isPlaying,
    required this.highlightStart,
    required this.highlightEnd,
    required this.onLineTap,
    required this.onLineDoubleTap,
    required this.onWordTap,
  });

  @override
  State<_LyricLine> createState() => _LyricLineState();
}

class _LyricLineState extends State<_LyricLine> {
  // For long-press word selection
  final Set<int> _selectedWordIndices = {};
  bool _selecting = false;
  late List<_WordInfo> _words;

  bool get _isCurrent => widget.index == widget.currentIndex;
  bool get _isPast => widget.index < widget.currentIndex;
  bool get _isActive => _isCurrent && widget.isPlaying;

  @override
  void initState() {
    super.initState();
    _buildWords();
  }

  @override
  void didUpdateWidget(_LyricLine old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _buildWords();
  }

  void _buildWords() {
    _words = [];
    for (final m in RegExp(r'\S+').allMatches(widget.text)) {
      _words.add(_WordInfo(m.start, m.end, widget.text.substring(m.start, m.end)));
    }
  }

  void _readSelected() {
    if (_selectedWordIndices.isEmpty) return;
    final sorted = _selectedWordIndices.toList()..sort();
    final selectedText = sorted.map((i) => _words[i].text).join(' ');
    HapticFeedback.mediumImpact();

    // Speak the selected words directly (no ugly SnackBar)
    widget.onWordTap(selectedText, Offset.zero);

    setState(() {
      _selectedWordIndices.clear();
      _selecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: widget.onLineTap,
      onDoubleTap: widget.onLineDoubleTap,
      onLongPressStart: (details) {
        HapticFeedback.selectionClick();
        setState(() {
          _selecting = true;
          _selectedWordIndices.clear();
          // Find which word was long-pressed
          final wordIdx = _findWordAtPosition(details.localPosition, context);
          if (wordIdx >= 0) _selectedWordIndices.add(wordIdx);
        });
      },
      onLongPressMoveUpdate: (details) {
        if (!_selecting) return;
        final wordIdx = _findWordAtPosition(details.localPosition, context);
        if (wordIdx >= 0 && !_selectedWordIndices.contains(wordIdx)) {
          HapticFeedback.selectionClick();
          setState(() => _selectedWordIndices.add(wordIdx));
        }
      },
      onLongPressEnd: (_) {
        if (_selecting) _readSelected();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: _isCurrent ? 16 : 10),
        child: _isActive
            ? _buildHighlighted(colors)
            : _buildInteractive(colors),
      ),
    );
  }

  int _findWordAtPosition(Offset localPos, BuildContext context) {
    // Approximate word hit-test based on horizontal position
    if (_words.isEmpty) return -1;
    final width = context.size?.width ?? 300;
    final totalChars = widget.text.length;
    if (totalChars == 0) return -1;
    final charPos = (localPos.dx / width * totalChars).round().clamp(0, totalChars - 1);

    for (var i = 0; i < _words.length; i++) {
      if (charPos >= _words[i].start && charPos <= _words[i].end) return i;
    }
    // Find nearest word
    int nearest = 0;
    int minDist = 999;
    for (var i = 0; i < _words.length; i++) {
      final center = (_words[i].start + _words[i].end) ~/ 2;
      final dist = (charPos - center).abs();
      if (dist < minDist) { minDist = dist; nearest = i; }
    }
    return nearest;
  }

  /// Non-playing: per-word tappable with selection highlight.
  Widget _buildInteractive(AppColorScheme colors) {
    final baseStyle = _plainStyle(colors);
    final spans = <InlineSpan>[];
    int cursor = 0;

    for (var i = 0; i < _words.length; i++) {
      final w = _words[i];
      // Whitespace
      if (w.start > cursor) {
        spans.add(TextSpan(
          text: widget.text.substring(cursor, w.start), style: baseStyle,
        ));
      }
      final isSelected = _selectedWordIndices.contains(i);
      final recognizer = TapGestureRecognizer()
        ..onTapUp = (details) => widget.onWordTap(w.text, details.globalPosition);

      spans.add(TextSpan(
        text: w.text,
        recognizer: recognizer,
        style: isSelected
            ? baseStyle.copyWith(
                color: colors.accent,
                backgroundColor: colors.accent.withValues(alpha: 0.15),
                fontWeight: FontWeight.w600,
              )
            : baseStyle,
      ));
      cursor = w.end;
    }

    if (cursor < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(cursor), style: baseStyle,
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  /// Playing: karaoke word highlighting.
  Widget _buildHighlighted(AppColorScheme colors) {
    final hStart = widget.highlightStart;
    final hEnd = widget.highlightEnd;
    final spans = <InlineSpan>[];
    int cursor = 0;

    for (final w in _words) {
      if (w.start > cursor) {
        spans.add(TextSpan(
          text: widget.text.substring(cursor, w.start),
          style: _hlWhitespace(colors, w.start, hStart),
        ));
      }

      final isCurWord = hStart >= 0 && w.start <= hStart && w.end >= hEnd;
      final isSpoken = hStart >= 0 && w.end <= hStart;

      final recognizer = TapGestureRecognizer()
        ..onTapUp = (details) => widget.onWordTap(w.text, details.globalPosition);

      spans.add(TextSpan(
        text: w.text,
        recognizer: recognizer,
        style: GoogleFonts.sourceSerif4(
          fontSize: 22,
          fontWeight: isCurWord ? FontWeight.w700 : FontWeight.w500,
          color: isCurWord
              ? colors.textPrimary
              : isSpoken ? colors.accent : colors.textMuted,
          height: 1.6,
          backgroundColor:
              isCurWord ? colors.accent.withValues(alpha: 0.15) : null,
        ),
      ));
      cursor = w.end;
    }

    if (cursor < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(cursor),
        style: _hlWhitespace(colors, cursor, hStart),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  TextStyle _plainStyle(AppColorScheme colors) {
    if (_isCurrent) {
      return GoogleFonts.sourceSerif4(
        fontSize: 22, fontWeight: FontWeight.w500,
        color: widget.isPlaying ? colors.accent : colors.textPrimary,
        height: 1.6,
      );
    }
    if (_isPast) {
      return GoogleFonts.sourceSerif4(
        fontSize: 17, fontWeight: FontWeight.w400,
        color: colors.textMuted.withValues(alpha: 0.6), height: 1.7,
      );
    }
    return GoogleFonts.sourceSerif4(
      fontSize: 17, fontWeight: FontWeight.w400,
      color: colors.textSecondary.withValues(alpha: 0.4), height: 1.7,
    );
  }

  TextStyle _hlWhitespace(AppColorScheme colors, int pos, int hStart) {
    final isSpoken = hStart >= 0 && pos < hStart;
    return GoogleFonts.sourceSerif4(
      fontSize: 22, fontWeight: FontWeight.w500,
      color: isSpoken ? colors.accent : colors.textMuted, height: 1.6,
    );
  }
}

class _WordInfo {
  final int start, end;
  final String text;
  const _WordInfo(this.start, this.end, this.text);
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.icon, this.size, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
