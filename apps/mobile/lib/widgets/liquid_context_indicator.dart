import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A liquid fill indicator that fills its parent container from the bottom up.
///
/// Place this inside a clipped container (e.g. ClipRRect). It expands to fill
/// the available area and paints a purple liquid that rises from the bottom
/// according to [usage]. The liquid is clipped to the widget bounds, which
/// should match the parent's rounded-rectangle shape.
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

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.translucent,
      child: Semantics(
        label: 'Context ${(usage * 100).round()} percent used',
        button: widget.onTap != null,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _wave,
            builder: (context, _) {
              return CustomPaint(
                // No fixed size — fills the parent Stack/ClipRRect entirely
                painter: _LiquidContextPainter(
                  usage: usage,
                  phase: _wave.value,
                  color: color,
                ),
              );
            },
          ),
        ),
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
    // The parent ClipRRect already clips to the rounded-rectangle.
    // We just paint within the given bounds.

    // 0% — nothing to draw
    if (usage <= 0.001) return;

    // The fill level: liquid rises from the bottom.
    // At 100%, the liquid covers the entire height.
    final fillHeight = size.height * usage;
    final surfaceY = size.height - fillHeight; // y-coordinate of the liquid surface

    // Build the liquid path: wavy surface, then fill down to bottom.
    final liquid = Path()..moveTo(0, surfaceY);
    final waveAmplitude = math.min(2.0, size.height * 0.08);
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
    canvas.drawPath(liquid, Paint()..color = color.withValues(alpha: 0.18));

    // Draw a brighter surface line on top of the liquid
    final surface = Path()..moveTo(0, surfaceY);
    for (double x = 0; x <= size.width; x += 1) {
      final y = surfaceY +
          math.sin((x / size.width * math.pi * 2) + phase * math.pi * 2) * waveAmplitude;
      surface.lineTo(x, y);
    }
    canvas.drawPath(
      surface,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_LiquidContextPainter old) =>
      old.usage != usage || old.phase != phase || old.color != color;
}
