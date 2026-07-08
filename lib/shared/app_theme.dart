import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static bool isDark = true;

  static Color get bg => isDark ? const Color(0xFF0A0B14) : const Color(0xFFFFFFFF);
  static Color get surface => isDark ? const Color(0xFF12131F) : const Color(0xFFFFFFFF);
  static Color get card => isDark ? const Color(0xFF212036) : const Color(0xFFFFFFFF);
  static Color get accent => isDark ? const Color(0xFF00F0FF) : const Color(0xFF007AFF);
  static Color get accentSecondary => isDark ? const Color(0xFF00C8D4) : const Color(0xFF5856D6);
  static Color get separator => isDark ? const Color(0xFF3A3C4E) : const Color(0xFFD2D2D7);
  static Color get textPrimary => isDark ? const Color(0xFFEAECEE) : const Color(0xFF1D1D1F);
  static Color get textSecondary => isDark ? const Color(0xFFA5ADBA) : const Color(0xFF6E6E73);
  static Color get textTertiary => isDark ? const Color(0xFF6C7A89) : const Color(0xFF8E8E93);
  static Color get surfaceLight => isDark ? const Color(0xFF302C42) : const Color(0xFFF5F5F7);
  static Color get navSurface => isDark ? const Color(0xFF0E101C) : const Color(0xFFF5F5F7);
  static Color get red => isDark ? const Color(0xFFD9534F) : const Color(0xFFFF3B30);
  static Color get orange => isDark ? const Color(0xFFF0AD4E) : const Color(0xFFFF9500);
  static Color get green => isDark ? const Color(0xFF5CB85C) : const Color(0xFF34C759);

  static Color get cyan => isDark ? const Color(0xFF00F0FF) : const Color(0xFF00F0FF);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF00C8D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> bookCoverColors = [
    Color(0xFF7A2021), // Rich Burgundy / Wine Red
    Color(0xFF1E3A5F), // Prussian Blue
    Color(0xFF2C5E43), // Forest Green
    Color(0xFFB35A38), // Warm Terracotta / Leather
    Color(0xFF5D2E46), // Deep Plum
  ];

  static const List<Color> bookAccentColors = [
    Color(0xFFC5A059),
    Color(0xFF8C7B6C),
    Color(0xFF5CB85C),
    Color(0xFFF0AD4E),
    Color(0xFFD9534F),
  ];

  static ThemeData _buildTheme(bool dark) {
    final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    final currentBg = dark ? const Color(0xFF0A0B14) : const Color(0xFFFFFFFF);
    final currentSurface = dark ? const Color(0xFF12131F) : const Color(0xFFFFFFFF);
    final currentCard = dark ? const Color(0xFF212036) : const Color(0xFFFFFFFF);
    final currentAccent = dark ? const Color(0xFF00F0FF) : const Color(0xFF007AFF);
    final currentAccentSecondary = dark ? const Color(0xFF00C8D4) : const Color(0xFF5856D6);
    final currentSeparator = dark ? const Color(0xFF3A3C4E) : const Color(0xFFD2D2D7);
    final currentTextPrimary = dark ? const Color(0xFFEAECEE) : const Color(0xFF1D1D1F);
    final currentTextSecondary = dark ? const Color(0xFFA5ADBA) : const Color(0xFF6E6E73);
    final currentTextTertiary = dark ? const Color(0xFF6C7A89) : const Color(0xFF8E8E93);
    final currentRed = dark ? const Color(0xFFD9534F) : const Color(0xFFFF3B30);

    return base.copyWith(
      scaffoldBackgroundColor: currentBg,
      colorScheme: dark
          ? ColorScheme.dark(
              primary: currentAccent,
              secondary: currentAccentSecondary,
              surface: currentSurface,
              onPrimary: Colors.black,
              onSurface: currentTextPrimary,
              onSecondary: Colors.black,
              error: currentRed,
            )
          : ColorScheme.light(
              primary: currentAccent,
              secondary: currentAccentSecondary,
              surface: currentSurface,
              onPrimary: Colors.white,
              onSurface: currentTextPrimary,
              onSecondary: Colors.white,
              error: currentRed,
            ),
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: currentTextPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.outfit(
          color: currentTextPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: currentTextPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.outfit(
          color: currentTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.outfit(
          color: currentTextPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: currentTextPrimary,
          fontSize: 15,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: currentTextSecondary,
          fontSize: 13,
          height: 1.5,
        ),
        labelSmall: GoogleFonts.outfit(
          color: currentTextTertiary,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: currentSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: currentTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: currentAccent),
        actionsIconTheme: IconThemeData(color: currentAccent),
      ),
      cardTheme: CardThemeData(
        color: currentCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: currentAccent,
          foregroundColor: dark ? Colors.black : Colors.white,
          elevation: 0,
          shadowColor: currentAccent.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: currentAccent,
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: currentAccent,
          side: BorderSide(color: currentAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: currentAccent,
        foregroundColor: dark ? Colors.black : Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: currentSeparator,
        thickness: 0.5,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF232539) : const Color(0xFFF5F5F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: currentAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: currentRed, width: 1),
        ),
        labelStyle: TextStyle(color: currentTextSecondary, fontSize: 14),
        hintStyle: TextStyle(color: currentTextTertiary, fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: currentSurface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: currentSeparator),
        ),
        titleTextStyle: GoogleFonts.outfit(
          color: currentTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        contentTextStyle: GoogleFonts.outfit(
          color: currentTextSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: currentAccent,
        textColor: currentTextPrimary,
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        selectedColor: dark ? Colors.black : Colors.white,
        fillColor: currentAccent,
        color: currentTextSecondary,
        borderColor: currentSeparator,
        selectedBorderColor: currentAccent,
        borderRadius: BorderRadius.circular(10),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: currentTextPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.outfit(
          color: dark ? Colors.black : Colors.white,
          fontSize: 14,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return currentAccent;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return currentAccent.withValues(alpha: 0.4);
          }
          return currentSeparator;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return currentAccent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: currentTextTertiary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: currentAccent,
        linearTrackColor: dark ? const Color(0xFF3A3C4E) : const Color(0xFFE5E5EA),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: currentTextPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.outfit(color: dark ? Colors.black : Colors.white, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  static ThemeData get lightTheme => _buildTheme(false);
  static ThemeData get darkTheme => _buildTheme(true);
}
