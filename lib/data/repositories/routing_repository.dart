import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:hammasir_driver/core/config/app_config.dart';
import 'package:hammasir_driver/core/utils/json_utils.dart';

/// مسیر واقعی خیابان‌ها بین ایستگاه‌ها (OSRM).
///
/// هر خطا (قطع اینترنت، محدودیت سرور) به null تبدیل می‌شود و نقشه خط مستقیم
/// می‌کشد. نتیجه‌ی موفق در حافظه cache می‌شود.
class RoutingRepository {
  RoutingRepository({http.Client? client}) : _client = client ?? http.Client();

  static const int maxPoints = 40;
  static const Duration _retryDelay = Duration(minutes: 2);

  final http.Client _client;
  final Map<String, List<LatLng>> _cache = {};
  final Map<String, DateTime> _failedAt = {};

  Future<List<LatLng>?> drivingPath(List<LatLng> points) async {
    if (points.length < 2) return null;

    final sampled = _sample(points);
    final key = sampled
        .map((p) => '${p.latitude.toStringAsFixed(5)},'
            '${p.longitude.toStringAsFixed(5)}')
        .join(';');

    final cached = _cache[key];
    if (cached != null) return cached;

    final failed = _failedAt[key];
    if (failed != null && DateTime.now().difference(failed) < _retryDelay) {
      return null;
    }

    try {
      final coords =
          sampled.map((p) => '${p.longitude},${p.latitude}').join(';');
      final uri = Uri.parse(
        '${AppConfig.routingBaseUrl}/route/v1/driving/$coords'
        '?overview=full&geometries=geojson',
      );

      final response = await _client.get(uri).timeout(AppConfig.routingTimeout);
      if (response.statusCode != 200) throw const FormatException('status');

      final routes = asMapList(asMap(jsonDecode(response.body))?['routes']);
      final coordinates = asMap(routes.first['geometry'])?['coordinates'];
      if (coordinates is! List) throw const FormatException('geometry');

      final path = <LatLng>[];
      for (final item in coordinates) {
        if (item is List && item.length >= 2) {
          final lng = asDouble(item[0]);
          final lat = asDouble(item[1]);
          if (lat != null && lng != null) path.add(LatLng(lat, lng));
        }
      }
      if (path.length < 2) throw const FormatException('empty');

      _cache[key] = path;
      return path;
    } catch (_) {
      _failedAt[key] = DateTime.now();
      return null;
    }
  }

  /// اگر ایستگاه‌ها زیاد باشند، به‌طور مساوی نمونه می‌گیرد (اولی و آخری حفظ می‌شود).
  static List<LatLng> _sample(List<LatLng> points) {
    if (points.length <= maxPoints) return points;

    final result = <LatLng>[];
    final step = (points.length - 1) / (maxPoints - 1);
    for (var i = 0; i < maxPoints; i++) {
      result.add(points[(i * step).round()]);
    }
    return result;
  }

  void close() => _client.close();
}
