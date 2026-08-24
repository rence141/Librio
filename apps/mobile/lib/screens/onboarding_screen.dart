import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding screen shown to first-time users.
///
/// Introduces Libro's key features in 3 swipeable pages:
/// 1. AI Tutor — Ask anything, get help studying
/// 2. Offline First — Works without internet
/// 3. Study Tools — Flashcards, quizzes, materials
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();

  /// Check if onboarding has been completed before.
  static Future<bool> hasCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }

  /// Mark onboarding as complete.
  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color _deepPurple = Color(0xFF7B2CBF);

  final _pages = [
    _OnboardingPage(
      icon: Icons.psychology,
      title: 'Ask Anything',
      subtitle: 'Libro is your AI study companion. Ask questions, get explanations, and learn faster.',
      gradient: const [Color(0xFF7B2CBF), Color(0xFF4F46E5)],
    ),
    _OnboardingPage(
      icon: Icons.cloud_off,
      title: 'Works Offline',
      subtitle: 'No internet? No problem. Libro runs a local AI model right on your device.',
      gradient: const [Color(0xFF4F46E5), Color(0xFF3B82F6)],
    ),
    _OnboardingPage(
      icon: Icons.school,
      title: 'Study Smarter',
      subtitle: 'Generate flashcards, take quizzes, and use your own materials for context-aware answers.',
      gradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingScreen.markComplete();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page, index);
                },
              ),
            ),
            // Dots + button
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
              child: Column(
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? _deepPurple : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  // Next / Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finish();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                        style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: page.gradient,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: page.gradient[0].withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 15,
              height: 1.5,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Data model for a single onboarding page.
class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
