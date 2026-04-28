import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const medium = 840.0;

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compact) return ScreenSize.compact;
    if (width < medium) return ScreenSize.medium;
    return ScreenSize.expanded;
  }
}
