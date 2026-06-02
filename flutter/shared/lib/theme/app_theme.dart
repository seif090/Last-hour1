import 'package:flutter/material.dart';
import 'brand_colors.dart';
import 'brand_typography.dart';

/// Last Hour brand [ThemeData] factory — Electric Crimson + Deep Navy.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: BrandColors.primary,
        scaffoldBackgroundColor: BrandColors.lightSurface,
        textTheme: BrandTypography.textTheme,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: BrandColors.lightOnSurface,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: BrandColors.lightOutline),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: BrandColors.primary,
            foregroundColor: BrandColors.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: BrandTypography.bodyLg(color: BrandColors.onPrimary).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          selectedColor: BrandColors.primary.withOpacity(0.15),
          labelStyle: BrandTypography.bodyMd(),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: BrandColors.primary,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: BrandColors.lightSurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BrandColors.lightOutline)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BrandColors.lightOutline)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BrandColors.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: BrandColors.primary,
        scaffoldBackgroundColor: BrandColors.surface,
        textTheme: BrandTypography.textTheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: BrandColors.surfaceContainer,
          foregroundColor: BrandColors.onSurface,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: BrandColors.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: BrandColors.outline.withOpacity(0.5)),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: BrandColors.primary,
            foregroundColor: BrandColors.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: BrandTypography.bodyLg(color: BrandColors.onPrimary).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          selectedColor: BrandColors.primary.withOpacity(0.2),
          labelStyle: BrandTypography.bodyMd(color: BrandColors.onSurface),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: BrandColors.primary,
          unselectedItemColor: BrandColors.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          backgroundColor: BrandColors.surfaceContainer.withOpacity(0.95),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: BrandColors.surfaceContainerHigh,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BrandColors.primary, width: 2),
          ),
          hintStyle: BrandTypography.bodyMd(color: BrandColors.onSurfaceVariant.withOpacity(0.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: BrandColors.surfaceContainer.withOpacity(0.95),
          indicatorColor: BrandColors.primary.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return BrandTypography.labelBold(color: BrandColors.primary);
            }
            return BrandTypography.labelBold(color: BrandColors.onSurfaceVariant);
          }),
        ),
      );
}
