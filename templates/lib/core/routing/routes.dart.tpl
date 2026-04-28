import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:__PROJECT_NAME__/core/routing/app_route.dart';
import 'package:__PROJECT_NAME__/core/routing/go_router_observer.dart';
import 'package:__PROJECT_NAME__/features/home/view/bindings/home_bindings.dart';
import 'package:__PROJECT_NAME__/features/home/view/pages/home_page.dart';
import 'package:__PROJECT_NAME__/features/onboarding/view/bindings/onboarding_bindings.dart';
import 'package:__PROJECT_NAME__/features/onboarding/view/pages/onboarding_page.dart';
import 'package:__PROJECT_NAME__/features/profile/view/bindings/profile_bindings.dart';
import 'package:__PROJECT_NAME__/features/profile/view/pages/profile_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRootRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.onboarding.path,
    observers: [GoRouterObserver()],
    routes: [
      GoRoute(
        path: AppRoute.onboarding.path,
        name: AppRoute.onboarding.name,
        pageBuilder: (context, state) {
          const OnboardingBindings().dependencies();
          return const MaterialPage(child: OnboardingPage());
        },
      ),
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.name,
        pageBuilder: (context, state) {
          const HomeBindings().dependencies();
          return const MaterialPage(child: HomePage());
        },
      ),
      GoRoute(
        path: AppRoute.profile.path,
        name: AppRoute.profile.name,
        pageBuilder: (context, state) {
          const ProfileBindings().dependencies();
          return const MaterialPage(child: ProfilePage());
        },
      ),
    ],
  );
}
