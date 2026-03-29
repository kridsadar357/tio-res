import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Helper method to get appropriate font based on locale
  static TextTheme _getTextTheme(Locale? locale) {
    // Use Sarabun for Thai, Poppins for English and others
    if (locale?.languageCode == 'th') {
      return GoogleFonts.sarabunTextTheme();
    } else {
      return GoogleFonts.poppinsTextTheme();
    }
  }

  // Helper method to get font for specific text style
  static TextStyle _getTextStyle(Locale? locale, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    if (locale?.languageCode == 'th') {
      return GoogleFonts.sarabun(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } else {
      return GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }
  // Premium Dark Palette
  static const Color background = Color.fromARGB(255, 64, 69, 81); // Deep Navy
  static const Color surface =
      Color.fromARGB(255, 47, 49, 54); // Translucent Surface Base
  static const Color primary = Color(0xFF6C5DD3); // Royal Purple
  static const Color accent = Color(0xFF00E096); // Vibrant Mint

  // Status Colors (Neon / High Contrast)
  static const Color statusAvailable =
      Color.fromARGB(255, 123, 255, 211); // Neon Cyan/Green
  static const Color statusOccupied =
      Color(0xFFFF4757); // Hot Pink / Burnt Orange
  static const Color statusCleaning = Color(0xFFFFA500); // Amber/Orange

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8F90A6);

  // Popular Modern Palette (Light) remains for fallback/toggle
  static const Color primaryLight = Color(0xFF2962FF);
  static const Color surfaceLight = Color(0xFFF5F7FA);
  static const Color backgroundLight = Colors.white;
  static const Color textMainLight = Color(0xFF1D1D35);

  static ThemeData lightTheme([Locale? locale]) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryLight,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surfaceLight,
      colorScheme: colorScheme.copyWith(
        onSurface: textMainLight,
        onBackground: textMainLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
      ),
      textTheme: _getTextTheme(locale).apply(
        bodyColor: textMainLight,
        displayColor: textMainLight,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textMainLight),
        titleTextStyle: _getTextStyle(locale,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textMainLight,
        ),
        shape: const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
    );
  }

  static ThemeData darkTheme([Locale? locale]) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: const Color.fromARGB(255, 217, 192, 49),

      // Use Sarabun for Thai, Poppins for English
      textTheme: _getTextTheme(locale).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      // Card Theme - Glass-like foundation
      cardTheme: CardThemeData(
        color:
            surface.withValues(alpha: 0.7), // Semi-transparent for glass effect
        elevation: 10,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side:
              BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Transparent for seamless feel
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _getTextStyle(locale,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: Color.fromARGB(255, 132, 178, 252),
        secondary: Color.fromARGB(255, 66, 239, 182),
        surface: surface,
        error: statusOccupied,
      ),

      dividerColor: Colors.white.withValues(alpha: 0.1),
    );
  }
}
