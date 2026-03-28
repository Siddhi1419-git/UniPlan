import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors (vibrant, modern)
  static const Color _lightPrimaryColor = Color(0xFF6750A4); // Deep purple (M3)
  static const Color _lightSecondaryColor = Color(0xFF00BFA6); // Teal accent
  static const Color _lightBackgroundColor = Color(0xFFF4F0FF); // Soft purple tint
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _lightErrorColor = Color(0xFFB3261E);

  // Dark Theme Colors
  static const Color _darkPrimaryColor = Color(0xFFCFBCFF); // Lighter purple
  static const Color _darkSecondaryColor = Color(0xFF66FFF5); // Teal accent
  static const Color _darkBackgroundColor = Color(0xFF141218);
  static const Color _darkSurfaceColor = Color(0xFF1D1B20);
  static const Color _darkErrorColor = Color(0xFFF2B8B5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _lightPrimaryColor,
        secondary: _lightSecondaryColor,
        background: _lightBackgroundColor,
        surface: _lightSurfaceColor,
        error: _lightErrorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.black87,
        onSurface: Colors.black87,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: _lightBackgroundColor,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _lightPrimaryColor,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: _lightSurfaceColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _darkPrimaryColor,
        secondary: _darkSecondaryColor,
        background: _darkBackgroundColor,
        surface: _darkSurfaceColor,
        error: _darkErrorColor,
        onPrimary: Colors.black87,
        onSecondary: Colors.black87,
        onBackground: Colors.white,
        onSurface: Colors.white,
        onError: Colors.black87,
      ),
      scaffoldBackgroundColor: _darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _darkSurfaceColor,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: _darkSurfaceColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _darkSurfaceColor,
      ),
    );
  }
}
