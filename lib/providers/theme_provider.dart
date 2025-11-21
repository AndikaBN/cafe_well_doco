import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cafe_well_doco/theme/app_colors.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true; // Default dark mode untuk coffee theme
  static const String _themeKey = 'isDarkMode';

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true; // Default true
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.coffeeCream,
      brightness: Brightness.light,
      primary: AppColors.coffeeCream,
      secondary: AppColors.cappuccino,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F1ED),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: AppColors.coffeeCream,
      foregroundColor: AppColors.darkBrown,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.coffeeCream,
      brightness: Brightness.dark,
      primary: AppColors.coffeeCream,
      secondary: AppColors.cappuccino,
      background: AppColors.darkBrown,
      surface: AppColors.mediumBrown,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.darkBrown,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: AppColors.mediumBrown,
      foregroundColor: AppColors.latte,
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      color: AppColors.mediumBrown,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
      titleLarge: TextStyle(color: AppColors.latte),
      titleMedium: TextStyle(color: AppColors.latte),
    ),
  );
}
