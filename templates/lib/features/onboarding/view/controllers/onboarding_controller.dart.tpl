import 'package:get/get.dart';

import 'package:__PROJECT_NAME__/features/onboarding/domain/use_cases/get_onboarding_state.dart';
import 'package:__PROJECT_NAME__/features/onboarding/domain/use_cases/set_onboarding_state.dart';

class OnboardingController extends GetxController {
  OnboardingController({
    required GetOnboardingStateUseCase getOnboardingState,
    required SetOnboardingStateUseCase setOnboardingState,
  }) : _getOnboardingState = getOnboardingState,
       _setOnboardingState = setOnboardingState;

  final GetOnboardingStateUseCase _getOnboardingState;
  final SetOnboardingStateUseCase _setOnboardingState;

  final title = 'Onboarding'.obs;
  final isAccepted = false.obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    isAccepted.value = await _getOnboardingState();
    isLoading.value = false;
  }

  Future<void> setAccepted(bool value) async {
    isAccepted.value = value;
    await _setOnboardingState(value);
  }
}
