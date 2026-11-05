import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:hammasir_driver/app/deps.dart';
import 'package:hammasir_driver/app/stores.dart';
import 'package:hammasir_driver/core/network/api_exception.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/utils/persian.dart';
import 'package:hammasir_driver/core/widgets/app_card.dart';
import 'package:hammasir_driver/core/widgets/route_map.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/data/models/driver.dart';
import 'package:hammasir_driver/features/breakdown/breakdown_screen.dart';
import 'package:hammasir_driver/features/shared/page_header.dart';
import 'package:hammasir_driver/features/shared/status_labels.dart';
import 'package:hammasir_driver/features/shared/ui_helpers.dart';
import 'package:hammasir_driver/features/trips/tracking_banner.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// جزئیات سفر: نقشه، دکمه‌ی وضعیت، مسافران و درخواست‌های سوار شدن.
class TripScreen extends StatefulWidget {
  const TripScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  late final Stores _stores = StoresScope.read(context);
  late final Deps _deps = DepsScope.read(context);

  Manifest? _manifest;
  List<LatLng>? _path;
  bool _busy = false;
  Timer? _poll;

  DriverTrip? get _trip {
    for (final t in _stores.trips.trips) {
      if (t.id == widget.tripId) return t;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadManifest();
    _loadPath();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_trip?.isActive ?? false) _loadManifest();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _loadManifest() async {
    try {
      final m = await _deps.driver.manifest(widget.tripId);
      if (mounted) setState(() => _manifest = m);
    } on ApiException {
      // فهرست مسافران حیاتی نیست؛ با تلاش بعدی تازه می‌شود.
    }
  }

  Future<void> _loadPath() async {
    final trip = _trip;
    if (trip == null || trip.stops.length < 2) return;
    final path = await _deps.routing.drivingPath(
      [for (final s in trip.stops) s.point],
    );
    if (mounted) setState(() => _path = path);
  }

  Future<void> _advance(DriverTrip trip) async {
    final next = trip.nextStatus;
    if (next == null || _busy) return;

    final ok = await confirm(
      context,
      title: context.t('drv.confirm_$next'),
      message: context.t('drv.confirm_${next}_msg'),
      confirmLabel: context.t('drv.action_$next'),
      icon: Icons.directions_bus_rounded,
      tone: next == TripStatus.completed ? Tone.warning : Tone.brand,
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await _deps.driver.setStatus(trip.id, next);
      await _stores.trips.load(silent: true);
      await _stores.syncTracking();
      await _loadManifest();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _board(ManifestPassenger p) async {
    try {
      await _deps.driver.board(
        tripId: widget.tripId,
        studentId: p.studentId,
        stationId: p.stationId,
      );
      await _loadManifest();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, tone: Tone.danger);
    }
  }

  Future<void> _decide(PendingRequest r, bool approve) async {
    try {
      await _deps.driver.decideRequest(r.id, approve: approve);
      await _loadManifest();
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_stores.trips, _stores.tracking]),
      builder: (context, _) {
        final trip = _trip;
        if (trip == null) {
          return Scaffold(appBar: AppBar());
        }
        return Scaffold(
          appBar: AppBar(title: Text(trip.serviceName)),
          body: _body(context, trip),
        );
      },
    );
  }

  Widget _body(BuildContext context, DriverTrip trip) {
    final p = context.palette;
    final label = StatusLabel.trip(trip.status);
    final vehicle = _stores.tracking.lastFix?.latLng;
    final manifest = _manifest;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (trip.isActive) const TrackingBanner(),
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: RouteMap(
              stops: [for (final s in trip.stops) MapStop(point: s.point)],
              path: _path,
              vehicle: vehicle,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              Fa.digits(trip.plannedTime),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: p.brand,
              ),
            ),
            const SizedBox(width: 10),
            StatusChip(label: label.text, tone: label.tone),
          ],
        ),
        const SizedBox(height: 12),
        if (trip.nextStatus != null)
          FilledButton.icon(
            onPressed: _busy ? null : () => _advance(trip),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(context.t('drv.action_${trip.nextStatus}')),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        if (trip.isActive) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BreakdownScreen(trip: trip),
              ),
            ),
            icon: Icon(Icons.warning_amber_rounded, color: p.danger),
            label: Text(
              context.t('bd.report'),
              style: TextStyle(color: p.danger, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: p.danger),
            ),
          ),
        ],
        SectionTitle(context.t('drv.stops')),
        AppCard(
          child: Column(
            children: [
              for (final s in trip.stops)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: p.brand),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s.name)),
                      Text(
                        context.t('drv.plus_min', {
                          'n': Fa.digits(s.minutesFromStart),
                        }),
                        style: TextStyle(color: p.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (manifest != null && manifest.pending.isNotEmpty) ...[
          SectionTitle(context.t('drv.requests')),
          for (final r in manifest.pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            r.stationName,
                            style: TextStyle(color: p.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _decide(r, false),
                      icon: Icon(Icons.close, color: p.danger),
                      tooltip: context.t('drv.reject'),
                    ),
                    IconButton(
                      onPressed: () => _decide(r, true),
                      icon: Icon(Icons.check_circle, color: p.success),
                      tooltip: context.t('drv.approve'),
                    ),
                  ],
                ),
              ),
            ),
        ],
        SectionTitle(
          manifest == null
              ? context.t('drv.passengers')
              : context.t('drv.passengers_count', {
                  'b': Fa.digits(manifest.boardedCount),
                  'n': Fa.digits(manifest.passengers.length),
                }),
        ),
        if (manifest != null && manifest.passengers.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              context.t('drv.no_passengers'),
              style: TextStyle(color: p.textMuted),
            ),
          ),
        if (manifest != null)
          for (final m in manifest.passengers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${m.stationName}${m.standing ? ' · ${context.t('drv.standing')}' : ''}',
                            style: TextStyle(color: p.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (m.boarded)
                      StatusChip(
                        label: context.t('drv.boarded'),
                        tone: Tone.success,
                      )
                    else if (trip.isActive)
                      OutlinedButton(
                        onPressed: () => _board(m),
                        child: Text(context.t('drv.mark_boarded')),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
