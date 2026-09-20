import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const ink = Color(0xFF172126),
      primary = Color(0xFFF26B38),
      surface = Color(0xFFF5F3EF);
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
    ),
    scaffoldBackgroundColor: const Color(0xFFFBFAF8),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: ink),
      headlineSmall: TextStyle(fontWeight: FontWeight.w700, color: ink),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );
}
