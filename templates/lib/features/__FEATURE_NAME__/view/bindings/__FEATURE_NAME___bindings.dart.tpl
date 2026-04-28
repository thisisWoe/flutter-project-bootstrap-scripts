import 'package:get/get.dart';

import 'package:__PROJECT_NAME__/features/__FEATURE_NAME__/view/controllers/__FEATURE_NAME___controller.dart';

class __FEATURE_CLASS_NAME__Bindings implements Bindings {
  const __FEATURE_CLASS_NAME__Bindings();

  @override
  void dependencies() {
    if (!Get.isRegistered<__FEATURE_CLASS_NAME__Controller>()) {
      Get.lazyPut<__FEATURE_CLASS_NAME__Controller>(() => __FEATURE_CLASS_NAME__Controller());
    }
  }
}
