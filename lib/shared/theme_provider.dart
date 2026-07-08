import 'package:flutter/material.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool get isDark => true;

  ThemeProvider() {
    AppColors.isDark = true;
  }

  Future<void> toggleTheme() async {
    // Locked to dark theme
  }
}
