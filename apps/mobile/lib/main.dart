import 'package:flutter/material.dart';
import 'services/model_loader.dart';
import 'services/token_manager.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/content_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'benchmark_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final tokenManager = TokenManager();
  await tokenManager.initialize();
  
  final modelLoader = ModelLoader();
  await modelLoader.loadModel();
  
  final apiService = ApiService();
  await apiService.initialize(tokenManager);
  
  final authService = AuthService();
  await authService.initialize(apiService, tokenManager);
  
  final contentService = ContentService();
  await contentService.initialize(apiService);
  
  runApp(LibrioApp(
    tokenManager: tokenManager,
    modelLoader: modelLoader,
    apiService: apiService,
    authService: authService,
    contentService: contentService,
  ));
}

class LibrioApp extends StatelessWidget {
  final TokenManager tokenManager;
  final ModelLoader modelLoader;
  final ApiService apiService;
  final AuthService authService;
  final ContentService contentService;
  
  const LibrioApp({
    super.key,
    required this.tokenManager,
    required this.modelLoader,
    required this.apiService,
    required this.authService,
    required this.contentService,
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
      home: FutureBuilder<bool>(
        future: tokenManager.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          if (snapshot.hasData && snapshot.data == true) {
            return HomeScreen(
              tokenManager: tokenManager,
              modelLoader: modelLoader,
              contentService: contentService,
            );
          }
          
          return LoginScreen(
            tokenManager: tokenManager,
            authService: authService,
          );
        },
      ),
      routes: {
        '/home': (context) => HomeScreen(
          tokenManager: tokenManager,
          modelLoader: modelLoader,
          contentService: contentService,
        ),
        '/login': (context) => LoginScreen(
          tokenManager: tokenManager,
          authService: authService,
        ),
        '/signup': (context) => SignupScreen(
          tokenManager: tokenManager,
          authService: authService,
        ),
      },
    );
  }
}
