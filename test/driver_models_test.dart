import 'package:flutter_test/flutter_test.dart';

import 'package:hammasir_driver/data/models/driver.dart';

void main() {
  test('ساعت سفر: تاریخ‌ساعت UTC به وقت تهران تبدیل می‌شود', () {
    String hm(String v) =>
        DriverTrip.fromJson({'id': 1, 'planned_departure_time': v}).plannedTime;
    expect(hm('2026-11-05T03:15:00'), '06:45');
    expect(hm('2026-11-05 03:15:00'), '06:45');
    expect(hm('2026-11-05T03:15:00Z'), '06:45');
    expect(hm('2026-11-05T20:45:00'), '00:15');
    expect(hm('07:30:00'), '07:30');
  });

  test('نتیجه‌ی اسکن و مسافر بدون رزرو', () {
    final r = ScanResult.fromJson({
      'result': 'needs_confirm',
      'name': 'الف ب',
      'student_number': '1',
      'has_reservation': false,
    });
    expect(r.result, 'needs_confirm');
    expect(r.hasReservation, isFalse);
    final m = Manifest.fromJson({
      'passengers': [
        {'student_id': 3, 'name': 'ج', 'walk_in': true, 'boarded': true},
      ],
    });
    expect(m.passengers.single.walkIn, isTrue);
    expect(m.passengers.single.reservationId, isNull);
  });

  test('DriverTrip: پارس و ترتیب ایستگاه‌ها و وضعیت بعدی', () {
    final trip = DriverTrip.fromJson({
      'id': 5,
      'service_name': 'سرویس از پردیس به خوابگاه',
      'trip_date': '2026-11-04',
      'planned_departure_time': '07:30:00',
      'status': 'scheduled',
      'reserved_count': 4,
      'seated_capacity': 30,
      'standing_capacity': 10,
      'vehicle_plate': '12ب345',
      'stops': [
        {
          'station_id': 2,
          'name': 'ب',
          'latitude': 36.7,
          'longitude': 48.5,
          'stop_order': 2,
          'minutes_from_start': 10,
        },
        {
          'station_id': 1,
          'name': 'الف',
          'latitude': 36.6,
          'longitude': 48.4,
          'stop_order': 1,
          'minutes_from_start': 0,
        },
      ],
    });

    expect(trip.plannedTime, '07:30');
    expect(trip.stops.first.name, 'الف');
    expect(trip.nextStatus, TripStatus.boarding);
    expect(trip.isActive, isFalse);
  });

  test('چرخه‌ی وضعیت سفر', () {
    DriverTrip with_(String s) => DriverTrip.fromJson({'id': 1, 'status': s});
    expect(with_('boarding').nextStatus, TripStatus.inProgress);
    expect(with_('in_progress').nextStatus, TripStatus.completed);
    expect(with_('completed').nextStatus, isNull);
    expect(with_('cancelled').nextStatus, isNull);
    expect(with_('in_progress').isActive, isTrue);
  });

  test('Manifest: شمارش سوار شده‌ها', () {
    final m = Manifest.fromJson({
      'passengers': [
        {'reservation_id': 1, 'student_id': 9, 'name': 'الف', 'boarded': true},
        {'reservation_id': 2, 'student_id': 10, 'name': 'ب', 'boarded': false},
      ],
      'pending_requests': [
        {'request_id': 3, 'name': 'ج', 'station_name': 'ایستگاه'},
      ],
    });
    expect(m.boardedCount, 1);
    expect(m.pending.single.id, 3);
  });
}
