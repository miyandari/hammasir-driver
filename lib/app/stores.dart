import 'package:flutter/widgets.dart';

import 'package:hammasir_driver/app/deps.dart';
import 'package:hammasir_driver/core/tracking/tracking_controller.dart';
import 'package:hammasir_driver/data/repositories/breakdown_outbox.dart';
import 'package:hammasir_driver/state/notifications_store.dart';
import 'package:hammasir_driver/state/session_controller.dart';
import 'package:hammasir_driver/state/trips_store.dart';

/// ذخیره‌گاه‌های وابسته به کاربر وارد شده؛ با خروج دور ریخته می‌شوند.
class Stores {
  Stores(Deps deps, {required this.session})
      : notifications = NotificationsStore(deps.notifications),
        trips = TripsStore(deps.driver),
        tracking = TrackingController(repository: deps.driver),
        outbox = BreakdownOutbox(deps.driver) {
    // سرور گفت سفر تمام شده: فهرست را تازه کن.
    tracking.onTripEnded = () => trips.load(silent: true);
  }

  final SessionController session;
  final NotificationsStore notifications;
  final TripsStore trips;
  final TrackingController tracking;
  final BreakdownOutbox outbox;

  /// ردیابی را با سفر فعال هماهنگ می‌کند: سفر فعال ← شروع، وگرنه توقف.
  Future<void> syncTracking() async {
    final active = trips.active;
    if (active != null) {
      await tracking.start(active.id);
    } else if (tracking.tripId != null) {
      await tracking.stop();
    }
  }

  void dispose() {
    tracking.stop(flush: false);
    notifications.dispose();
    trips.dispose();
    tracking.dispose();
  }
}

class StoresScope extends InheritedWidget {
  const StoresScope({super.key, required this.stores, required super.child});

  final Stores stores;

  static Stores read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<StoresScope>();
    assert(scope != null, 'StoresScope در درخت ویجت پیدا نشد');
    return scope!.stores;
  }

  @override
  bool updateShouldNotify(StoresScope oldWidget) => stores != oldWidget.stores;
}
