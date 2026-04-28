import 'package:get/get.dart';

import 'package:flutter_launcher/features/profile/view/controllers/profile_controller.dart';

class ProfileBindings implements Bindings {
  const ProfileBindings();

  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(() => ProfileController());
    }
  }
}
