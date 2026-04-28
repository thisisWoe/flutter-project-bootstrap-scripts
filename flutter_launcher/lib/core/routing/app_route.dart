enum AppRoute {
  onboarding('/onboarding'),
  home('/home'),
  profile('/profile');

  final String path;

  const AppRoute(this.path);
}
