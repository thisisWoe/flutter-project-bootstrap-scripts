import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_launcher/features/profile/view/controllers/profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(title: Text(controller.title.value)),
      body: Center(
        child: Obx(() => Text(controller.title.value)),
      ),
    );
  }
}
