import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF56ab2f);
  static const secondary = Color(0xFFFFC42A);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const lightGreen1 = Color(0xFFB8F5E7);
  static const lightGreen2 = Color(0xFFB8F5C2);

  // Dark mode colors
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkPrimary = Color(0xFF4CAF50);
  static const darkSecondary = Color(0xFFFFB74D);
  static const darkText = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFB3B3B3);

  static const background = white;
  static const textDark = primary;
  static const textLight = white;
  static const accent = secondary;

  // Theme-aware colors
  static Color getBackgroundColor(bool isDark) {
    return isDark ? darkBackground : white;
  }

  static Color getSurfaceColor(bool isDark) {
    return isDark ? darkSurface : white;
  }

  static Color getTextColor(bool isDark) {
    return isDark ? darkText : black;
  }

  static Color getTextSecondaryColor(bool isDark) {
    return isDark ? darkTextSecondary : black.withOpacity(0.6);
  }

  static Color getPrimaryColor(bool isDark) {
    return isDark ? darkPrimary : primary;
  }

  static Color getSecondaryColor(bool isDark) {
    return isDark ? darkSecondary : secondary;
  }
}
