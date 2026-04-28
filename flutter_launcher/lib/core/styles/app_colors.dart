import 'package:flutter/material.dart';

abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Base palette
  // ---------------------------------------------------------------------------

  static const Color night = Color(0xFF001219);
  static const Color deepTeal = Color(0xFF005F73);
  static const Color teal = Color(0xFF0A9396);
  static const Color mint = Color(0xFF94D2BD);
  static const Color sand = Color(0xFFE9D8A6);
  static const Color amber = Color(0xFFEE9B00);
  static const Color orange = Color(0xFFCA6702);
  static const Color rust = Color(0xFFBB3E03);
  static const Color red = Color(0xFFAE2012);
  static const Color wine = Color(0xFF9B2226);

  static const Color flutterSky = Color(0xFF027DFD);

  // ---------------------------------------------------------------------------
  // Extra shades generated from the palette
  // ---------------------------------------------------------------------------

  static const Color teal950 = Color(0xFF001219);
  static const Color teal900 = Color(0xFF003844);
  static const Color teal800 = Color(0xFF005F73);
  static const Color teal700 = Color(0xFF08777F);
  static const Color teal600 = Color(0xFF0A9396);
  static const Color teal300 = Color(0xFF94D2BD);
  static const Color teal100 = Color(0xFFD6F2EA);
  static const Color teal50 = Color(0xFFEFFAF5);

  static const Color sand900 = Color(0xFF3A2D00);
  static const Color sand700 = Color(0xFF8A6400);
  static const Color sand500 = Color(0xFFE9D8A6);
  static const Color sand200 = Color(0xFFF6EBC8);
  static const Color sand100 = Color(0xFFFFF3C8);
  static const Color sand50 = Color(0xFFFFFBF0);

  static const Color amber900 = Color(0xFF3D2600);
  static const Color amber800 = Color(0xFF7A4E00);
  static const Color amber700 = Color(0xFF9A5A00);
  static const Color amber600 = Color(0xFFCA6702);
  static const Color amber500 = Color(0xFFEE9B00);
  static const Color amber200 = Color(0xFFFFD88A);
  static const Color amber100 = Color(0xFFFFE8BE);

  static const Color red950 = Color(0xFF410002);
  static const Color red900 = Color(0xFF690005);
  static const Color red800 = Color(0xFF9B2226);
  static const Color red700 = Color(0xFFAE2012);
  static const Color red600 = Color(0xFFBB3E03);
  static const Color red100 = Color(0xFFFFDAD3);
  static const Color red50 = Color(0xFFFFF2EF);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ---------------------------------------------------------------------------
  // Light theme colors
  // ---------------------------------------------------------------------------

  static const Color primary = deepTeal;
  static const Color onPrimary = white;
  static const Color primaryContainer = mint;
  static const Color onPrimaryContainer = night;
  static const Color primaryFixed = Color(0xFFC8F1E5);
  static const Color primaryFixedDim = mint;
  static const Color onPrimaryFixed = night;
  static const Color onPrimaryFixedVariant = deepTeal;

  static const Color secondary = teal;
  static const Color onSecondary = night;
  static const Color secondaryContainer = teal100;
  static const Color onSecondaryContainer = night;
  static const Color secondaryFixed = teal100;
  static const Color secondaryFixedDim = mint;
  static const Color onSecondaryFixed = night;
  static const Color onSecondaryFixedVariant = deepTeal;

  static const Color tertiary = rust;
  static const Color onTertiary = white;
  static const Color tertiaryContainer = amber100;
  static const Color onTertiaryContainer = amber900;
  static const Color tertiaryFixed = Color(0xFFFFE2A8);
  static const Color tertiaryFixedDim = sand;
  static const Color onTertiaryFixed = amber900;
  static const Color onTertiaryFixedVariant = amber800;

  static const Color error = red;
  static const Color onError = white;
  static const Color errorContainer = red100;
  static const Color onErrorContainer = red950;

  static const Color surface = sand50;
  static const Color onSurface = night;
  static const Color surfaceDim = Color(0xFFE1D6C3);
  static const Color surfaceBright = sand50;
  static const Color surfaceContainerLowest = white;
  static const Color surfaceContainerLow = Color(0xFFFCF7E8);
  static const Color surfaceContainer = Color(0xFFF6EFD8);
  static const Color surfaceContainerHigh = Color(0xFFEFE5C8);
  static const Color surfaceContainerHighest = sand;
  static const Color onSurfaceVariant = Color(0xFF2F4D50);
  static const Color surfaceTint = primary;

  static const Color outline = Color(0xFF637778);
  static const Color outlineVariant = Color(0xFFB8C9C2);

  static const Color shadow = black;
  static const Color scrim = black;

  static const Color inverseSurface = Color(0xFF123236);
  static const Color onInverseSurface = teal50;
  static const Color inversePrimary = mint;

  // Legacy aliases.
  static const Color background = surface;
  static const Color onBackground = onSurface;
  static const Color surfaceVariant = surfaceContainerHighest;

  // ---------------------------------------------------------------------------
  // Dark theme colors
  // ---------------------------------------------------------------------------

  static const Color darkPrimary = mint;
  static const Color darkOnPrimary = teal900;
  static const Color darkPrimaryContainer = deepTeal;
  static const Color darkOnPrimaryContainer = teal100;
  static const Color darkPrimaryFixed = primaryFixed;
  static const Color darkPrimaryFixedDim = primaryFixedDim;
  static const Color darkOnPrimaryFixed = onPrimaryFixed;
  static const Color darkOnPrimaryFixedVariant = onPrimaryFixedVariant;

  static const Color darkSecondary = sand;
  static const Color darkOnSecondary = sand900;
  static const Color darkSecondaryContainer = Color(0xFF5F4B00);
  static const Color darkOnSecondaryContainer = sand100;
  static const Color darkSecondaryFixed = secondaryFixed;
  static const Color darkSecondaryFixedDim = secondaryFixedDim;
  static const Color darkOnSecondaryFixed = onSecondaryFixed;
  static const Color darkOnSecondaryFixedVariant = onSecondaryFixedVariant;

  static const Color darkTertiary = amber;
  static const Color darkOnTertiary = amber900;
  static const Color darkTertiaryContainer = orange;
  static const Color darkOnTertiaryContainer = amber100;
  static const Color darkTertiaryFixed = tertiaryFixed;
  static const Color darkTertiaryFixedDim = tertiaryFixedDim;
  static const Color darkOnTertiaryFixed = onTertiaryFixed;
  static const Color darkOnTertiaryFixedVariant = onTertiaryFixedVariant;

  static const Color darkError = Color(0xFFFFB4A8);
  static const Color darkOnError = red900;
  static const Color darkErrorContainer = wine;
  static const Color darkOnErrorContainer = red100;

  static const Color darkSurface = night;
  static const Color darkOnSurface = teal50;
  static const Color darkSurfaceDim = night;
  static const Color darkSurfaceBright = Color(0xFF17363B);
  static const Color darkSurfaceContainerLowest = Color(0xFF00090D);
  static const Color darkSurfaceContainerLow = night;
  static const Color darkSurfaceContainer = Color(0xFF002630);
  static const Color darkSurfaceContainerHigh = teal900;
  static const Color darkSurfaceContainerHighest = Color(0xFF004F5F);
  static const Color darkOnSurfaceVariant = Color(0xFFC7D7D2);
  static const Color darkSurfaceTint = darkPrimary;

  static const Color darkOutline = Color(0xFF8EA3A0);
  static const Color darkOutlineVariant = Color(0xFF40595B);

  static const Color darkShadow = black;
  static const Color darkScrim = black;

  static const Color darkInverseSurface = sand;
  static const Color darkOnInverseSurface = night;
  static const Color darkInversePrimary = deepTeal;

  // Legacy aliases.
  static const Color darkBackground = darkSurface;
  static const Color darkOnBackground = darkOnSurface;
  static const Color darkSurfaceVariant = darkSurfaceContainerHighest;

  // ---------------------------------------------------------------------------
  // Optional semantic colors
  // ---------------------------------------------------------------------------

  static const Color info = deepTeal;
  static const Color onInfo = white;
  static const Color infoContainer = teal100;
  static const Color onInfoContainer = night;

  static const Color success = teal;
  static const Color onSuccess = night;
  static const Color successContainer = mint;
  static const Color onSuccessContainer = night;

  static const Color warning = amber;
  static const Color onWarning = night;
  static const Color warningContainer = amber100;
  static const Color onWarningContainer = amber900;

  static const Color danger = red;
  static const Color onDanger = white;
  static const Color dangerContainer = red100;
  static const Color onDangerContainer = red950;
}
