import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A compact liquid fill indicator contained within a horizontal rounded-rectangle bar.
///
/// The liquid is clipped to the exact same rounded-rectangle shape as the parent bar,
/// so it follows the container's inner silhouette at every fill level.
class LiquidContextIndicator extends StatefulWidget {
  final double usage;
  final VoidCallback? onTap;

  const LiquidContextIndicator({super.key, required this.usage, this.onTap});

  @override
  State<LiquidContextIndicator> createState() => _LiquidContextIndicatorState();
}

class _LiquidContextIndicatorState extends State<LiquidContextIndicator>
    with SingleTickerProviderStateMixin {
  static const _height = 7.0;
  static const _width = 46.0;

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
    final borderRadius = BorderRadius.circular(_height / 2);

    return Semantics(
      label: 'Context ${(usage * 100).round()} percent used',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: _width,
          height: _height,
          // The container: a horizontal rounded-rectangle bar.
          // This is the clipping boundary — everything inside is clipped to this shape.
          child: ClipRRect(
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background tint
                ColoredBox(color: color.withValues(alpha: 0.15)),
                // Liquid fill — fills the entire ClipRRect area; painter clips itself
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _wave,
                    builder: (context, _) {
                      return CustomPaint(
                        // No explicit size — fills the Stack (which fills the ClipRRect)
                        painter: _LiquidContextPainter(
                          usage: usage,
                          phase: _wave.value,
                          color: color,
                          borderRadius: borderRadius,
                        ),
                      );
                    },
                  ),
                ),
              ],
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
  final BorderRadius borderRadius;

  const _LiquidContextPainter({
    required this.usage,
    required this.phase,
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Build the exact same RRect as the parent ClipRRect.
    // This is the container's inner silhouette.
    final rrect = borderRadius.toRRect(Offset.zero & size);

    // Clip to the container shape — liquid can never draw outside it.
    canvas.clipRRect(rrect);

    // The fill level: 0% = empty (bottom), 100% = full (top).
    final fillHeight = size.height * usage;
    final topY = size.height - fillHeight;

    // Build the liquid path: wavy top edge, then fill down to bottom corners.
    final liquid = Path()..moveTo(0, topY);
    for (double x = 0; x <= size.width; x += 1) {
      final y = topY + math.sin((x / size.width * math.pi * 2) + phase * math.pi * 2) * 0.8;
      liquid.lineTo(x, y);
    }
    liquid
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Draw the liquid — it's already clipped to the rounded container.
    canvas.drawPath(liquid, Paint()..color = color.withValues(alpha: 0.85));

    // Draw a subtle highlight line on the wave crest.
    final crest = Path()..moveTo(0, topY);
    for (double x = 0; x <= size.width; x += 1) {
      final y = topY + math.sin((x / size.width * math.pi * 2) + phase * math.pi * 2) * 0.8;
      crest.lineTo(x, y);
    }
    canvas.drawPath(
      crest,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(_LiquidContextPainter old) =>
      old.usage != usage || old.phase != phase || old.color != color;
}
