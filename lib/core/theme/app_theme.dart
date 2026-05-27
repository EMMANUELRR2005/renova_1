import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primarios
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D2B4E);
  static const Color primaryLight = Color(0xFFE8F0FE);

  // Clínicos
  static const Color clinicalGreen = Color(0xFF00695C);
  static const Color clinicalGreenBg = Color(0xFFE0F2F1);

  // Estados
  static const Color danger = Color(0xFFC62828);
  static const Color dangerBg = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFE65100);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color success = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color neutral = Color(0xFF455A64);
  static const Color neutralBg = Color(0xFFECEFF1);

  // Fondos
  static const Color bgGeneral = Color(0xFFF5F7FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E4EA);

  // Sidebar y Topbar
  static const Color sidebar = Color(0xFF0D2B4E);
  static const Color topbar = Color(0xFFFFFFFF);

  // Grises
  static const Color textPrimary = Color(0xFF0D2B4E);
  static const Color textSecondary = Color(0xFF455A64);
  static const Color textTertiary = Color(0xFF90CAF9);
  static const Color textDisabled = Color(0xFFCFD8DC);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.clinicalGreen,
        surface: AppColors.bgGeneral,
        error: AppColors.danger,
      ),
      fontFamily: GoogleFonts.dmSans().fontFamily,
    );

    return baseTheme.copyWith(
      // TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          fontFamily: GoogleFonts.dmSans().fontFamily,
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textDisabled,
          fontFamily: GoogleFonts.dmSans().fontFamily,
        ),
      ),
      // Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: GoogleFonts.dmSans().fontFamily,
          ),
        ),
      ),
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.topbar,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.08),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: GoogleFonts.dmSans().fontFamily,
        ),
      ),
      // Scaffold
      scaffoldBackgroundColor: AppColors.bgGeneral,
    );
  }
}

// Extensiones para TextStyle
extension TextStyleExtension on TextStyle {
  TextStyle get display => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: GoogleFonts.dmSans().fontFamily,
      );

  TextStyle get subtitle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: GoogleFonts.dmSans().fontFamily,
      );

  TextStyle get label => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontFamily: GoogleFonts.dmSans().fontFamily,
      );

  TextStyle get body => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFamily: GoogleFonts.dmSans().fontFamily,
      );

  TextStyle get caption => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: GoogleFonts.dmSans().fontFamily,
      );
}
