import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reservation_chat_univercity_project/core/themes/text_themes.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: false,
      //platform: TargetPlatform.iOS,
      fontFamily: 'IRANYekan',
      fontFamilyFallback: const ['Roboto'],

      brightness: Brightness.light,
      primaryColor: AppColors.primary500,
      scaffoldBackgroundColor: AppColors.bg1Light,
      cardColor: AppColors.text100Light,
      indicatorColor: AppColors.progressIndicatorLight,
      canvasColor: AppColors.primary500,
      colorScheme: const ColorScheme.light(
        tertiaryFixed: AppColors.text700Dark,
        onTertiaryFixed: AppColors.primary400,
        tertiaryFixedDim: AppColors.primary50,
        onPrimaryFixed: AppColors.primary100,
        onInverseSurface: AppColors.primary400,
        onPrimaryContainer: AppColors.primary50,
        onSecondaryFixed: AppColors.white50,
        primary: AppColors.primary500,
        onPrimary: Colors.white,
        secondaryFixed: AppColors.blueLight,
        surface: AppColors.bg2Light,
        onSurface: AppColors.text700Light,
        secondary: AppColors.text600Light,
        onSecondary: AppColors.text500Light,
        tertiary: AppColors.text400Light,
        onTertiary: AppColors.text300Light,
        surfaceDim: AppColors.text200Light,
        surfaceTint: AppColors.text100Light,
        surfaceBright: AppColors.text50Light,
        shadow: Colors.white,
        outline: AppColors.white100,
        scrim: AppColors.white100,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.text50Light,
        alignLabelWithHint: true,
        hintStyle: TextStyle(
          color: AppColors.text500Light,
          fontSize: 14.0.sp,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: TextStyle(fontSize: 12.sp, color: Colors.red),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.text400Light),
          borderRadius: BorderRadius.circular(12.0.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.text200Light),
          borderRadius: BorderRadius.circular(12.0.r),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.text200Light),
          borderRadius: BorderRadius.circular(12.0.r),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shadowColor: Colors.transparent,
          visualDensity: VisualDensity.compact,
          textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
          elevation: 0.0,
          fixedSize: const Size(120.0, 56.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.r),
          ),
        ),
      ),
      textTheme: TextTheme(
        bodyMedium: LightAppTextStyles.bodyMedium,
        labelMedium: LightAppTextStyles.labelMedium,
        headlineMedium: LightAppTextStyles.headlineMedium,
        bodySmall: LightAppTextStyles.bodySmall,
        titleMedium: LightAppTextStyles.titleMedium,
        bodyLarge: LightAppTextStyles.bodyLarge,
        titleSmall: LightAppTextStyles.titleSmall,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: false,
      //platform: TargetPlatform.iOS,
      fontFamily: 'IRANYekan',
      fontFamilyFallback: const ['Roboto'],

      brightness: Brightness.dark,
      indicatorColor: AppColors.progressIndicatorDark,
      cardColor: AppColors.text200Dark,
      primaryColor: AppColors.primary500,
      canvasColor: AppColors.primary50,
      scaffoldBackgroundColor: AppColors.bg1Dark,
      colorScheme: const ColorScheme.dark(
        onSecondaryFixed: AppColors.black2050,
        secondaryFixed: AppColors.blueDark,
        onPrimaryContainer: AppColors.bg2Dark,
        onInverseSurface: AppColors.primary50,
        tertiaryFixed: AppColors.black2050,
        onTertiaryFixed: AppColors.primary100,
        tertiaryFixedDim: AppColors.primary900,
        onPrimaryFixed: AppColors.primary700,
        primary: AppColors.primary500,
        onPrimary: Colors.white,
        surface: AppColors.bg2Dark,
        onSurface: AppColors.text700Dark,
        secondary: AppColors.text600Dark,
        onSecondary: AppColors.text500Dark,
        tertiary: AppColors.text400Dark,
        onTertiary: AppColors.text300Dark,
        surfaceDim: AppColors.text200Dark,
        surfaceTint: AppColors.text100Dark,
        surfaceBright: AppColors.text50Dark,
        shadow: AppColors.black100,
        outline: AppColors.white100,
        scrim: AppColors.white100,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.text50Dark,
        alignLabelWithHint: true,
        hintStyle: TextStyle(
          color: AppColors.text500Dark,
          fontSize: 14.0.sp,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: TextStyle(fontSize: 12.sp, color: Colors.red),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.text400Dark),
          borderRadius: BorderRadius.circular(12.0.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.text200Dark),
          borderRadius: BorderRadius.circular(12.0.r),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.text200Dark),
          borderRadius: BorderRadius.circular(12.0.r),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shadowColor: Colors.transparent,
          visualDensity: VisualDensity.compact,
          textStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
          elevation: 0.0,
          fixedSize: const Size(120.0, 56.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.r),
          ),
        ),
      ),
      textTheme: TextTheme(
        titleSmall: DarkAppTextStyles.titleSmall,
        // titleSmall: DarkAppTextStyles.titleSmall,
        titleMedium: DarkAppTextStyles.titleMedium,
        bodySmall: DarkAppTextStyles.bodySmall,
        labelMedium: DarkAppTextStyles.labelMedium,
        headlineMedium: DarkAppTextStyles.headlineMedium,
        bodyMedium: DarkAppTextStyles.bodyMedium,
        bodyLarge: DarkAppTextStyles.bodyLarge,
      ),
    );
  }
}
