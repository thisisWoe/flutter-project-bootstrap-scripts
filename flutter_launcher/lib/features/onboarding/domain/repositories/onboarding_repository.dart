abstract interface class OnboardingRepository {
  Future<bool> getOnboardingState();
  Future<void> setOnboardingState(bool accepted);
}
