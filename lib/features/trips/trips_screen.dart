import 'package:flutter/material.dart';

import 'package:hammasir_driver/app/stores.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/utils/load_status.dart';
import 'package:hammasir_driver/core/utils/persian.dart';
import 'package:hammasir_driver/core/widgets/app_card.dart';
import 'package:hammasir_driver/core/widgets/state_views.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/data/models/driver.dart';
import 'package:hammasir_driver/features/shared/page_header.dart';
import 'package:hammasir_driver/features/shared/status_labels.dart';
import 'package:hammasir_driver/features/trips/tracking_banner.dart';
import 'package:hammasir_driver/features/trips/trip_screen.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// صفحه‌ی اصلی راننده: سفرهای امروز و فردا.
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoresScope.read(context).trips;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        Widget body;

        if (store.status == LoadStatus.loading && store.trips.isEmpty) {
          body = const CenteredLoader();
        } else if (store.status == LoadStatus.error && store.trips.isEmpty) {
          body = ErrorState(
            message: store.error ?? '',
            onRetry: store.load,
          );
        } else {
          body = RefreshIndicator(
            onRefresh: () => store.load(silent: true),
            child: _list(context, store.trips),
          );
        }

        return Column(
          children: [
            PageHeader(title: context.t('drv.trips_title')),
            Expanded(child: body),
          ],
        );
      },
    );
  }

  Widget _list(BuildContext context, List<DriverTrip> trips) {
    final children = <Widget>[const TrackingBanner()];

    if (trips.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: EmptyState(
            icon: Icons.directions_bus_outlined,
            message: context.t('drv.no_trips'),
          ),
        ),
      );
    }

    String? lastDate;
    for (final trip in trips) {
      if (trip.date != lastDate) {
        lastDate = trip.date;
        final d = DateTime.tryParse(trip.date);
        children.add(
          SectionTitle(d == null ? trip.date : Fa.dayLabel(d)),
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _TripCard(trip: trip),
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: children,
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final DriverTrip trip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = StatusLabel.trip(trip.status);
    final first = trip.stops.isEmpty ? null : trip.stops.first.name;
    final last = trip.stops.length < 2 ? null : trip.stops.last.name;

    return AppCard(
      borderColor: trip.isActive ? p.brand : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TripScreen(tripId: trip.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              const Spacer(),
              StatusChip(label: label.text, tone: label.tone),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            trip.serviceName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (first != null && last != null) ...[
            const SizedBox(height: 4),
            Text(
              '$first ← $last',
              style: TextStyle(color: p.textMuted, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people_outline, size: 16, color: p.textMuted),
              const SizedBox(width: 4),
              Text(
                context.t('drv.reserved_of', {
                  'n': Fa.digits(trip.reserved),
                  'cap': Fa.digits(trip.seats + trip.standing),
                }),
                style: TextStyle(color: p.textMuted, fontSize: 12.5),
              ),
              if (trip.plate != null) ...[
                const Spacer(),
                Icon(Icons.directions_bus_outlined,
                    size: 16, color: p.textMuted),
                const SizedBox(width: 4),
                Text(
                  Fa.digits(trip.plate),
                  style: TextStyle(color: p.textMuted, fontSize: 12.5),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
