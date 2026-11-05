import 'package:flutter/material.dart';

import 'package:hammasir_driver/core/storage/settings_store.dart';
import 'package:hammasir_driver/core/utils/safe_notifier.dart';

class ThemeController extends ChangeNotifier with SafeNotifier {
  ThemeController(this._store);

  final SettingsStore _store;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    _mode = await _store.readThemeMode();
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _store.saveThemeMode(mode);
  }
}
