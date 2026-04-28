import 'package:flutter/material.dart';
import 'package:flutter_launcher/core/styles/app_colors.dart';
import 'package:flutter_launcher/core/styles/app_text_styles.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_launcher/core/routing/app_route.dart';
import 'package:flutter_launcher/features/onboarding/view/controllers/onboarding_controller.dart';
import 'package:flutter_launcher/l10n/app_localizations.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();
    final l10n = AppLocalizations.of(context);
    final generalPrerequisites = <String>[
      l10n.onboardingRequirementFvm,
      l10n.onboardingRequirementInternet,
      l10n.onboardingRequirementShell,
      l10n.onboardingRequirementTargetDirectory,
    ];
    final platformToolchains = <({String platform, String requirement})>[
      (
        platform: l10n.onboardingPlatformAndroid,
        requirement: l10n.onboardingPlatformRequirementAndroid,
      ),
      (
        platform: l10n.onboardingPlatformIos,
        requirement: l10n.onboardingPlatformRequirementIos,
      ),
      (
        platform: l10n.onboardingPlatformMacos,
        requirement: l10n.onboardingPlatformRequirementMacos,
      ),
      (
        platform: l10n.onboardingPlatformWeb,
        requirement: l10n.onboardingPlatformRequirementWeb,
      ),
      (
        platform: l10n.onboardingPlatformWindows,
        requirement: l10n.onboardingPlatformRequirementWindows,
      ),
      (
        platform: l10n.onboardingPlatformLinux,
        requirement: l10n.onboardingPlatformRequirementLinux,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final showTitle = constraints.maxWidth >= 220;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FlutterLogo(size: 28),
                if (showTitle) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      l10n.onboardingTitle,
                      style: AppTextStyles.title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        backgroundColor: AppColors.flutterSky,
      ),
      backgroundColor: AppColors.surfaceTint,
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
                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        l10n.onboardingHeading,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.onboardingDescription,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.onboardingPrerequisitesTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final prerequisite in generalPrerequisites)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  prerequisite,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Card(
                        color: AppColors.darkOnSurfaceVariant,
                        surfaceTintColor: AppColors.darkOnSurfaceVariant,
                        margin: EdgeInsets.zero,
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          title: Text(
                            l10n.onboardingToolchainsTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.onPrimaryFixedVariant,
                                ),
                          ),
                          subtitle: Text(
                            l10n.onboardingToolchainsDescription,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.onPrimaryFixedVariant,
                                ),
                          ),
                          iconColor: AppColors.onPrimaryFixedVariant,
                          collapsedIconColor: AppColors.onPrimaryFixedVariant,
                          children: [
                            for (final item in platformToolchains)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.settings_suggest_outlined,
                                        size: 20,
                                        color: AppColors.onPrimaryFixedVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                color: AppColors
                                                    .onPrimaryFixedVariant,
                                              ),
                                          children: [
                                            TextSpan(
                                              text: '${item.platform}: ',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            TextSpan(text: item.requirement),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l10n.onboardingAcceptanceLabel),
                  value: controller.isAccepted.value,
                  onChanged: (value) => controller.setAccepted(value ?? false),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        AppColors.flutterSky,
                      ),
                      foregroundColor: WidgetStatePropertyAll(
                        AppColors.onPrimary,
                      ),
                      mouseCursor: WidgetStatePropertyAll(
                        controller.isAccepted.value
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                      ),
                    ),
                    onPressed: controller.isAccepted.value
                        ? () => context.go(AppRoute.home.path)
                        : null,
                    child: Text(l10n.onboardingContinue),
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
