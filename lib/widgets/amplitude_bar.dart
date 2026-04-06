import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Modern centered waveform visualizer.
/// Mirrored bars grow up and down from center, responding to voice amplitude.
/// Silent = flat line. Speaking = bars ripple outward from center.
class AmplitudeBar extends StatefulWidget {
  final double amplitude; // 0.0 to 1.0

  const AmplitudeBar({
    super.key,
    required this.amplitude,
  });

  @override
  State<AmplitudeBar> createState() => _AmplitudeBarState();
}

class _AmplitudeBarState extends State<AmplitudeBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _smooth = 0.0;
  // Ring buffer of recent amplitude samples for ripple history
  final List<double> _history = List.filled(40, 0.0);
  int _historyIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Smooth follow
        _smooth += (widget.amplitude - _smooth) * 0.12;
        if (_smooth < 0.005) _smooth = 0.0;

        // Push current amplitude into history ring buffer
        _history[_historyIndex % _history.length] = _smooth;
        _historyIndex++;

        return CustomPaint(
          size: const Size(double.infinity, 56),
          painter: _WaveformPainter(
            time: _controller.value,
            amplitude: _smooth,
            history: _history,
            historyIndex: _historyIndex,
            color: colors.accent,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double time;
  final double amplitude;
  final List<double> history;
  final int historyIndex;
  final Color color;

  static const int barCount = 40;
  static const double barWidth = 3.0;
  static const double barGap = 2.5;

  _WaveformPainter({
    required this.time,
    required this.amplitude,
    required this.history,
    required this.historyIndex,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final totalBarWidth = barCount * (barWidth + barGap) - barGap;
    final startX = (size.width - totalBarWidth) / 2;
    final maxBarHeight = size.height * 0.45;

    for (var i = 0; i < barCount; i++) {
      // Sample from history — creates a ripple/propagation effect
      // Center bars use newest samples, edge bars use older samples
      final distFromCenter = (i - barCount / 2).abs() / (barCount / 2);
      final historyOffset = (distFromCenter * 12).round();
      final sampleIndex =
          (historyIndex - 1 - historyOffset) % history.length;
      final sampleAmp =
          history[sampleIndex < 0 ? sampleIndex + history.length : sampleIndex];

      // Base height: minimal line when silent, grows with amplitude
      final idleHeight = 2.0;
      final activeHeight = sampleAmp * maxBarHeight;

      // Add subtle organic motion — center bars breathe slightly
      final breathe = amplitude > 0.01
          ? sin(time * 2 * pi * 2 + i * 0.4) * 1.5 * amplitude
          : 0.0;

      final barHeight =
          (idleHeight + activeHeight + breathe).clamp(idleHeight, maxBarHeight);

      // Opacity: center bars brighter, edge bars fade out
      final opacityBase = amplitude > 0.01 ? 0.3 : 0.15;
      final opacity =
          (opacityBase + (1 - distFromCenter) * 0.6 * sampleAmp.clamp(0.0, 1.0))
              .clamp(0.1, 0.95);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth
        ..style = PaintingStyle.stroke;

      final x = startX + i * (barWidth + barGap) + barWidth / 2;

      // Draw mirrored bar from center
      canvas.drawLine(
        Offset(x, midY - barHeight),
        Offset(x, midY + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}
