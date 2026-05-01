import 'package:flutter/widgets.dart';

/// Bootstrap-style breakpoints + modern extras (2025).
///
///  * **xs**   < 576 px  (phones portrait)
///  * **sm** >= 576 px  (phones landscape / small tablets)
///  * **md** >= 768 px  (tablets portrait)
///  * **lg** >= 992 px  (tablets landscape / small laptops)
///  * **xl** >= 1200 px (laptops / desktops)
///  * **xxl** >= 1400 px (large desktops)
///  * **xxxl** >= 1920 px (Full-HD & ultrawide)
///  * **u4k** >= 2560 px (4K & up)
///
/// Use `context.screenSize` or the convenience getters (`isMd`, `isLg`, ecc.).
enum ScreenSize { xs, sm, md, lg, xl, xxl, xxxl, u4k }

abstract final class AppBreakpoints {
  // Core Bootstrap v5 breakpoints
  static const double xs = 0; // implicit
  static const double sm = 576;
  static const double md = 768;
  static const double lg = 992;
  static const double xl = 1200;
  static const double xxl = 1400;

  // Modern extras
  static const double xxxl = 1920; // 1080p / ultrawide
  static const double u4k = 2560; // 4K & UHD-2

  /// Returns the [ScreenSize] category for a given width.
  static ScreenSize of(double width) {
    if (width >= u4k) return ScreenSize.u4k;
    if (width >= xxxl) return ScreenSize.xxxl;
    if (width >= xxl) return ScreenSize.xxl;
    if (width >= xl) return ScreenSize.xl;
    if (width >= lg) return ScreenSize.lg;
    if (width >= md) return ScreenSize.md;
    if (width >= sm) return ScreenSize.sm;
    return ScreenSize.xs;
  }
}

extension BreakpointUtils on BuildContext {
  /// Current screen size category.
  ScreenSize get screenSize =>
      AppBreakpoints.of(MediaQuery.of(this).size.width);

  bool get isXs => screenSize == ScreenSize.xs;

  bool get isSm => screenSize == ScreenSize.sm;

  bool get isMd => screenSize == ScreenSize.md;

  bool get isLg => screenSize == ScreenSize.lg;

  bool get isXl => screenSize == ScreenSize.xl;

  bool get isXxl => screenSize == ScreenSize.xxl;

  bool get isXxxl => screenSize == ScreenSize.xxxl;

  bool get isU4k => screenSize == ScreenSize.u4k;

  /// Restituisce la sezione corrente come stringa (es. "xs", "sm", ...)
  String get screenSizeSection {
    return screenSize.name;
  }

  /// Composite helpers
  bool get breakpointIsMobile => isXs || isSm;

  bool get breakpointIsTablet => isMd || isLg;

  /// **Desktop** = xl and up (>= 1200 px)
  bool get breakpointIsDesktop => isXl || isXxl || isXxxl || isU4k;
}
