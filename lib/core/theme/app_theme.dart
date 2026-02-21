import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF161B28); // Slightly lighter for cards
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF00D2FF);
  static const Color accent = Color(0xFFE8006A); // INHAUS Pink
  static const Color inhausPink = Color(0xFFE8006A);
  static const Color inhausPurple = Color(0xFF1A1423);
  
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Colors.white70;

  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666); // Darkened for better contrast on secondary text

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      
      // Text Theme using 'Outfit' for a modern, tech feel
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimaryDark,
        displayColor: textPrimaryDark,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surface.withValues(alpha: 0.6), // Translucent for glass effect
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1),
        ),
        hintStyle: const TextStyle(color: Colors.white30),
      ),
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primary,
      
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(color: textPrimaryLight),
        displayMedium: GoogleFonts.outfit(color: textPrimaryLight),
        displaySmall: GoogleFonts.outfit(color: textPrimaryLight),
        headlineLarge: GoogleFonts.outfit(color: textPrimaryLight),
        headlineMedium: GoogleFonts.outfit(color: textPrimaryLight),
        headlineSmall: GoogleFonts.outfit(color: textPrimaryLight),
        titleLarge: GoogleFonts.outfit(color: textPrimaryLight),
        titleMedium: GoogleFonts.outfit(color: textPrimaryLight),
        titleSmall: GoogleFonts.outfit(color: textPrimaryLight),
        bodyLarge: GoogleFonts.outfit(color: textPrimaryLight),
        bodyMedium: GoogleFonts.outfit(color: textPrimaryLight),
        bodySmall: GoogleFonts.outfit(color: textSecondaryLight),
        labelLarge: GoogleFonts.outfit(color: textPrimaryLight),
        labelSmall: GoogleFonts.outfit(color: textSecondaryLight),
      ),

      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1),
        ),
        labelStyle: const TextStyle(color: textPrimaryLight),
        hintStyle: const TextStyle(color: textSecondaryLight),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
