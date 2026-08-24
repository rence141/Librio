import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A compact rounded-square context meter with gradient progress border.
/// 
/// The border itself represents context usage (0-100%), flowing clockwise
/// around the perimeter. The center displays the percentage.
/// 
/// Features:
/// - Smooth gradient progress stroke (Librio theme colors)
/// - Rounded corners integrated into the progress path
/// - Clockwise progress animation
/// - Compact 44x44 size
/// - Subtle inactive border
class ContextMeter extends StatefulWidget {
  final double usage; // 0.0 to 1.0
  final Duration animationDuration;
  final VoidCallback? onTap;
  final String? tooltip;

  const ContextMeter({
    Key? key,
    required this.usage,
    this.animationDuration = const Duration(milliseconds: 400),
    this.onTap,
    this.tooltip,
  }) : super(key: key);

  @override
  State<ContextMeter> createState() => _ContextMeterState();
}

class _ContextMeterState extends State<ContextMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _previousUsage;

  @override
  void initState() {
    super.initState();
    _previousUsage = widget.usage;
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _setupAnimation();
  }

  void _setupAnimation() {
    _animation = Tween<double>(
      begin: _previousUsage,
      end: widget.usage,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ContextMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usage != widget.usage) {
      _previousUsage = _animation.value;
      _setupAnimation();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip ?? 'Context: ${(widget.usage * 100).toStringAsFixed(0)}%',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(44, 44),
              painter: _ContextMeterPainter(
                progress: _animation.value,
              ),
              child: Center(
                child: Text(
                  '${(_animation.value * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContextMeterPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _ContextMeterPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;

    // Padding from edges
    const padding = 3.0;
    final left = padding;
    final top = padding;
    final right = width - padding;
    final bottom = height - padding;

    // Corner radius
    const cornerRadius = 6.0;

    // Create the rounded rectangle path
    final roundedRect = RRect.fromLTRBR(
      left,
      top,
      right,
      bottom,
      const Radius.circular(cornerRadius),
    );

    // Inactive border (subtle background)
    final inactivePaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(roundedRect, inactivePaint);

    // Calculate the perimeter length
    final perimeter = _calculateRoundedRectPerimeter(
      width - padding * 2,
      height - padding * 2,
      cornerRadius,
    );

    // Calculate how much of the perimeter to draw based on progress
    final progressLength = perimeter * progress;

    // Draw the active progress border with gradient
    _drawProgressBorder(
      canvas,
      left,
      top,
      right,
      bottom,
      cornerRadius,
      progressLength,
      perimeter,
    );
  }

  /// Calculate the perimeter of a rounded rectangle
  double _calculateRoundedRectPerimeter(
    double width,
    double height,
    double radius,
  ) {
    // Perimeter = 2 * (width + height - 4*radius + π*radius)
    // Simplified: 2 * (width + height) - 8*radius + 2*π*radius
    final straightParts = 2 * (width + height - 2 * radius);
    final curvedParts = 2 * math.pi * radius;
    return straightParts + curvedParts;
  }

  /// Draw the progress border with gradient, following the rounded rectangle path
  void _drawProgressBorder(
    Canvas canvas,
    double left,
    double top,
    double right,
    double bottom,
    double radius,
    double progressLength,
    double totalPerimeter,
  ) {
    // Create gradient paint
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF7B2CBF), // Deep purple
          const Color(0xFF06B6D4), // Cyan
        ],
      ).createShader(Rect.fromLTWH(left, top, right - left, bottom - top))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Build the path for the rounded rectangle border
    final path = Path();

    // We'll trace the border clockwise starting from top-left corner
    // Top-left corner (arc)
    path.moveTo(left + radius, top);

    // Top edge
    path.lineTo(right - radius, top);

    // Top-right corner (arc)
    path.arcToPoint(
      Offset(right, top + radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Right edge
    path.lineTo(right, bottom - radius);

    // Bottom-right corner (arc)
    path.arcToPoint(
      Offset(right - radius, bottom),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Bottom edge
    path.lineTo(left + radius, bottom);

    // Bottom-left corner (arc)
    path.arcToPoint(
      Offset(left, bottom - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Left edge
    path.lineTo(left, top + radius);

    // Top-left corner (arc)
    path.arcToPoint(
      Offset(left + radius, top),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Use PathMetrics to draw only the progress portion
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0, progressLength);
      canvas.drawPath(extractPath, gradientPaint);
    }
  }

  @override
  bool shouldRepaint(_ContextMeterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
