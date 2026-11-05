import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationResult { ok, denied, serviceOff, failed }

/// موقعیت فعلی کاربر برای نمایش روی نقشه. همه‌ی خطاها به [LocationResult] تبدیل می‌شوند.
class LocationService {
  LocationService._();

  static Future<(LocationResult, LatLng?)> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return (LocationResult.serviceOff, null);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (LocationResult.denied, null);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return (LocationResult.ok, LatLng(position.latitude, position.longitude));
    } catch (_) {
      return (LocationResult.failed, null);
    }
  }
}
