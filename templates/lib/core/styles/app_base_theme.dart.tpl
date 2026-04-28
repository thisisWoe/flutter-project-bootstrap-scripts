import 'package:flutter/material.dart';
import 'package:__PROJECT_NAME__/core/styles/app_colors.dart';

abstract final class AppBaseTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.lightSeed),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkSeed,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
