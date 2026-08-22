import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Librio App Theme with Fredoka font and official gradient colors
class LibrioTheme {
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
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
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
      textTheme: GoogleFonts.fredokaTextTheme(
        ThemeData.light().textTheme,
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        iconTheme: const IconThemeData(color: white),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepPurple,
          foregroundColor: white,
          textStyle: GoogleFonts.fredoka(
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
          textStyle: GoogleFonts.fredoka(
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
        labelStyle: GoogleFonts.fredoka(
          fontSize: 14,
          color: Colors.grey[600],
        ),
        hintStyle: GoogleFonts.fredoka(
          fontSize: 14,
          color: Colors.grey[400],
        ),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100]!,
        labelStyle: GoogleFonts.fredoka(
          fontSize: 14,
          color: deepNavy,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: deepNavy,
        ),
        contentTextStyle: GoogleFonts.fredoka(
          fontSize: 16,
          color: deepNavy,
        ),
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: white,
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
    return GoogleFonts.fredoka(
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
    return GoogleFonts.fredoka(
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
    return GoogleFonts.fredoka(
      fontSize: fontSize,
      color: color,
    );
  }

  /// Get Fredoka button style
  static TextStyle fredokaButton({
    double fontSize = 16,
    Color color = white,
  }) {
    return GoogleFonts.fredoka(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}
