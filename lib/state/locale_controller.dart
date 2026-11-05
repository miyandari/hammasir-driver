import 'package:flutter/material.dart';

import 'package:hammasir_driver/core/storage/settings_store.dart';
import 'package:hammasir_driver/core/utils/safe_notifier.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// زبان برنامه (فارسی/انگلیسی) و اینکه کاربر زبان را انتخاب کرده یا نه.
class LocaleController extends ChangeNotifier with SafeNotifier {
  LocaleController(this._store);

  final SettingsStore _store;

  String _code = 'fa';
  bool _chosen = false;
  bool _loaded = false;

  Locale get locale => Locale(_code);
  String get code => _code;

  /// کاربر قبلاً زبان را انتخاب کرده است (برای نمایش صفحه‌ی انتخاب زبان).
  bool get chosen => _chosen;
  bool get loaded => _loaded;

  Future<void> load() async {
    final saved = await _store.readLanguage();
    if (saved != null) {
      _code = saved;
      _chosen = true;
    }
    L10n.lang = _code;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (code != 'fa' && code != 'en') return;
    _code = code;
    _chosen = true;
    L10n.lang = code;
    notifyListeners();
    await _store.saveLanguage(code);
  }
}
