import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A liquid fill indicator that fills its parent container from the bottom up.
///
/// Place this inside a clipped container (e.g. ClipRRect with StackFit.expand).
/// It expands to fill the available area and paints a purple liquid that rises
/// from the bottom according to [usage]. The liquid is clipped to the widget
/// bounds, which should match the parent's rounded-rectangle shape.
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

  @override
  Widget build(BuildContext context) {
    final usage = widget.usage.clamp(0.0, 1.0);
    const color = Color(0xFF7B2CBF);

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
