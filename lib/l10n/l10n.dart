import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';

import 'package:hammasir_driver/l10n/strings_en.dart';
import 'package:hammasir_driver/l10n/strings_fa.dart';

/// ترجمه‌ها (فارسی/انگلیسی) بدون تولید کد.
///
/// - `context.t('کلید')` در ویجت‌ها (با تغییر زبان، صفحه دوباره ساخته می‌شود)
/// - `L10n.t('کلید')` در جاهایی که context نیست (مثلاً پیام خطای شبکه)
class L10n {
  L10n._();

  static const List<Locale> supported = [Locale('fa'), Locale('en')];

  /// زبان فعلی؛ فقط توسط delegate تنظیم می‌شود.
  static String lang = 'fa';

  static bool get isFa => lang != 'en';

  static String t(String key, [Map<String, Object?>? args]) {
    var text = (isFa ? stringsFa[key] : stringsEn[key]) ?? stringsFa[key] ?? key;

    if (args != null) {
      args.forEach((name, value) {
        text = text.replaceAll('{$name}', '${value ?? ''}');
      });
    }
    return text;
  }
}

/// شیء خالی برای ثبت وابستگی به Localizations.
class AppLocalizations {
  const AppLocalizations();
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'fa' || locale.languageCode == 'en';
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    L10n.lang = locale.languageCode == 'en' ? 'en' : 'fa';
    return SynchronousFuture<AppLocalizations>(const AppLocalizations());
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const LocalizationsDelegate<AppLocalizations> appLocalizationsDelegate =
    _AppLocalizationsDelegate();

extension TranslateContext on BuildContext {
  /// ترجمه‌ی کلید؛ با تغییر زبان، ویجت دوباره ساخته می‌شود.
  String t(String key, [Map<String, Object?>? args]) {
    Localizations.of<AppLocalizations>(this, AppLocalizations);
    return L10n.t(key, args);
  }
}
