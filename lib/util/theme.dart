import 'package:flutter/material.dart';

/// Shared design tokens so the UI stays consistent.
class AppTheme {
  static const primary = Color(0xFF2563EB); // indigo-blue
  static const primaryDark = Color(0xFF1D4ED8);
  static const bg = Color(0xFFF7F8FA);
  static const surface = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: 'Inter',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 600),
        showDuration: const Duration(milliseconds: 1500),
        preferBelow: true,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF111827).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF111827),
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}
