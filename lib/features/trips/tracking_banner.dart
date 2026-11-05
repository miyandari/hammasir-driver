import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:hammasir_driver/app/stores.dart';
import 'package:hammasir_driver/core/tracking/tracking_controller.dart';
import 'package:hammasir_driver/core/tracking/tracking_policy.dart';
import 'package:hammasir_driver/core/utils/persian.dart';
import 'package:hammasir_driver/core/widgets/soft_banner.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// وضعیت زنده‌ی ردیابی: ارسال موقعیت، باتری، آفلاین بودن و مشکل دسترسی.
class TrackingBanner extends StatelessWidget {
  const TrackingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tracking = StoresScope.read(context).tracking;

    return ListenableBuilder(
      listenable: tracking,
      builder: (context, _) {
        final items = <Widget>[];

        switch (tracking.state) {
          case TrackingState.noPermission:
            items.add(
              SoftBanner(
                message: context.t('track.no_permission'),
                tone: Tone.danger,
                icon: Icons.location_disabled,
                action: TextButton(
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                    await tracking.retry();
                  },
                  child: Text(context.t('track.open_settings')),
                ),
              ),
            );
          case TrackingState.gpsOff:
            items.add(
              SoftBanner(
                message: context.t('track.gps_off'),
                tone: Tone.danger,
                icon: Icons.gps_off,
                action: TextButton(
                  onPressed: () async {
                    await Geolocator.openLocationSettings();
                    await tracking.retry();
                  },
                  child: Text(context.t('track.open_settings')),
                ),
              ),
            );
          case TrackingState.running:
            items.add(_status(context, tracking));
          case TrackingState.starting:
          case TrackingState.idle:
            break;
        }

        if (tracking.isRunning) {
          if (tracking.powerMode == PowerMode.critical) {
            items.add(
              SoftBanner(
                message: context.t(
                  'track.battery_critical',
                  {'n': Fa.digits(tracking.batteryLevel ?? 0)},
                ),
                tone: Tone.danger,
                icon: Icons.battery_alert,
              ),
            );
          } else if (tracking.powerMode == PowerMode.saver) {
            items.add(
              SoftBanner(
                message: context.t(
                  'track.battery_low',
                  {'n': Fa.digits(tracking.batteryLevel ?? 0)},
                ),
                tone: Tone.warning,
                icon: Icons.battery_3_bar,
              ),
            );
          }
        }

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            for (final w in items)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: w),
          ],
        );
      },
    );
  }

  Widget _status(BuildContext context, TrackingController t) {
    final pending = t.pending;

    if (t.offline) {
      return SoftBanner(
        message: context.t('track.offline', {'n': Fa.digits(pending)}),
        tone: Tone.warning,
        icon: Icons.cloud_off,
      );
    }

    final last = t.lastUploadAt;
    final text = last == null
        ? context.t('track.waiting_fix')
        : context.t('track.sending', {'t': Fa.time(last)});

    return SoftBanner(
      message: text,
      tone: Tone.success,
      icon: Icons.my_location,
    );
  }
}
