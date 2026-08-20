import 'package:flutter/material.dart';
import 'benchmark_screen.dart';

void main() {
  runApp(const LibrioApp());
}

class LibrioApp extends StatelessWidget {
  const LibrioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Librio Phase 0',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const BenchmarkScreen(),
    );
  }
}
