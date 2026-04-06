import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../services/tts_service.dart';

/// IPA lookup for common tech/English words.
const ipaMap = <String, String>{
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

/// Overlay popup showing IPA + play button when user taps a word in Listen mode.
class WordPopup {
  static OverlayEntry? _current;

  static void show({
    required BuildContext context,
    required String word,
    required Offset position,
    required TtsService tts,
  }) {
    dismiss();

    final colors = AppColors.of(context);
    final overlay = Overlay.of(context);
    final cleanWord = word.replaceAll(RegExp(r"[^\w'-]"), '').toLowerCase();
    final ipa = ipaMap[cleanWord];

    _current = OverlayEntry(
      builder: (ctx) => _WordPopupOverlay(
        word: cleanWord,
        ipa: ipa,
        position: position,
        colors: colors,
        tts: tts,
        onDismiss: dismiss,
      ),
    );

    overlay.insert(_current!);

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), dismiss);
  }

  static void dismiss() {
    _current?.remove();
    _current = null;
  }
}

class _WordPopupOverlay extends StatefulWidget {
  final String word;
  final String? ipa;
  final Offset position;
  final AppColorScheme colors;
  final TtsService tts;
  final VoidCallback onDismiss;

  const _WordPopupOverlay({
    required this.word,
    this.ipa,
    required this.position,
    required this.colors,
    required this.tts,
    required this.onDismiss,
  });

  @override
  State<_WordPopupOverlay> createState() => _WordPopupOverlayState();
}

class _WordPopupOverlayState extends State<_WordPopupOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _anim.forward();

    // Speak the word
    widget.tts.speakWord(widget.word);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const popupWidth = 200.0;

    // Position popup above the tapped word, centered
    var left = widget.position.dx - popupWidth / 2;
    left = left.clamp(16.0, screenWidth - popupWidth - 16);
    final top = widget.position.dy - 80;

    return Stack(
      children: [
        // Tap anywhere to dismiss
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
            child: const SizedBox.expand(),
          ),
        ),
        // Popup card
        Positioned(
          left: left,
          top: top.clamp(60.0, double.infinity),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, child) => Opacity(
              opacity: _opacity.value,
              child: Transform.scale(scale: _scale.value, child: child),
            ),
            child: Container(
              width: popupWidth,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.colors.border,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.colors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Word
                  Text(
                    widget.word,
                    style: GoogleFonts.sourceSerif4(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: widget.colors.textPrimary,
                    ),
                  ),
                  if (widget.ipa != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.ipa!,
                      style: AppTextStyles.caption(widget.colors.textMuted),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Play button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.tts.speakWord(widget.word);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.colors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.volume_up_rounded,
                              size: 16, color: widget.colors.accent),
                          const SizedBox(width: 6),
                          Text(
                            'play again',
                            style: AppTextStyles.caption(widget.colors.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
