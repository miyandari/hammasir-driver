import 'package:latlong2/latlong.dart';

import 'package:hammasir_driver/core/utils/json_utils.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

class Station {
  const Station({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;

  LatLng? get point {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name'], L10n.t('common.station')),
      address: asNullableString(json['address']),
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
    );
  }
}

/// یک ایستگاه در ترتیب مسیر (`/route-stations/`).
class RouteStop {
  const RouteStop({
    required this.stationId,
    required this.order,
    this.minutesFromStart,
  });

  final int stationId;
  final int order;
  final int? minutesFromStart;

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      stationId: asInt(json['station_id']) ?? 0,
      order: asInt(json['stop_order']) ?? 0,
      minutesFromStart: asInt(json['estimated_minutes_from_start']),
    );
  }
}

/// ایستگاه + ترتیب آن در یک مسیر؛ برای نمایش لیست و نقشه.
class RouteStationInfo {
  const RouteStationInfo({required this.station, required this.stop});

  final Station station;
  final RouteStop stop;
}
