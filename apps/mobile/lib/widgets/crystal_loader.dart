import 'package:flutter/material.dart';

/// Crystal loader — animated "thinking" indicator.
///
/// Ported from Uiverse.io Z4drus CSS design: 6 rotating crystals with
/// staggered blue gradients that emerge and spin in 3D perspective.
class CrystalLoader extends StatefulWidget {
  final double size;
  const CrystalLoader({super.key, this.size = 80});

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
  static const _delays = [0.0, 0.3, 0.6, 0.9, 1.2, 1.5];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
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
              final spinAngle = _spinController.value * 2 * 3.14159265;
              // Staggered emerge: offset each crystal's phase
              final phase = (_emergeController.value + _delays[i] / 2.0) % 1.0;
              final scaleVal = 0.5 + 0.5 * (1 - (2 * phase - 1).abs());
              final opacityVal = (1 - (2 * phase - 1).abs()) * 0.8;

              return Transform.scale(
                scale: scaleVal.clamp(0.3, 1.0),
                child: Opacity(
                  opacity: opacityVal.clamp(0.0, 0.8),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.003) // perspective
                      ..rotateX(0.785) // 45deg
                      ..rotateZ(spinAngle),
                    child: Container(
                      width: crystalSize,
                      height: crystalSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
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
