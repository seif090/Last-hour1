import 'package:flutter/material.dart';

/// Exact brand color values from DESIGN.md.
class BrandColors {
  BrandColors._();

  // ── Primary ──
  static const Color primary = Color(0xFFFFB2B7);
  static const Color onPrimary = Color(0xFF67001C);
  static const Color primaryContainer = Color(0xFFFC536D);
  static const Color onPrimaryContainer = Color(0xFF5B0017);
  static const Color inversePrimary = Color(0xFFB71D3F);
  static const Color primaryFixed = Color(0xFFFFDADB);
  static const Color primaryFixedDim = Color(0xFFFFB2B7);
  static const Color onPrimaryFixed = Color(0xFF40000E);
  static const Color onPrimaryFixedVariant = Color(0xFF91002B);

  // ── Surface & Background (dark) ──
  static const Color surface = Color(0xFF1D1011);
  static const Color surfaceDim = Color(0xFF1D1011);
  static const Color surfaceBright = Color(0xFF463536);
  static const Color surfaceContainerLowest = Color(0xFF170B0C);
  static const Color surfaceContainerLow = Color(0xFF261819);
  static const Color surfaceContainer = Color(0xFF2B1C1D);
  static const Color surfaceContainerHigh = Color(0xFF362627);
  static const Color surfaceContainerHighest = Color(0xFF413031);

  static const Color onSurface = Color(0xFFF7DCDD);
  static const Color onSurfaceVariant = Color(0xFFE2BEBF);
  static const Color inverseSurface = Color(0xFFF7DCDD);
  static const Color inverseOnSurface = Color(0xFF3D2C2D);

  // ── Background ──
  static const Color background = Color(0xFF1D1011);
  static const Color onBackground = Color(0xFFF7DCDD);
  static const Color surfaceVariant = Color(0xFF413031);
  static const Color surfaceTint = Color(0xFFFFB2B7);

  // ── Secondary ──
  static const Color secondary = Color(0xFFBBC5EB);
  static const Color onSecondary = Color(0xFF252F4D);
  static const Color secondaryContainer = Color(0xFF3B4665);
  static const Color onSecondaryContainer = Color(0xFFAAB4D9);
  static const Color secondaryFixed = Color(0xFFDAE1FF);
  static const Color secondaryFixedDim = Color(0xFFBBC5EB);
  static const Color onSecondaryFixed = Color(0xFF0F1A37);
  static const Color onSecondaryFixedVariant = Color(0xFF3B4665);

  // ── Tertiary ──
  static const Color tertiary = Color(0xFF67DC9F);
  static const Color onTertiary = Color(0xFF003921);
  static const Color tertiaryContainer = Color(0xFF25A46D);
  static const Color onTertiaryContainer = Color(0xFF00311C);
  static const Color tertiaryFixed = Color(0xFF84F9BA);
  static const Color tertiaryFixedDim = Color(0xFF67DC9F);
  static const Color onTertiaryFixed = Color(0xFF002111);
  static const Color onTertiaryFixedVariant = Color(0xFF005232);

  // ── Error ──
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // ── Outline ──
  static const Color outline = Color(0xFFA9898A);
  static const Color outlineVariant = Color(0xFF5A4042);

  // ── Light-theme overrides (inverted from dark) ──
  static const Color lightSurface = Color(0xFFFFF8F9);
  static const Color lightOnSurface = Color(0xFF201A1B);
  static const Color lightOnSurfaceVariant = Color(0xFF524344);
  static const Color lightOutline = Color(0xFF857374);
  static const Color lightSurfaceContainerLow = Color(0xFFFDF5F6);
  static const Color lightSurfaceContainer = Color(0xFFF7ECED);
}
