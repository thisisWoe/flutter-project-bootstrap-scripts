import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:__PROJECT_NAME__/features/__FEATURE_NAME__/view/controllers/__FEATURE_NAME___controller.dart';

class __FEATURE_CLASS_NAME__Page extends StatelessWidget {
  const __FEATURE_CLASS_NAME__Page({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<__FEATURE_CLASS_NAME__Controller>();

    return Scaffold(
      appBar: AppBar(title: Text(controller.title.value)),
      body: Center(
        child: Obx(() => Text(controller.title.value)),
      ),
    );
  }
}
