import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Crystal loader — animated "thinking" indicator.
///
/// 6 crystals positioned around a ring, each pulsing with staggered
/// blue gradients. The whole ring rotates smoothly.
class CrystalLoader extends StatefulWidget {
  final double size;
  const CrystalLoader({super.key, this.size = 64});

  @override
  State<CrystalLoader> createState() => _CrystalLoaderState();
}

class _CrystalLoaderState extends State<CrystalLoader>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;

  static const _gradients = [
    [Color(0xFF003366), Color(0xFF336699)],
    [Color(0xFF003399), Color(0xFF3366CC)],
    [Color(0xFF0066CC), Color(0xFF3399FF)],
    [Color(0xFF0099FF), Color(0xFF66CCFF)],
    [Color(0xFF33CCFF), Color(0xFF99CCFF)],
    [Color(0xFF66FFFF), Color(0xFFCCFFFF)],
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crystalSize = widget.size * 0.18;
    final radius = widget.size * 0.32;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _spinController,
        builder: (context, _) {
          final spinAngle = _spinController.value * 2 * math.pi;
          return Stack(
            alignment: Alignment.center,
            children: List.generate(6, (i) {
              // Position each crystal at a different angle around the ring
              final angle = (i / 6) * 2 * math.pi + spinAngle;
              final x = radius * math.cos(angle);
              final y = radius * math.sin(angle);

              return Transform.translate(
                offset: Offset(x, y),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    // Stagger pulse phase per crystal
                    final phase = (_pulseController.value + i / 6) % 1.0;
                    final pulse = 0.7 + 0.3 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));
                    final opacity = 0.5 + 0.5 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi));

                    return Opacity(
                      opacity: opacity.clamp(0.3, 1.0),
                      child: Transform.scale(
                        scale: pulse,
                        child: Container(
                          width: crystalSize,
                          height: crystalSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(crystalSize * 0.3),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _gradients[i],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _gradients[i][1].withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
