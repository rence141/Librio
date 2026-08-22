import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'services/model_loader.dart';
import 'services/llm_service.dart';
import 'screens/chat_screen.dart';
import 'screens/intro_splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'utils/debug_logger.dart';

// Web database support
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Global error handler for Flutter framework errors
  FlutterError.onError = (details) {
    DebugLogger.error('FlutterError', details.exceptionAsString(), details.exception, details.stack);
  };

  // Global error handler for errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    DebugLogger.error('Platform', 'Uncaught error', error, stack);
    return true;
  };

  DebugLogger.info('Main', 'Starting Librio app...');

  // Initialize services in parallel with the intro splash
  DebugLogger.info('Main', 'Initializing model loader...');
  final modelLoader = ModelLoader();
  await modelLoader.loadModel();

  // Local LLM only works on native platforms (Android/iOS/desktop)
  // Web uses online models only
  final llmService = LlmService();
  if (!kIsWeb) {
    DebugLogger.info('Main', 'Initializing LLM service...');
    await llmService.initialize(modelLoader);
  }

  DebugLogger.success('Main', 'All services initialized, launching app...');

  // Check if onboarding is needed (defensive against null prefs)
  bool needsOnboarding = true;
  try {
    needsOnboarding = !await OnboardingScreen.hasCompleted();
  } catch (e) {
    DebugLogger.error('Main', 'Onboarding check failed, defaulting to show', e, null);
  }

  runApp(LibrioApp(
    modelLoader: modelLoader,
    llmService: llmService,
    needsOnboarding: needsOnboarding,
  ));
}

class LibrioApp extends StatelessWidget {
  final ModelLoader modelLoader;
  final LlmService llmService;
  final bool needsOnboarding;

  const LibrioApp({
    super.key,
    required this.modelLoader,
    required this.llmService,
    required this.needsOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Librio',
      theme: LibrioTheme.lightTheme,
      home: _AppEntry(
        llmService: llmService,
        needsOnboarding: needsOnboarding,
      ),
      builder: (context, widget) {
        // Catch widget build errors
        ErrorWidget.builder = (details) {
          DebugLogger.error('WidgetBuilder', 'Widget build error', details.exception, details.stack);
          return Material(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details.exception.toString(),
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        };
        return widget ?? const SizedBox.shrink();
      },
    );
  }
}

/// Entry widget that routes through intro splash → onboarding (if needed) → chat.
class _AppEntry extends StatefulWidget {
  final LlmService llmService;
  final bool needsOnboarding;

  const _AppEntry({
    required this.llmService,
    required this.needsOnboarding,
  });

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _showSplash = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.needsOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    // Step 1: Intro splash animation
    if (_showSplash) {
      return IntroSplashScreen(
        onComplete: () {
          setState(() => _showSplash = false);
        },
      );
    }

    // Step 2: Onboarding (first launch only)
    if (_showOnboarding) {
      return OnboardingScreen(
        onComplete: () {
          setState(() => _showOnboarding = false);
        },
      );
    }

    // Step 3: Main chat screen
    return ChatScreen(llmService: widget.llmService);
  }
}
