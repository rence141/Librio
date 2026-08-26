import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A liquid fill indicator that fills its parent container from the bottom up.
///
/// The liquid color smoothly transitions:
///   purple (< 75%) → orange (75-90%) → red (≥ 90%)
class LiquidContextIndicator extends StatefulWidget {
  final double usage; // 0.0 to 1.0
  final VoidCallback? onTap;

  const LiquidContextIndicator({super.key, required this.usage, this.onTap});

  @override
  State<LiquidContextIndicator> createState() => _LiquidContextIndicatorState();
}

class _LiquidContextIndicatorState extends State<LiquidContextIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  /// Smoothly interpolate color based on usage level.
  Color _liquidColor(double usage) {
    const purple = Color(0xFF7B2CBF);
    const orange = Color(0xFFE8590C);
    const red = Color(0xFFD90429);

    if (usage < 0.75) {
      // Purple → stays purple (could fade toward orange near 75%)
      return purple;
    } else if (usage < 0.90) {
      // Purple → orange between 75% and 90%
      final t = (usage - 0.75) / 0.15; // 0.0 to 1.0
      return Color.lerp(purple, orange, t)!;
    } else {
      // Orange → red between 90% and 100%
      final t = (usage - 0.90) / 0.10; // 0.0 to 1.0
      return Color.lerp(orange, red, t)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usage = widget.usage.clamp(0.0, 1.0);
    final color = _liquidColor(usage);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _wave,
        builder: (context, _) {
          return CustomPaint(
            painter: _LiquidContextPainter(
              usage: usage,
              phase: _wave.value,
              color: color,
            ),
          );
        },
      ),
    );
  }
}

class _LiquidContextPainter extends CustomPainter {
  final double usage;
  final double phase;
  final Color color;

  const _LiquidContextPainter({
    required this.usage,
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (usage <= 0.001) return;

    // Fill rises from the bottom. At 100%, covers entire height.
    final fillHeight = size.height * usage;
    final surfaceY = size.height - fillHeight;

    // Build the liquid path: wavy surface, then fill down to bottom.
    final waveAmplitude = math.min(1.5, size.height * 0.15);
    final liquid = Path()..moveTo(0, surfaceY);
    for (double x = 0; x <= size.width; x += 1) {
      final y = surfaceY +
          math.sin((x / size.width * math.pi * 2) + phase * math.pi * 2) * waveAmplitude;
      liquid.lineTo(x, y);
    }
    liquid
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Draw the liquid fill
    canvas.drawPath(liquid, Paint()..color = color.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(_LiquidContextPainter old) =>
      old.usage != usage || old.phase != phase || old.color != color;
}
