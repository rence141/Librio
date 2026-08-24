import 'package:flutter/material.dart';

/// Animated intro splash screen shown when the app opens.
///
/// Animation sequence:
/// 1. Logo scales up from 0 with a bounce effect
/// 2. "Libro" text fades in below
/// 3. Tagline fades in
/// 4. Crystal loader appears
/// 5. After ~2.5s, transitions to the next screen
class IntroSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const IntroSplashScreen({super.key, required this.onComplete});

  @override
  State<IntroSplashScreen> createState() => _IntroSplashScreenState();
}

class _IntroSplashScreenState extends State<IntroSplashScreen>
    with TickerProviderStateMixin {
  static const Color _deepPurple = Color(0xFF7B2CBF);
  static const Color _cyan = Color(0xFF06B6D4);

  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Logo animation: scale + fade in with bounce
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Text animation: fade + slide up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });

    // Navigate after animation completes
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_deepPurple, _cyan],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _deepPurple.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text(
                        'L',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // App name + tagline (fade + slide)
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [_deepPurple, _cyan],
                      ).createShader(bounds),
                      child: const Text(
                        'Librio',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your AI study companion',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 15,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Subtle loading dots
            FadeTransition(
              opacity: _textOpacity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => _LoadingDot(
                  delay: i * 200,
                  color: i == 0 ? _deepPurple : (i == 1 ? const Color(0xFF4F46E5) : _cyan),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single pulsing dot for the loading indicator.
class _LoadingDot extends StatefulWidget {
  final int delay;
  final Color color;

  const _LoadingDot({required this.delay, required this.color});

  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8 + (_controller.value * 4),
          height: 8 + (_controller.value * 4),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.4 + _controller.value * 0.6),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
