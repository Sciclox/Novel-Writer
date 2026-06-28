import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color bg = Color(0xFF1C1C1E);
  static const Color surface = Color(0xFF2C2C2E);
  static const Color card = Color(0xFF3A3A3C);
  static const Color accent = Color(0xFFFFFFFF);
  static const Color accentSecondary = Color(0xFFAEAEB2);
  static const Color separator = Color(0xFF48484A);
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFAEAEB2);
  static const Color textTertiary = Color(0xFF636366);
  static const Color red = Color(0xFFFF453A);
  static const Color orange = Color(0xFFFF9F0A);
  static const Color green = Color(0xFF30D158);

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentSecondary,
        surface: surface,
        onPrimary: bg,
        onSurface: textPrimary,
        onSecondary: bg,
        error: red,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.inter(color: textPrimary),
        titleLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 15),
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 15),
        bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        labelSmall: GoogleFonts.inter(color: textTertiary, fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: accent),
        actionsIconTheme: const IconThemeData(color: accent),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: bg,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(color: separator, thickness: 0.5, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: red, width: 1),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textTertiary, fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        contentTextStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: accent,
        textColor: textPrimary,
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        selectedColor: bg,
        fillColor: accent,
        color: textSecondary,
        borderColor: separator,
        selectedBorderColor: accent,
        borderRadius: BorderRadius.circular(8),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
