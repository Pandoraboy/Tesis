import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const amarillo = Color(0xFFFFC107);
  static const negro = Color(0xFF121212);

  static final oscuro = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: negro,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: amarillo,
          brightness: Brightness.dark,
        ).copyWith(
          primary: amarillo,
          onPrimary: negro,
          secondary: amarillo,
          onSecondary: negro,
          surface: const Color(0xFF1E1E1E),
          onSurface: const Color(0xFFF5F5F5),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: negro,
      foregroundColor: amarillo,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      indicatorColor: amarillo,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: amarillo, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: amarillo,
        foregroundColor: negro,
        minimumSize: const Size(48, 48),
      ),
    ),
  );
}
