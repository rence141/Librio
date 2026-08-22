import 'dart:ui';
import 'package:flutter/material.dart';
import 'services/model_loader.dart';
import 'services/llm_service.dart';
import 'screens/chat_screen.dart';
import 'theme/app_theme.dart';
import 'utils/debug_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize services
  DebugLogger.info('Main', 'Initializing model loader...');
  final modelLoader = ModelLoader();
  await modelLoader.loadModel();

  DebugLogger.info('Main', 'Initializing LLM service...');
  final llmService = LlmService();
  await llmService.initialize(modelLoader);

  DebugLogger.success('Main', 'All services initialized, launching app...');

  runApp(LibrioApp(
    modelLoader: modelLoader,
    llmService: llmService,
  ));
}

class LibrioApp extends StatelessWidget {
  final ModelLoader modelLoader;
  final LlmService llmService;

  const LibrioApp({
    super.key,
    required this.modelLoader,
    required this.llmService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Librio',
      theme: LibrioTheme.lightTheme,
      home: ChatScreen(llmService: llmService),
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
