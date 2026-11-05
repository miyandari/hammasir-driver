import 'package:shamsi_date/shamsi_date.dart';

import 'package:hammasir_driver/l10n/l10n.dart';

/// قالب‌بندی تاریخ، ساعت و عدد بر اساس زبان فعلی اپ:
/// فارسی ← ارقام فارسی و تاریخ شمسی؛ انگلیسی ← ارقام لاتین و تاریخ میلادی.
class Fa {
  Fa._();

  static const List<String> _faDigits = [
    '۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹', //
  ];
  static const List<String> _faMonths = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', //
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند', //
  ];
  static const List<String> _enMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  /// در فارسی همه‌ی ارقام داخل متن را فارسی می‌کند؛ در انگلیسی دست نمی‌زند.
  static String digits(Object? value) {
    final text = value?.toString() ?? '';
    if (!L10n.isFa) return text;

    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final digit = int.tryParse(char);
      buffer.write(digit == null ? char : _faDigits[digit]);
    }
    return buffer.toString();
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// مثل «۱۰ آبان ۱۴۰۵» یا «10 Nov 2026»
  static String date(DateTime dateTime) {
    if (L10n.isFa) {
      final j = Jalali.fromDateTime(dateTime);
      return '${digits(j.day)} ${_faMonths[j.month - 1]} ${digits(j.year)}';
    }
    return '${dateTime.day} ${_enMonths[dateTime.month - 1]} ${dateTime.year}';
  }

  /// مثل «۱۴۰۵/۰۸/۱۰» یا «2026-11-01»
  static String shortDate(DateTime dateTime) {
    if (L10n.isFa) {
      final j = Jalali.fromDateTime(dateTime);
      return digits('${j.year}/${_two(j.month)}/${_two(j.day)}');
    }
    return '${dateTime.year}-${_two(dateTime.month)}-${_two(dateTime.day)}';
  }

  /// مثل «۰۷:۳۰»
  static String time(DateTime dateTime) {
    return digits('${_two(dateTime.hour)}:${_two(dateTime.minute)}');
  }

  /// «امروز»، «فردا»، «دیروز» یا روز و ماه.
  static String dayLabel(DateTime dateTime, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final target = _dateOnly(dateTime);
    final diff = target.difference(today).inDays;

    if (diff == 0) return L10n.t('time.today');
    if (diff == 1) return L10n.t('time.tomorrow');
    if (diff == -1) return L10n.t('time.yesterday');

    if (L10n.isFa) {
      final j = Jalali.fromDateTime(dateTime);
      return '${digits(j.day)} ${_faMonths[j.month - 1]}';
    }
    return '${dateTime.day} ${_enMonths[dateTime.month - 1]}';
  }

  /// مثل «امروز، ۰۷:۳۰»
  static String dayAndTime(DateTime dateTime, {DateTime? now}) {
    final comma = L10n.isFa ? '،' : ',';
    return '${dayLabel(dateTime, now: now)}$comma ${time(dateTime)}';
  }

  /// زمان نسبی برای اعلان‌ها: «۵ دقیقه پیش».
  static String relative(DateTime dateTime, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(dateTime);

    if (diff.inSeconds < 60) return L10n.t('time.just_now');
    if (diff.inMinutes < 60) {
      return L10n.t('time.minutes_ago', {'n': digits(diff.inMinutes)});
    }
    if (diff.inHours < 24) {
      return L10n.t('time.hours_ago', {'n': digits(diff.inHours)});
    }
    if (diff.inDays < 7) {
      return L10n.t('time.days_ago', {'n': digits(diff.inDays)});
    }
    return shortDate(dateTime);
  }

  /// مثل «۴ دقیقه» یا «کمتر از ۱ دقیقه».
  static String duration(int seconds) {
    if (seconds < 60) return L10n.t('time.less_than_minute');
    return L10n.t('time.minutes', {'n': digits((seconds / 60).round())});
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
