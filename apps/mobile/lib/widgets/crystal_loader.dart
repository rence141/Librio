import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Crystal loader.
///
/// 6 crystals at center, each with:
/// - spin: rotateZ 0→360deg over 4s (with rotateX(45deg) fixed)
/// - emerge: scale 0.5→1→0.5 + opacity 0→1→0 over 2s (alternate)
/// - staggered delays: 0s, 0.3s, 0.6s, 0.9s, 1.2s, 1.5s
class CrystalLoader extends StatefulWidget {
  final double size;
  const CrystalLoader({super.key, this.size = 100});

  @override
  State<CrystalLoader> createState() => _CrystalLoaderState();
}

class _CrystalLoaderState extends State<CrystalLoader>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _emergeController;

  static const _gradients = [
    [Color(0xFF003366), Color(0xFF336699)],
    [Color(0xFF003399), Color(0xFF3366CC)],
    [Color(0xFF0066CC), Color(0xFF3399FF)],
    [Color(0xFF0099FF), Color(0xFF66CCFF)],
    [Color(0xFF33CCFF), Color(0xFF99CCFF)],
    [Color(0xFF66FFFF), Color(0xFFCCFFFF)],
  ];
  // Staggered delays in seconds (matches CSS animation-delay)
  static const _delays = [0.0, 0.3, 0.6, 0.9, 1.2, 1.5];

  @override
  void initState() {
    super.initState();
    // spin: 4s linear infinite
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    // emerge: 2s ease-in-out infinite alternate
    _emergeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _emergeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CSS: container 200px, crystal 60px → crystal is 30% of container
    final crystalSize = widget.size * 0.3;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(6, (i) {
          return AnimatedBuilder(
            animation: Listenable.merge([_spinController, _emergeController]),
            builder: (context, _) {
              // spin: rotateZ 0→360deg
              final spinAngle = _spinController.value * 2 * math.pi;

              // emerge: staggered phase per crystal
              // CSS delay shifts the animation timeline for each crystal
              final emergeDuration = 2.0; // seconds
              final delay = _delays[i];
              // Calculate effective phase with delay offset
              final elapsed = (_emergeController.lastElapsedDuration?.inMilliseconds ?? 0) / 1000.0;
              final phaseTime = (elapsed + delay) % (emergeDuration * 2);
              final normalized = phaseTime / emergeDuration;
              // alternate: 0→1→0 pattern
              final emergeValue = normalized < 1.0 ? normalized : (2.0 - normalized);

              // scale: 0.5 at 0% and 100%, 1.0 at 50%
              final scale = 0.5 + 0.5 * emergeValue;
              // opacity: 0 at 0% and 100%, 1.0 at 50%, capped at 0.8
              final opacity = (emergeValue * 0.8).clamp(0.0, 0.8);

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.00125) // perspective: 800px
                      ..rotateX(math.pi / 4) // rotateX(45deg)
                      ..rotateZ(spinAngle), // rotateZ(spin)
                    child: Container(
                      width: crystalSize,
                      height: crystalSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _gradients[i],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
