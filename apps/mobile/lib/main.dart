import 'package:flutter/material.dart';
import 'services/model_loader.dart';
import 'services/llm_service.dart';
import 'screens/splash_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final modelLoader = ModelLoader();
  await modelLoader.loadModel();
  
  final llmService = LlmService();
  await llmService.initialize(modelLoader);
  
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
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: modelLoader.isModelLoaded
          ? ChatScreen(llmService: llmService)
          : const SplashScreen(),
    );
  }
}
