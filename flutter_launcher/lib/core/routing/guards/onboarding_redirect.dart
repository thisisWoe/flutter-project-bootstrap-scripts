import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_launcher/core/routing/app_route.dart';
import 'package:flutter_launcher/core/utils/app_key_store.dart';

String? redirectOnboardingGuard(BuildContext context, GoRouterState state) {
  final preferences = Get.find<SharedPreferences>();
  final hasAcceptedOnboarding =
      preferences.getBool(AppKeyStore.onboardingAccepted) ?? false;
  final isOnboardingRoute = state.matchedLocation == AppRoute.onboarding.path;

  if (!hasAcceptedOnboarding && !isOnboardingRoute) {
    return AppRoute.onboarding.path;
  }

  if (hasAcceptedOnboarding && isOnboardingRoute) {
    return AppRoute.home.path;
  }

  return null;
}
