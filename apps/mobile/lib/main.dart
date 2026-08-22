import 'package:flutter/material.dart';
import 'services/model_loader.dart';
import 'services/token_manager.dart';
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
  
  runApp(LibrioApp(
    tokenManager: tokenManager,
    modelLoader: modelLoader,
  ));
}

class LibrioApp extends StatelessWidget {
  final TokenManager tokenManager;
  final ModelLoader modelLoader;
  
  const LibrioApp({
    super.key,
    required this.tokenManager,
    required this.modelLoader,
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
            );
          }
          
          return LoginScreen(tokenManager: tokenManager);
        },
      ),
      routes: {
        '/home': (context) => HomeScreen(
          tokenManager: tokenManager,
          modelLoader: modelLoader,
        ),
        '/login': (context) => LoginScreen(tokenManager: tokenManager),
        '/signup': (context) => SignupScreen(tokenManager: tokenManager),
      },
    );
  }
}
