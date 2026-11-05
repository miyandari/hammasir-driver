import 'package:hammasir_driver/core/network/api_client.dart';
import 'package:hammasir_driver/core/network/api_exception.dart';
import 'package:hammasir_driver/core/tracking/tracking_policy.dart';
import 'package:hammasir_driver/core/utils/json_utils.dart';
import 'package:hammasir_driver/data/models/driver.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// نتیجه‌ی ارسال یک دسته موقعیت.
class LocationUploadResult {
  const LocationUploadResult({
    required this.accepted,
    required this.rejected,
    required this.tripActive,
  });

  final int accepted;
  final int rejected;

  /// false یعنی سفر دیگر در حال سوار کردن/حرکت نیست و باید ردیابی بایستد.
  final bool tripActive;
}

/// همه‌ی درخواست‌های مخصوص راننده.
class DriverRepository {
  DriverRepository(this._api);

  final ApiClient _api;

  Future<DriverMe> me() async {
    final map = asMap(await _api.get('/driver/me'));
    if (map == null) throw ApiException(L10n.t('err.profile_failed'));
    return DriverMe.fromJson(map);
  }

  Future<List<DriverTrip>> trips({int days = 2}) async {
    final data = await _api.get('/driver/trips', query: {'days': '$days'});
    final list = data is List ? data : const [];
    return [
      for (final item in list)
        if (asMap(item) != null) DriverTrip.fromJson(asMap(item)!),
    ];
  }

  Future<DriverTrip> trip(int id) async {
    final map = asMap(await _api.get('/driver/trips/$id'));
    if (map == null) throw ApiException(L10n.t('err.profile_failed'));
    return DriverTrip.fromJson(map);
  }

  Future<void> setStatus(int tripId, String status) async {
    await _api.post('/driver/trips/$tripId/status', body: {'status': status});
  }

  Future<Manifest> manifest(int tripId) async {
    final map = asMap(await _api.get('/driver/trips/$tripId/manifest'));
    if (map == null) throw ApiException(L10n.t('err.profile_failed'));
    return Manifest.fromJson(map);
  }

  Future<void> board({
    required int tripId,
    required int studentId,
    int? stationId,
  }) async {
    await _api.post(
      '/trip-passengers/$tripId/board',
      body: {
        'student_id': studentId,
        'boarding_method': 'manual',
        if (stationId != null) 'boarding_station_id': stationId,
      },
    );
  }

  Future<void> decideRequest(int requestId, {required bool approve}) async {
    await _api.post(
      '/boarding-requests/$requestId/${approve ? 'approve' : 'reject'}',
      body: approve ? null : {'approved': false},
    );
  }

  Future<LocationUploadResult> uploadLocations(
    int tripId,
    List<TrackPoint> points,
  ) async {
    final map = asMap(
      await _api.post(
        '/driver/trips/$tripId/locations',
        body: {
          'points': [for (final p in points) p.toApi()],
        },
      ),
    );
    return LocationUploadResult(
      accepted: asInt(map?['accepted']) ?? 0,
      rejected: asInt(map?['rejected']) ?? 0,
      tripActive: asBool(map?['trip_active'], true),
    );
  }

  Future<void> reportBreakdown(
    int tripId,
    Map<String, dynamic> payload,
  ) async {
    await _api.post('/driver/trips/$tripId/breakdown', body: payload);
  }
}
