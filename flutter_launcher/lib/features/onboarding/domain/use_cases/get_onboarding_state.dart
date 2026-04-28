import 'package:flutter_launcher/features/onboarding/domain/repositories/onboarding_repository.dart';

class GetOnboardingStateUseCase {
  const GetOnboardingStateUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<bool> call() {
    return _repository.getOnboardingState();
  }
}
