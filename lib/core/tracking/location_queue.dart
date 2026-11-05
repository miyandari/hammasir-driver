import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:hammasir_driver/core/tracking/tracking_policy.dart';

/// صف ماندگار نقاط ارسال‌نشده (وقتی اینترنت نیست یا اپ بسته می‌شود).
///
/// نقاط با زمان واقعی ثبتشان ذخیره می‌شوند و بعداً دسته‌ای ارسال می‌شوند.
class LocationQueue {
  LocationQueue({this.maxPoints = 2000});

  static const String _prefix = 'track_queue_';
  static const String _activeKey = 'track_active_trip';

  final int maxPoints;
  final List<TrackPoint> _points = [];
  int? _tripId;

  int get length => _points.length;
  int? get tripId => _tripId;
  bool get isEmpty => _points.isEmpty;

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// سفری که ردیابی‌اش فعال بوده (برای ادامه بعد از بستن اپ).
  Future<int?> activeTrip() async {
    final prefs = await _prefs();
    return prefs?.getInt(_activeKey);
  }

  Future<void> open(int tripId) async {
    _tripId = tripId;
    _points.clear();
    final prefs = await _prefs();
    await prefs?.setInt(_activeKey, tripId);

    final raw = prefs?.getString('$_prefix$tripId');
    if (raw == null) return;
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        for (final item in list) {
          final p = TrackPoint.fromStore(item);
          if (p != null) _points.add(p);
        }
      }
    } catch (_) {
      // صف خراب؛ نادیده گرفته می‌شود.
    }
  }

  /// نقطه را اضافه می‌کند؛ اگر صف پر شد قدیمی‌ترین‌ها یک‌درمیان حذف می‌شوند
  /// تا شکل کلی مسیر حفظ شود.
  void add(TrackPoint point) {
    _points.add(point);
    if (_points.length > maxPoints) {
      final kept = <TrackPoint>[];
      final half = _points.length ~/ 2;
      for (var i = 0; i < half; i++) {
        if (i.isEven) kept.add(_points[i]);
      }
      kept.addAll(_points.sublist(half));
      _points
        ..clear()
        ..addAll(kept);
    }
  }

  List<TrackPoint> peek(int count) =>
      List.unmodifiable(_points.take(count).toList());

  void removeFirst(int count) {
    _points.removeRange(0, count.clamp(0, _points.length));
  }

  Future<void> save() async {
    final id = _tripId;
    if (id == null) return;
    final prefs = await _prefs();
    if (prefs == null) return;
    if (_points.isEmpty) {
      await prefs.remove('$_prefix$id');
    } else {
      await prefs.setString(
        '$_prefix$id',
        jsonEncode([for (final p in _points) p.toStore()]),
      );
    }
  }

  /// پایان ردیابی: صف و نشانه‌ی سفر فعال پاک می‌شود.
  Future<void> close({bool discard = true}) async {
    final id = _tripId;
    final prefs = await _prefs();
    await prefs?.remove(_activeKey);
    if (discard && id != null) await prefs?.remove('$_prefix$id');
    _points.clear();
    _tripId = null;
  }
}
