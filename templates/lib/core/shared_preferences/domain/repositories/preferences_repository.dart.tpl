abstract interface class PreferencesRepository {
  String? readString(String key);
  Future<void> writeString(String key, String value);
}
