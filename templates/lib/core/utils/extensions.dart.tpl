import 'package:flutter/widgets.dart';

extension BuildContextScreenSize on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
}
