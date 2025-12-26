import 'package:flutter/material.dart';
import 'app_text.dart';

class AppTheme {
  static ThemeData light() {
    const baseBackground = Color(0xFFE0E5EC);
    const accent = Color(0xFF64B5F6);
    return ThemeData(
      scaffoldBackgroundColor: baseBackground,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: Color(0xFF42A5F5),
        // Purple accent to match the landing background palette.
        tertiary: Color(0xFF8B7CFF),
        surface: baseBackground,
        background: baseBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF2C3E50),
        onBackground: Color(0xFF2C3E50),
      ),
      useMaterial3: true,
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: const Color(0xFF2C3E50),
            displayColor: const Color(0xFF2C3E50),
          ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: baseBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: accent,
          foregroundColor: Colors.white,
          textStyle: AppText.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const background = Color(0xFF040C18);
    const surface = Color(0xFF111A2E);
    const primary = Color(0xFF6AC1FF);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFFFFA26B),
        tertiary: Color(0xFF8B7CFF),
        surface: surface,
        background: background,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      useMaterial3: true,
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
      cardTheme: CardTheme(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: AppText.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
