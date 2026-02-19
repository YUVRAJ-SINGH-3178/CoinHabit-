import 'package:flutter/material.dart';
import 'package:version/core/constants/app_colors.dart';
import 'package:version/core/theme/text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const radiusMd = 14.0;
    const radiusLg = 18.0;

    return ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryGold,
        secondary: AppColors.primaryGoldDark,
        surface: AppColors.cardWhite,
        onSurface: AppColors.textDark,
        error: AppColors.dangerRed,
      ),
      scaffoldBackgroundColor: AppColors.softWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.softWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        titleMedium: AppTextStyles.h3,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: AppTextStyles.h3,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: AppTextStyles.h3,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          side: const BorderSide(color: AppColors.divider),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: AppTextStyles.h3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.cardWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.primaryGoldDark),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.dangerRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.dangerRed),
        ),
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.textMid),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textLight),
        prefixIconColor: AppColors.textMid,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepNavy,
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.softWhite,
        elevation: 0,
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.softWhite,
        indicatorColor: AppColors.primaryGold.withValues(alpha: 0.16),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextStyles.caption.copyWith(
            color: selected ? AppColors.textDark : AppColors.textMid,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      dividerColor: AppColors.divider,
    );
  }
}
