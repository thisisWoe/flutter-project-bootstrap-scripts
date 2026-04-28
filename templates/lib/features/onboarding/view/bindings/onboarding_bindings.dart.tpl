import 'package:get/get.dart';

import 'package:__PROJECT_NAME__/features/onboarding/domain/use_cases/get_onboarding_state.dart';
import 'package:__PROJECT_NAME__/features/onboarding/domain/use_cases/set_onboarding_state.dart';
import 'package:__PROJECT_NAME__/features/onboarding/view/controllers/onboarding_controller.dart';

class OnboardingBindings implements Bindings {
  const OnboardingBindings();

  @override
  void dependencies() {
    if (!Get.isRegistered<OnboardingController>()) {
      Get.lazyPut<OnboardingController>(
        () => OnboardingController(
          getOnboardingState: Get.find<GetOnboardingStateUseCase>(),
          setOnboardingState: Get.find<SetOnboardingStateUseCase>(),
        ),
      );
    }
  }
}
