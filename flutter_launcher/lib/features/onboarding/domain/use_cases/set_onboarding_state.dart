import 'package:flutter_launcher/features/onboarding/domain/repositories/onboarding_repository.dart';

class SetOnboardingStateUseCase {
  const SetOnboardingStateUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<void> call(bool accepted) {
    return _repository.setOnboardingState(accepted);
  }
}
