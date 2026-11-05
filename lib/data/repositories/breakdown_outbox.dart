import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:hammasir_driver/core/network/api_exception.dart';
import 'package:hammasir_driver/data/repositories/driver_repository.dart';

/// گزارش‌های خرابی که هنوز به سرور نرسیده‌اند (نبود اینترنت).
/// تا موفقیت ارسال، روی دستگاه می‌مانند و دوباره تلاش می‌شوند.
class BreakdownOutbox {
  BreakdownOutbox(this._repo);

  static const String _key = 'breakdown_outbox';

  final DriverRepository _repo;

  Future<List<Map<String, dynamic>>> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return [
        for (final item in list)
          if (item is Map) Map<String, dynamic>.from(item),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (items.isEmpty) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, jsonEncode(items));
      }
    } catch (_) {}
  }

  Future<int> count() async => (await _read()).length;

  /// ارسال فوری؛ اگر شبکه نبود در صف می‌ماند و true (= صف شد) برمی‌گردد.
  /// خطای غیرشبکه‌ای (مثل ۴۰۳) به بالا پرتاب می‌شود.
  Future<bool> submit(int tripId, Map<String, dynamic> payload) async {
    try {
      await _repo.reportBreakdown(tripId, payload);
      return false;
    } on ApiException catch (e) {
      if (!e.isNetwork) rethrow;
      final items = await _read();
      items.add({'trip_id': tripId, 'payload': payload});
      await _write(items);
      return true;
    }
  }

  /// تلاش دوباره برای صف؛ تعداد ارسال‌شده‌ها را برمی‌گرداند.
  Future<int> flush() async {
    final items = await _read();
    if (items.isEmpty) return 0;

    final left = <Map<String, dynamic>>[];
    var sent = 0;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      try {
        await _repo.reportBreakdown(
          item['trip_id'] as int,
          Map<String, dynamic>.from(item['payload'] as Map),
        );
        sent++;
      } on ApiException catch (e) {
        if (e.isNetwork) {
          left.addAll(items.sublist(i));
          break;
        }
        // خطای دائمی: دور ریخته می‌شود.
      } catch (_) {}
    }
    await _write(left);
    return sent;
  }
}
