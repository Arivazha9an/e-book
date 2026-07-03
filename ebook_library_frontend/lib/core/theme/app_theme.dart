import 'package:flutter/material.dart';

/// A warm, "wood and paper" palette that fits a bookshelf-style library
/// rather than a generic Material blue app.
class AppTheme {
  const AppTheme._();

  static const Color _walnut = Color(0xFF6B4226);
  static const Color _parchment = Color(0xFFFAF6F0);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _walnut,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _parchment,
      appBarTheme: const AppBarTheme(
        backgroundColor: _parchment,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _walnut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
