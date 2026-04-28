import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_launcher/features/home/view/controllers/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(title: Text(controller.title.value)),
      body: Center(
        child: Obx(() => Text(controller.title.value)),
      ),
    );
  }
}
