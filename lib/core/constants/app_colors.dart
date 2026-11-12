import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF090D18);
  static const Color surface = Color(0xFF141A2B);
  static const Color surfaceLight = Color(0xFF202941);
  static const Color surfaceElevated = Color(0xFF29334F);

  static const Color primary = Color(0xFF9B7BFF);
  static const Color primaryLight = Color(0xFFB9A4FF);
  static const Color primaryDark = Color(0xFF6F54D9);
  static const Color secondary = Color(0xFF64B5E8);
  static const Color secondaryDark = Color(0xFF387DAF);

  static const Color starGold = Color(0xFFFFD989);
  static const Color moonSilver = Color(0xFFE4E9F5);
  static const Color success = Color(0xFF55C9A2);
  static const Color warning = Color(0xFFF2B95F);
  static const Color error = Color(0xFFF07886);

  static const Color textPrimary = Color(0xFFF3F4FB);
  static const Color textSecondary = Color(0xFFADB6CA);
  static const Color textMuted = Color(0xFF7F8AA3);
  static const Color divider = Color(0xFF293149);

  static const LinearGradient nightSkyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10172A), background, Color(0xFF17152C)],
    stops: [0, 0.58, 1],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF202844), Color(0xFF151B2D)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFAA8BFF), Color(0xFF7564E8)],
  );

  static const LinearGradient sleepGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4D9BCB), Color(0xFF6862C9)],
  );

  static const LinearGradient dreamGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB36BE0), Color(0xFF795FE0)],
  );
}
