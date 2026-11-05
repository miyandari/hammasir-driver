import 'package:flutter/widgets.dart';

import 'package:hammasir_driver/state/locale_controller.dart';
import 'package:hammasir_driver/state/theme_controller.dart';

/// تنظیمات نمایشی برنامه (تم و زبان) برای صفحه‌های داخل MaterialApp.
class SettingsScope extends InheritedWidget {
  const SettingsScope({
    super.key,
    required this.theme,
    required this.locale,
    required super.child,
  });

  final ThemeController theme;
  final LocaleController locale;

  static SettingsScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope در درخت ویجت پیدا نشد');
    return scope!;
  }

  @override
  bool updateShouldNotify(SettingsScope oldWidget) {
    return theme != oldWidget.theme || locale != oldWidget.locale;
  }
}
