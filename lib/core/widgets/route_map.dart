import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:hammasir_driver/core/config/app_config.dart';
import 'package:hammasir_driver/core/widgets/osm_map_view.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';

/// یک ایستگاه روی نقشه.
class MapStop {
  const MapStop({required this.point, this.highlighted = false});

  final LatLng point;

  /// ایستگاه انتخاب‌شده‌ی دانشجو.
  final bool highlighted;
}

/// نقشه‌ی مسیر: ایستگاه‌ها، خط مسیر و (در صورت وجود) خودرو.
class RouteMap extends StatelessWidget {
  const RouteMap({
    super.key,
    required this.stops,
    this.path,
    this.vehicle,
    this.interactive = true,
  });

  final List<MapStop> stops;

  /// مسیر واقعی خیابان‌ها؛ اگر null باشد ایستگاه‌ها با خط مستقیم وصل می‌شوند.
  final List<LatLng>? path;
  final LatLng? vehicle;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final route = path ?? [for (final stop in stops) stop.point];
    final all = <LatLng>[
      for (final stop in stops) stop.point,
      ...?path,
      if (vehicle != null) vehicle!,
    ];

    if (all.isEmpty) {
      all.add(const LatLng(AppConfig.defaultLat, AppConfig.defaultLng));
    }

    final canFit = _hasSpread(all);

    return OsmMapView(
      showLocate: interactive,
      key: ValueKey('${stops.length}-${path?.length}-${vehicle == null}'),
      options: MapOptions(
        initialCenter: all.first,
        initialZoom: 15,
        initialCameraFit: canFit
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(all),
                padding: const EdgeInsets.all(56),
              )
            : null,
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
      ),
      layers: [
        if (route.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(points: route, strokeWidth: 5, color: p.brand),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final stop in stops)
              Marker(
                point: stop.point,
                width: 28,
                height: 28,
                child: _StopDot(highlighted: stop.highlighted),
              ),
            if (vehicle != null)
              Marker(
                point: vehicle!,
                width: 44,
                height: 44,
                child: const _VehicleDot(),
              ),
          ],
        ),
      ],
    );
  }

  /// اگر همه‌ی نقطه‌ها تقریباً یکی باشند، fit کردن دوربین بی‌معنی است.
  static bool _hasSpread(List<LatLng> points) {
    if (points.length < 2) return false;

    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return (maxLat - minLat) > 0.0001 || (maxLng - minLng) > 0.0001;
  }
}

class _StopDot extends StatelessWidget {
  const _StopDot({required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: highlighted ? p.accent : Colors.white,
        border: Border.all(color: p.brand, width: highlighted ? 5 : 3),
      ),
    );
  }
}

class _VehicleDot extends StatelessWidget {
  const _VehicleDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF11262B),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8),
        ],
      ),
      child: const Icon(
        Icons.directions_bus_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
