import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:hammasir_driver/core/config/app_config.dart';
import 'package:hammasir_driver/core/location/location_service.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// نقشه‌ی OpenStreetMap با لایه‌های دلخواه، موقعیت کاربر (نقطه‌ی آبی) و دکمه‌ی «موقعیت من».
/// اگر تایل‌ها بارگذاری نشوند پیام می‌دهد.
class OsmMapView extends StatefulWidget {
  const OsmMapView({
    super.key,
    required this.options,
    required this.layers,
    this.buttonBottom = 12,
    this.showLocate = true,
  });

  final MapOptions options;
  final List<Widget> layers;

  /// فاصله‌ی دکمه‌ی «موقعیت من» از پایین (برای نقشه‌ای که کشو روی آن می‌آید).
  final double buttonBottom;
  final bool showLocate;

  @override
  State<OsmMapView> createState() => _OsmMapViewState();
}

class _OsmMapViewState extends State<OsmMapView> {
  final MapController _controller = MapController();

  int _errors = 0;
  LatLng? _me;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.showLocate) _locate(moveCamera: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onError(TileImage tile, Object error, StackTrace? stackTrace) {
    if (!mounted) return;
    // چند خطای پشت‌سرهم یعنی تایل‌ها اصلاً نمی‌آیند (فیلتر یا قطع اینترنت).
    if (_errors < 6) setState(() => _errors++);
  }

  Future<void> _locate({required bool moveCamera}) async {
    if (_locating) return;
    setState(() => _locating = true);

    final (result, point) = await LocationService.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (point != null) _me = point;
    });

    if (point != null && moveCamera) {
      try {
        _controller.move(point, 16);
      } catch (_) {
        // نقشه هنوز آماده نیست.
      }
    } else if (point == null && moveCamera && result != LocationResult.ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(L10n.t('map.location_denied'))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: widget.options,
          children: [
            TileLayer(
              urlTemplate: AppConfig.tileUrl,
              fallbackUrl: AppConfig.tileFallbackUrl,
              userAgentPackageName: AppConfig.userAgentPackage,
              errorTileCallback: _onError,
              tileDisplay: const TileDisplay.fadeIn(),
            ),
            ...widget.layers,
            if (_me != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _me!,
                    width: 28,
                    height: 28,
                    child: const _MyLocationDot(),
                  ),
                ],
              ),
            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap'),
              alignment: Alignment.bottomLeft,
            ),
          ],
        ),
        if (widget.showLocate)
          Positioned(
            right: 12,
            bottom: widget.buttonBottom,
            child: Material(
              color: p.surface,
              elevation: 3,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: L10n.t('map.my_location'),
                onPressed: () => _locate(moveCamera: true),
                icon: _locating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.my_location_rounded, color: p.brand),
              ),
            ),
          ),
        if (_errors >= 6)
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Material(
              color: p.warningSoft,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  L10n.t('map.tiles_failed'),
                  style: TextStyle(fontSize: 12, color: p.warning),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A73E8),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
    );
  }
}
