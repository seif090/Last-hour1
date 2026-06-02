import 'package:flutter/material.dart';
import 'brand_colors.dart';
import 'brand_typography.dart';

/// Last Hour brand [ThemeData] — exact values from DESIGN.md.
class AppTheme {
  AppTheme._();

  /// Exact Material 3 dark color scheme from DESIGN.md structured data.
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: BrandColors.primary,
    onPrimary: BrandColors.onPrimary,
    primaryContainer: BrandColors.primaryContainer,
    onPrimaryContainer: BrandColors.onPrimaryContainer,
    secondary: BrandColors.secondary,
    onSecondary: BrandColors.onSecondary,
    secondaryContainer: BrandColors.secondaryContainer,
    onSecondaryContainer: BrandColors.onSecondaryContainer,
    tertiary: BrandColors.tertiary,
    onTertiary: BrandColors.onTertiary,
    tertiaryContainer: BrandColors.tertiaryContainer,
    onTertiaryContainer: BrandColors.onTertiaryContainer,
    error: BrandColors.error,
    onError: BrandColors.onError,
    errorContainer: BrandColors.errorContainer,
    onErrorContainer: BrandColors.onErrorContainer,
    surface: BrandColors.surface,
    onSurface: BrandColors.onSurface,
    surfaceContainerHighest: BrandColors.surfaceContainerHighest,
    onSurfaceVariant: BrandColors.onSurfaceVariant,
    outline: BrandColors.outline,
    outlineVariant: BrandColors.outlineVariant,
    inverseSurface: BrandColors.inverseSurface,
    inversePrimary: BrandColors.inversePrimary,
  );

  /// Light scheme — derived by inverting the dark scheme.
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: BrandColors.inversePrimary,
    onPrimary: Colors.white,
    primaryContainer: BrandColors.primaryContainer,
    onPrimaryContainer: Colors.white,
    secondary: BrandColors.onSecondary,
    onSecondary: Colors.white,
    secondaryContainer: BrandColors.secondaryContainer,
    onSecondaryContainer: Colors.white,
    tertiary: BrandColors.onTertiary,
    onTertiary: Colors.white,
    tertiaryContainer: BrandColors.tertiaryContainer,
    onTertiaryContainer: Colors.white,
    error: BrandColors.onError,
    onError: Colors.white,
    errorContainer: BrandColors.errorContainer,
    onErrorContainer: Colors.white,
    surface: BrandColors.lightSurface,
    onSurface: BrandColors.lightOnSurface,
    surfaceContainerHighest: BrandColors.lightSurfaceContainer,
    onSurfaceVariant: BrandColors.lightOnSurfaceVariant,
    outline: BrandColors.lightOutline,
    outlineVariant: BrandColors.lightOutline,
    inverseSurface: BrandColors.surface,
    inversePrimary: BrandColors.primary,
  );

  // ── Theme data ──

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightColorScheme,
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
            backgroundColor: _lightColorScheme.primary,
            foregroundColor: _lightColorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: BrandTypography.bodyLg().copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          selectedColor: BrandColors.primaryContainer.withOpacity(0.3),
          labelStyle: BrandTypography.bodyMd(color: BrandColors.lightOnSurface),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: BrandColors.inversePrimary,
          type: BottomNavigationBarType.fixed,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: BrandColors.lightSurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BrandColors.lightOutline)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BrandColors.lightOutline)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: BrandColors.inversePrimary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _darkColorScheme,
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
          selectedColor: BrandColors.primaryContainer.withOpacity(0.3),
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
          indicatorColor: BrandColors.primaryContainer.withOpacity(0.3),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return BrandTypography.labelBold(color: BrandColors.primary);
            }
            return BrandTypography.labelBold(color: BrandColors.onSurfaceVariant);
          }),
        ),
      );
}
