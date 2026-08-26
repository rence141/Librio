import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A compact liquid fill that complements the detailed context bar.
/// The liquid is strictly contained within a horizontal rounded-rectangle.
class LiquidContextIndicator extends StatefulWidget {
  final double usage;
  final VoidCallback? onTap;

  const LiquidContextIndicator({super.key, required this.usage, this.onTap});

  @override
  State<LiquidContextIndicator> createState() => _LiquidContextIndicatorState();
}

class _LiquidContextIndicatorState extends State<LiquidContextIndicator>
    with SingleTickerProviderStateMixin {
  // Pill radius — half of height, so ends are fully rounded but shape is rectangular
  static const _height = 7.0;
  static const _width = 46.0;
  static const _radius = Radius.circular(_height / 2);

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
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
    return Semantics(
      label: 'Context ${(usage * 100).round()} percent used',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: _width,
          height: _height,
          // Strict containment: clip everything to the rounded-rectangle bar
          child: ClipRRect(
            borderRadius: const BorderRadius.all(_radius),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: const BorderRadius.all(_radius),
              ),
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _wave,
                  builder: (context, _) => CustomPaint(
                    size: const Size(_width, _height),
                    painter: _LiquidContextPainter(
                      usage: usage,
                      phase: _wave.value,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
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
  const _LiquidContextPainter({required this.usage, required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Clip to the exact rounded-rectangle bounds — liquid never escapes
    final bounds = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.clipRRect(bounds);

    final level = size.height * (1 - usage);
    final wave = Path()..moveTo(0, level);
    for (double x = 0; x <= size.width; x += 2) {
      final y = level + math.sin((x / size.width * math.pi * 2) + phase * math.pi * 2) * 1.1;
      wave.lineTo(x, y);
    }
    wave..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(wave, Paint()..color = color.withValues(alpha: .85));
  }

  @override
  bool shouldRepaint(_LiquidContextPainter old) => old.usage != usage || old.phase != phase || old.color != color;
}
