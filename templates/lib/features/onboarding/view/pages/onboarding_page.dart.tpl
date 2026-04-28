import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:__PROJECT_NAME__/core/routing/app_route.dart';
import 'package:__PROJECT_NAME__/features/onboarding/view/controllers/onboarding_controller.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      appBar: AppBar(title: Text(controller.title.value)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prima di continuare devi accettare l\\'onboarding.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Conferma di aver letto e accettato per sbloccare il pulsante di accesso alla home.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Accetto e voglio proseguire'),
                  value: controller.isAccepted.value,
                  onChanged: (value) => controller.setAccepted(value ?? false),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isAccepted.value
                        ? () => context.go(AppRoute.home.path)
                        : null,
                    child: const Text('Continua'),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
