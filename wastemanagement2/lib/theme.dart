import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color secondaryColor = Color(0xFF8BC34A);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textColor = Color(0xFF333333);
  static const Color lightTextColor = Color(0xFF757575);

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: lightTextColor,
          fontSize: 14,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textTheme: ButtonTextTheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightTextColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}