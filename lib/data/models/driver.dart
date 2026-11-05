import 'package:latlong2/latlong.dart';

import 'package:hammasir_driver/core/utils/json_utils.dart';

/// وضعیت‌های سفر (همان مقادیر بک‌اند).
class TripStatus {
  TripStatus._();

  static const scheduled = 'scheduled';
  static const boarding = 'boarding';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
  static const cancelled = 'cancelled';
}

/// نوع خرابی؛ مقدار همان چیزی است که بک‌اند می‌پذیرد.
const List<String> breakdownKinds = [
  'engine',
  'tire',
  'electrical',
  'fuel',
  'accident',
  'other',
];

class DriverVehicle {
  const DriverVehicle({
    required this.id,
    required this.plate,
    required this.type,
    required this.capacity,
  });

  final int id;
  final String plate;
  final String type;
  final int capacity;

  factory DriverVehicle.fromJson(Map<String, dynamic> json) => DriverVehicle(
        id: asInt(json['id']) ?? 0,
        plate: asString(json['plate_number']),
        type: asString(json['vehicle_type']),
        capacity: asInt(json['capacity']) ?? 0,
      );
}

/// پاسخ `GET /driver/me`.
class DriverMe {
  const DriverMe({
    required this.driverId,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.vehicle,
  });

  final int driverId;
  final String firstName;
  final String lastName;
  final String? phone;
  final DriverVehicle? vehicle;

  String get fullName => '$firstName $lastName'.trim();

  factory DriverMe.fromJson(Map<String, dynamic> json) {
    final vehicle = asMap(json['vehicle']);
    return DriverMe(
      driverId: asInt(json['driver_id']) ?? 0,
      firstName: asString(json['first_name']),
      lastName: asString(json['last_name']),
      phone: asNullableString(json['phone']),
      vehicle: vehicle == null ? null : DriverVehicle.fromJson(vehicle),
    );
  }
}

class TripStopInfo {
  const TripStopInfo({
    required this.stationId,
    required this.name,
    required this.point,
    required this.order,
    required this.minutesFromStart,
  });

  final int stationId;
  final String name;
  final LatLng point;
  final int order;
  final int minutesFromStart;

  factory TripStopInfo.fromJson(Map<String, dynamic> json) => TripStopInfo(
        stationId: asInt(json['station_id']) ?? 0,
        name: asString(json['name']),
        point: LatLng(
          asDouble(json['latitude']) ?? 0,
          asDouble(json['longitude']) ?? 0,
        ),
        order: asInt(json['stop_order']) ?? 0,
        minutesFromStart: asInt(json['minutes_from_start']) ?? 0,
      );
}

class DriverTrip {
  const DriverTrip({
    required this.id,
    required this.serviceName,
    required this.date,
    required this.plannedTime,
    required this.status,
    required this.reserved,
    required this.seats,
    required this.standing,
    required this.stops,
    this.plate,
  });

  final int id;
  final String serviceName;
  final String date;

  /// مثل «07:30»
  final String plannedTime;
  final String status;
  final int reserved;
  final int seats;
  final int standing;
  final String? plate;
  final List<TripStopInfo> stops;

  bool get isActive =>
      status == TripStatus.boarding || status == TripStatus.inProgress;
  bool get isFinished =>
      status == TripStatus.completed || status == TripStatus.cancelled;

  /// وضعیت بعدی مجاز برای راننده؛ null یعنی دکمه‌ای نیست.
  String? get nextStatus {
    switch (status) {
      case TripStatus.scheduled:
        return TripStatus.boarding;
      case TripStatus.boarding:
        return TripStatus.inProgress;
      case TripStatus.inProgress:
        return TripStatus.completed;
      default:
        return null;
    }
  }

  factory DriverTrip.fromJson(Map<String, dynamic> json) {
    final time = asString(json['planned_departure_time']);
    return DriverTrip(
      id: asInt(json['id']) ?? 0,
      serviceName: asString(json['service_name']),
      date: asString(json['trip_date']),
      plannedTime: time.length >= 5 ? time.substring(0, 5) : time,
      status: asString(json['status'], TripStatus.scheduled),
      reserved: asInt(json['reserved_count']) ?? 0,
      seats: asInt(json['seated_capacity']) ?? 0,
      standing: asInt(json['standing_capacity']) ?? 0,
      plate: asNullableString(json['vehicle_plate']),
      stops: [
        for (final s in asMapList(json['stops'])) TripStopInfo.fromJson(s),
      ]..sort((a, b) => a.order.compareTo(b.order)),
    );
  }
}

class ManifestPassenger {
  const ManifestPassenger({
    required this.reservationId,
    required this.studentId,
    required this.name,
    required this.studentNumber,
    required this.stationId,
    required this.stationName,
    required this.standing,
    required this.boarded,
  });

  final int reservationId;
  final int studentId;
  final String name;
  final String studentNumber;
  final int? stationId;
  final String stationName;
  final bool standing;
  final bool boarded;

  factory ManifestPassenger.fromJson(Map<String, dynamic> json) =>
      ManifestPassenger(
        reservationId: asInt(json['reservation_id']) ?? 0,
        studentId: asInt(json['student_id']) ?? 0,
        name: asString(json['name']),
        studentNumber: asString(json['student_number']),
        stationId: asInt(json['station_id']),
        stationName: asString(json['station_name']),
        standing: asBool(json['is_standing']),
        boarded: asBool(json['boarded']),
      );
}

class PendingRequest {
  const PendingRequest({
    required this.id,
    required this.name,
    required this.stationName,
    required this.standing,
  });

  final int id;
  final String name;
  final String stationName;
  final bool standing;

  factory PendingRequest.fromJson(Map<String, dynamic> json) => PendingRequest(
        id: asInt(json['request_id']) ?? 0,
        name: asString(json['name']),
        stationName: asString(json['station_name']),
        standing: asBool(json['is_standing']),
      );
}

class Manifest {
  const Manifest({required this.passengers, required this.pending});

  final List<ManifestPassenger> passengers;
  final List<PendingRequest> pending;

  int get boardedCount => passengers.where((p) => p.boarded).length;

  factory Manifest.fromJson(Map<String, dynamic> json) => Manifest(
        passengers: [
          for (final p in asMapList(json['passengers']))
            ManifestPassenger.fromJson(p),
        ],
        pending: [
          for (final p in asMapList(json['pending_requests']))
            PendingRequest.fromJson(p),
        ],
      );
}
