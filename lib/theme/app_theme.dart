import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const primary = Color(0xFF005FFF);
  static const primaryDark = Color(0xFF0040CC);
  static const secondary = Color(0xFF00C3FF);
  static const accent = Color(0xFF0E60DB);

  // Dark theme surfaces
  static const darkBg = Color(0xFF0A0D1A);
  static const darkSurface = Color(0xFF141928);
  static const darkCard = Color(0xFF1A2035);
  static const darkAppBar = Color(0xFF0F1523);
  static const darkNavBar = Color(0xFF0F1523);
  static const darkBackground = Color(0xFF0A0D1A); // alias for darkBg
  static const darkDivider = Color(0xFF1E2840);

  // Light theme surfaces
  static const lightBg = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF5F6FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightAppBar = Color(0xFF005FFF);
  static const lightNavBar = Color(0xFFFFFFFF);

  // Chat bubbles
  static const sentBubble = Color(0xFF005FFF);
  static const receivedBubbleDark = Color(0xFF1D2941);
  static const receivedBubbleLight = Color(0xFFEEF0F5);

  // Text
  static const textDark = Color(0xFFFFFFFF);
  static const textDarkSecondary = Color(0xFF8892A4);
  static const textLight = Color(0xFF1A1D22);
  static const textLightSecondary = Color(0xFF72767E);

  // Status
  static const online = Color(0xFF20E070);
  static const error = Color(0xFFFF4B4B);
  static const unreadBadge = Color(0xFF005FFF);

  // Reaction
  static const reactionBg = Color(0xFF1D2941);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.lightSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightAppBar,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: AppColors.lightNavBar,
        ),
        dividerColor: const Color(0xFFE5E7EB),
        useMaterial3: true,
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.darkSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkAppBar,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: AppColors.darkNavBar,
        ),
        dividerColor: AppColors.darkDivider,
        useMaterial3: true,
      );
}
