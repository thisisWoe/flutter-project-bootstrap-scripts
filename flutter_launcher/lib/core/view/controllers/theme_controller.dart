import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_launcher/core/view/domain/use_cases/get_theme_mode.dart';
import 'package:flutter_launcher/core/view/domain/use_cases/set_theme_mode.dart';

class ThemeController extends GetxController {
  ThemeController({
    required GetThemeModeUseCase getThemeMode,
    required SetThemeModeUseCase setThemeModeUseCase,
  })  : _getThemeMode = getThemeMode,
        _setThemeMode = setThemeModeUseCase;

  final GetThemeModeUseCase _getThemeMode;
  final SetThemeModeUseCase _setThemeMode;
  final themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    themeMode.value = await _getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _setThemeMode(mode);
  }
}
