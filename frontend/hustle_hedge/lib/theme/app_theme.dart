import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF1A7A7A); // dark cyan
  static const Color secondaryLight = Color(0xFF2AA8A8);
  static const Color secondaryMuted = Color(0xFFE8F5F5);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF555555);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color surface = Color(0xFFF7FAFA);
  static const Color divider = Color(0xFFE0EEEE);
  static const Color error = Color(0xFFD32F2F);

  // Typography
  static const String fontFamily = 'Poppins';

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        colorScheme: const ColorScheme.light(
          primary: secondary,
          secondary: secondaryLight,
          surface: primary,
          onPrimary: primary,
          onSurface: textPrimary,
        ),
        scaffoldBackgroundColor: primary,
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: secondary,
            foregroundColor: primary,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: secondary,
            minimumSize: const Size(double.infinity, 54),
            side: const BorderSide(color: secondary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: secondary, width: 1.8),
          ),
          hintStyle: const TextStyle(
            color: textHint,
            fontSize: 15,
            fontFamily: fontFamily,
          ),
          labelStyle: const TextStyle(
            color: textSecondary,
            fontSize: 14,
            fontFamily: fontFamily,
          ),
        ),
      );
}