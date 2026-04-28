import 'package:flutter/material.dart';

class AppTheme {
  static const _teal = Color(0xFF0F6E56);
  static const _tealLight = Color(0xFFE1F5EE);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _teal,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _tealLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _teal,
            );
          }
          return const TextStyle(fontSize: 12);
        }),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _teal,
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }
}
