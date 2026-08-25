import 'package:flutter/material.dart';

/// Librio App Theme with Fredoka font and official gradient colors
class LibrioTheme {
  // Font family
  static const String font = 'Fredoka';

  // Colors
  static const Color deepPurple = Color(0xFF7B2CBF);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color brightBlue = Color(0xFF3B82F6);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color softWhite = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color deepNavy = Color(0xFF1E293B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [deepPurple, indigo, brightBlue, cyan],
    stops: [0.0, 0.33, 0.66, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [deepPurple, cyan],
  );

  static const LinearGradient diagonalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepPurple, cyan],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [softWhite, white],
  );

  /// Get the light theme with Fredoka font
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      // Primary color
      primaryColor: deepPurple,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: deepPurple,
        secondary: cyan,
        surface: white,
        onSurface: deepNavy,
        error: Colors.red,
      ),

      // Text theme with Fredoka
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(fontFamily: font),
        displayMedium: base.textTheme.displayMedium?.copyWith(fontFamily: font),
        displaySmall: base.textTheme.displaySmall?.copyWith(fontFamily: font),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(fontFamily: font),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(fontFamily: font),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontFamily: font),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontFamily: font),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontFamily: font),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontFamily: font),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontFamily: font),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontFamily: font),
        bodySmall: base.textTheme.bodySmall?.copyWith(fontFamily: font),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontFamily: font),
        labelMedium: base.textTheme.labelMedium?.copyWith(fontFamily: font),
        labelSmall: base.textTheme.labelSmall?.copyWith(fontFamily: font),
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        iconTheme: IconThemeData(color: white),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepPurple,
          foregroundColor: white,
          textStyle: const TextStyle(
            fontFamily: font,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: deepPurple,
          textStyle: const TextStyle(
            fontFamily: font,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: deepPurple, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: font,
          fontSize: 14,
          color: Colors.grey,
        ),
        hintStyle: const TextStyle(
          fontFamily: font,
          fontSize: 14,
          color: Colors.grey,
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100]!,
        labelStyle: const TextStyle(
          fontFamily: font,
          fontSize: 14,
          color: deepNavy,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Dialog theme
      dialogTheme: const DialogThemeData(
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: deepNavy,
        ),
        contentTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 16,
          color: deepNavy,
        ),
      ),

      // Scaffold background
      scaffoldBackgroundColor: white,
    );
  }

  /// Get the dark theme with Fredoka font
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      // Primary color
      primaryColor: deepPurple,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: deepPurple,
        secondary: cyan,
        surface: Color(0xFF1E1E2E),
        onSurface: Color(0xFFE0E0E0),
        error: Colors.red,
      ),

      // Text theme with Fredoka
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(fontFamily: font, color: Colors.white),
        displayMedium: base.textTheme.displayMedium?.copyWith(fontFamily: font, color: Colors.white),
        displaySmall: base.textTheme.displaySmall?.copyWith(fontFamily: font, color: Colors.white),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(fontFamily: font, color: Colors.white),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(fontFamily: font, color: Colors.white),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontFamily: font, color: Colors.white),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontFamily: font, color: Colors.white),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontFamily: font, color: Colors.white),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontFamily: font, color: Colors.white),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontFamily: font, color: Colors.white),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontFamily: font, color: Colors.white),
        bodySmall: base.textTheme.bodySmall?.copyWith(fontFamily: font, color: Colors.white),
        labelLarge: base.textTheme.labelLarge?.copyWith(fontFamily: font, color: Colors.white),
        labelMedium: base.textTheme.labelMedium?.copyWith(fontFamily: font, color: Colors.white),
        labelSmall: base.textTheme.labelSmall?.copyWith(fontFamily: font, color: Colors.white),
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF2A2A3E),
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepPurple,
          foregroundColor: white,
          textStyle: const TextStyle(
            fontFamily: font,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cyan,
          textStyle: const TextStyle(
            fontFamily: font,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cyan, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: font,
          fontSize: 14,
          color: Colors.grey,
        ),
        hintStyle: const TextStyle(
          fontFamily: font,
          fontSize: 14,
          color: Colors.grey,
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[800]!,
        labelStyle: const TextStyle(
          fontFamily: font,
          fontSize: 14,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Dialog theme
      dialogTheme: const DialogThemeData(
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        contentTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 16,
          color: Colors.white,
        ),
      ),

      // Scaffold background
      scaffoldBackgroundColor: const Color(0xFF1E1E2E),
    );
  }

  /// Get Fredoka text style with custom properties
  static TextStyle fredokaStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = deepNavy,
    double letterSpacing = 0,
    double height = 1.5,
  }) {
    return TextStyle(
      fontFamily: font,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Get Fredoka heading style
  static TextStyle fredokaHeading({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.bold,
    Color color = deepNavy,
  }) {
    return TextStyle(
      fontFamily: font,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Get Fredoka body style
  static TextStyle fredokaBody({
    double fontSize = 14,
    Color color = deepNavy,
  }) {
    return TextStyle(
      fontFamily: font,
      fontSize: fontSize,
      color: color,
    );
  }

  /// Get Fredoka button style
  static TextStyle fredokaButton({
    double fontSize = 16,
    Color color = white,
  }) {
    return TextStyle(
      fontFamily: font,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}
