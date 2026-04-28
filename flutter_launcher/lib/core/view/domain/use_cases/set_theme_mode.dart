import 'package:flutter/material.dart';
import 'package:flutter_launcher/core/view/domain/repositories/theme_repository.dart';

class SetThemeModeUseCase {
  const SetThemeModeUseCase(this._repository);

  final ThemeRepository _repository;

  Future<void> call(ThemeMode mode) {
    return _repository.saveThemeMode(mode);
  }
}
