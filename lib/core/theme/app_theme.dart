import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primarios (sistema de diseño Renova)
  static const Color primary = Color(0xFF1E3A5F); // azul oscuro
  static const Color primaryDark = Color(0xFF0D2B4E); // sidebar
  static const Color primaryLight = Color(0xFFE8F0FE);
  static const Color accent = Color(0xFFC9A96E); // dorado

  // Clínicos
  static const Color clinicalGreen = Color(0xFF00695C);
  static const Color clinicalGreenBg = Color(0xFFE0F2F1);

  // Estados (paleta moderna)
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralBg = Color(0xFFF3F4F6);

  // Fondos
  static const Color bgGeneral = Color(0xFFF8F9FA); // surface
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);

  // Sidebar y Topbar
  static const Color sidebar = Color(0xFF0D2B4E);
  static const Color topbar = Color(0xFFFFFFFF);

  // Texto
  static const Color textPrimary = Color(0xFF1E3A5F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF90CAF9);
  static const Color textDisabled = Color(0xFFB0B7C3);
}

class AppTheme {
  static ThemeData get lightTheme {
    final fontFamily = GoogleFonts.dmSans().fontFamily;

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
        error: AppColors.danger,
      ),
      fontFamily: fontFamily,
    );

    OutlineInputBorder borde(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppColors.bgGeneral,

      // ── Campos de texto ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: borde(AppColors.border),
        enabledBorder: borde(AppColors.border),
        focusedBorder: borde(AppColors.primary, width: 2),
        errorBorder: borde(AppColors.danger),
        focusedErrorBorder: borde(AppColors.danger, width: 2),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIconColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
          fontFamily: fontFamily,
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textDisabled,
          fontFamily: fontFamily,
        ),
      ),

      // ── Botones primarios ────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),

      // ── Botones secundarios ──────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.topbar,
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontFamily: fontFamily,
        ),
      ),

      // ── Chips ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.bgGeneral,
        side: const BorderSide(color: AppColors.border),
        labelStyle: TextStyle(fontSize: 13, fontFamily: fontFamily),
      ),

      // ── Dividers ─────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── ListTile ─────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          fontFamily: fontFamily,
        ),
      ),

      // ── BottomSheet ──────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),

      // ── Tabs ─────────────────────────────────────────────────────────────
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        dividerColor: Colors.transparent,
      ),
    );
  }
}

// Extensiones para TextStyle (sistema tipográfico)
extension TextStyleExtension on TextStyle {
  TextStyle get display => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        fontFamily: GoogleFonts.dmSans().fontFamily,
      );

  TextStyle get subtitle => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
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
        color: AppColors.textSecondary,
        fontFamily: GoogleFonts.dmSans().fontFamily,
      );
}
