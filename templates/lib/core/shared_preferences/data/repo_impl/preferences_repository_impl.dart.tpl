import 'package:shared_preferences/shared_preferences.dart';
import 'package:__PROJECT_NAME__/core/shared_preferences/domain/repositories/preferences_repository.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  const PreferencesRepositoryImpl(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? readString(String key) => _preferences.getString(key);

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }
}
