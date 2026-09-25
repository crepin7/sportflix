import 'package:flutter/material.dart';

class AppTheme {
  // Vert électrique / sportif
  static const Color primary = Color(0xFF00E676);
  static const Color background = Color(0xFF0A0E0A);
  static const Color surface = Color(0xFF141A14);
  static const Color surfaceLight = Color(0xFF1F2A1F);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9DB39D);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          onPrimary: Colors.black,
          secondary: primary,
          surface: surface,
          onSurface: textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceLight,
          selectedColor: primary,
          labelStyle: const TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
}
