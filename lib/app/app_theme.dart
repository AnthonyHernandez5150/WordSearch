import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildAppTheme() {
  const ColorScheme scheme = ColorScheme.dark(
    primary: wtCyan,
    onPrimary: wtBackground,
    secondary: wtBlue,
    onSecondary: wtWhite,
    tertiary: wtPurple,
    onTertiary: wtWhite,
    surface: wtSurface,
    onSurface: wtWhite,
    error: Color(0xFFFF6B7A),
    onError: wtWhite,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'sans-serif',
    colorScheme: scheme,
    scaffoldBackgroundColor: wtBackground,
    canvasColor: wtBackground,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: wtSurfaceElevated,
      contentTextStyle: const TextStyle(color: wtWhite),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: wtWhite,
        foregroundColor: wtBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: wtWhite,
        side: const BorderSide(color: Color(0x55F5F7FB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: wtWhite.withValues(alpha: 0.08),
      hintStyle: const TextStyle(color: Color(0xA6F5F7FB)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x26F5F7FB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: wtCyan, width: 1.4),
      ),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        height: 0.98,
        color: wtWhite,
      ),
      headlineMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.0,
        color: wtWhite,
      ),
      headlineSmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: wtWhite,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: wtWhite,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: wtWhite,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: wtTextMuted),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: wtTextMuted),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        color: Color(0x99F5F7FB),
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: wtWhite,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: wtTextMuted,
      ),
    ),
  );
}
