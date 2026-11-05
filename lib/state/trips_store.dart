import 'package:hammasir_driver/core/network/api_exception.dart';
import 'package:hammasir_driver/core/utils/load_status.dart';
import 'package:hammasir_driver/core/utils/safe_notifier.dart';
import 'package:flutter/foundation.dart';

import 'package:hammasir_driver/data/models/driver.dart';
import 'package:hammasir_driver/data/repositories/driver_repository.dart';

/// سفرهای امروز و فردای راننده.
class TripsStore extends ChangeNotifier with SafeNotifier {
  TripsStore(this._repo);

  final DriverRepository _repo;

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  List<DriverTrip> _trips = const [];
  DriverMe? _me;

  LoadStatus get status => _status;
  String? get error => _error;
  List<DriverTrip> get trips => _trips;
  DriverMe? get me => _me;

  /// سفر فعال (در حال سوار کردن یا حرکت)؛ null اگر نباشد.
  DriverTrip? get active {
    for (final t in _trips) {
      if (t.isActive) return t;
    }
    return null;
  }

  Future<void> load({bool silent = false}) async {
    if (!silent || _status == LoadStatus.idle) {
      _status = LoadStatus.loading;
      _error = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([_repo.trips(days: 2), _repo.me()]);
      _trips = (results[0] as List<DriverTrip>)
        ..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          return byDate != 0 ? byDate : a.plannedTime.compareTo(b.plannedTime);
        });
      _me = results[1] as DriverMe;
      _status = LoadStatus.ready;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      if (!silent || _trips.isEmpty) _status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// جایگزین کردن یک سفر پس از تغییر وضعیت.
  void replace(DriverTrip trip) {
    _trips = [for (final t in _trips) t.id == trip.id ? trip : t];
    notifyListeners();
  }
}
