import 'package:flutter/material.dart';

abstract class AppTextStyles {
  // ───────────────────── Display ─────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    height: 64 / 57,
    letterSpacing: -0.25,
  );
  static const TextStyle displayLargeItalic = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    height: 64 / 57,
    letterSpacing: -0.25,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    height: 52 / 45,
  );
  static const TextStyle displayMediumItalic = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    height: 52 / 45,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
  );
  static const TextStyle displaySmallItalic = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Headlines ─────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
  );
  static const TextStyle headlineLargeItalic = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
  );
  static const TextStyle headlineMediumItalic = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
  );
  static const TextStyle headlineSmallItalic = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Titles ─────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
  );
  static const TextStyle titleLargeItalic = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: 0.15,
  );
  static const TextStyle titleMediumItalic = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: 0.15,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.1,
  );
  static const TextStyle titleSmallItalic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Body ─────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0.5,
  );
  static const TextStyle bodyLargeItalic = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0.5,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0.25,
  );
  static const TextStyle bodyMediumItalic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0.25,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.4,
  );
  static const TextStyle bodySmallItalic = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.4,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Labels ─────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.1,
  );
  static const TextStyle labelLargeItalic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.1,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.5,
  );
  static const TextStyle labelMediumItalic = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.5,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 16 / 11,
    letterSpacing: 0.5,
  );
  static const TextStyle labelSmallItalic = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 16 / 11,
    letterSpacing: 0.5,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Buttons ─────────────────────
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.75,
    color: Colors.white,
  );
  static const TextStyle buttonPrimaryItalic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.75,
    color: Colors.white,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.75,
  );
  static const TextStyle buttonSecondaryItalic = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.75,
    fontStyle: FontStyle.italic,
  );

  // ───────────────────── Captions & Overline ─────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 16 / 11,
    letterSpacing: 0.5,
    color: Colors.grey,
  );
}
