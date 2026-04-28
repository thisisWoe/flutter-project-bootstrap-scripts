import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_launcher/core/utils/app_key_store.dart';
import 'package:flutter_launcher/core/view/domain/repositories/theme_repository.dart';

class ThemeRepositorySharedPrefsImpl implements ThemeRepository {
  const ThemeRepositorySharedPrefsImpl(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<ThemeMode> getThemeMode() async {
    return ThemeMode.values.byName(
      _preferences.getString(AppKeyStore.themeMode) ?? ThemeMode.system.name,
    );
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    await _preferences.setString(AppKeyStore.themeMode, mode.name);
  }
}
