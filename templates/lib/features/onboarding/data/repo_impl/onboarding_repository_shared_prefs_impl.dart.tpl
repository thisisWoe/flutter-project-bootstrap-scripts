import 'package:shared_preferences/shared_preferences.dart';

import 'package:__PROJECT_NAME__/core/utils/app_key_store.dart';
import 'package:__PROJECT_NAME__/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositorySharedPrefsImpl implements OnboardingRepository {
  const OnboardingRepositorySharedPrefsImpl(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<bool> getOnboardingState() async {
    return _preferences.getBool(AppKeyStore.onboardingAccepted) ?? false;
  }

  @override
  Future<void> setOnboardingState(bool accepted) async {
    await _preferences.setBool(AppKeyStore.onboardingAccepted, accepted);
  }
}
