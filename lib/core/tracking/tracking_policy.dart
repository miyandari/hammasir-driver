import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// یک نقطه‌ی موقعیت آماده‌ی ارسال. سرعت بر حسب km/h (همان واحد بک‌اند).
class TrackPoint {
  const TrackPoint({
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.speedKmh,
    this.heading,
    this.accuracy,
  });

  final double lat;
  final double lng;
  final DateTime recordedAt;
  final double? speedKmh;
  final double? heading;
  final double? accuracy;

  LatLng get latLng => LatLng(lat, lng);

  Map<String, dynamic> toApi() => {
        'latitude': lat,
        'longitude': lng,
        if (speedKmh != null) 'speed': speedKmh,
        if (heading != null) 'heading': heading,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toStore() => {
        'lat': lat,
        'lng': lng,
        't': recordedAt.toUtc().millisecondsSinceEpoch,
        if (speedKmh != null) 's': speedKmh,
        if (heading != null) 'h': heading,
      };

  static TrackPoint? fromStore(Object? raw) {
    if (raw is! Map) return null;
    final lat = raw['lat'];
    final lng = raw['lng'];
    final t = raw['t'];
    if (lat is! num || lng is! num || t is! int) return null;
    return TrackPoint(
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      recordedAt: DateTime.fromMillisecondsSinceEpoch(t, isUtc: true),
      speedKmh: (raw['s'] as num?)?.toDouble(),
      heading: (raw['h'] as num?)?.toDouble(),
    );
  }
}

/// حالت مصرف انرژی بر اساس شارژ باتری.
enum PowerMode { normal, saver, critical }

/// پارامترهای نمونه‌برداری و ارسال در هر حالت.
///
/// دقت GPS در همه‌ی حالت‌ها «بالا» می‌ماند؛ صرفه‌جویی با کم کردن تعداد
/// نمونه‌ها، و بسته‌بندی ارسال‌ها (کم شدن بیدار شدن رادیو) انجام می‌شود.
class TrackingProfile {
  const TrackingProfile({
    required this.mode,
    required this.distanceFilterM,
    required this.minSendInterval,
    required this.heartbeat,
    required this.flushInterval,
    required this.sampleInterval,
  });

  final PowerMode mode;

  /// حداقل جابه‌جایی برای نمونه‌ی جدید GPS (متر).
  final int distanceFilterM;

  /// حداقل فاصله‌ی بین دو ارسال وقتی خودرو حرکت می‌کند.
  final Duration minSendInterval;

  /// حداکثر فاصله‌ی بین دو ارسال، حتی اگر خودرو ایستاده باشد.
  final Duration heartbeat;

  /// هر چند وقت صف روی شبکه ارسال شود (بسته‌ای).
  final Duration flushInterval;

  /// فاصله‌ی درخواست نمونه از GPS (Android).
  final Duration sampleInterval;

  static const normal = TrackingProfile(
    mode: PowerMode.normal,
    distanceFilterM: 15,
    minSendInterval: Duration(seconds: 5),
    heartbeat: Duration(seconds: 30),
    flushInterval: Duration(seconds: 5),
    sampleInterval: Duration(seconds: 4),
  );

  static const saver = TrackingProfile(
    mode: PowerMode.saver,
    distanceFilterM: 40,
    minSendInterval: Duration(seconds: 12),
    heartbeat: Duration(seconds: 60),
    flushInterval: Duration(seconds: 20),
    sampleInterval: Duration(seconds: 10),
  );

  static const critical = TrackingProfile(
    mode: PowerMode.critical,
    distanceFilterM: 80,
    minSendInterval: Duration(seconds: 25),
    heartbeat: Duration(seconds: 90),
    flushInterval: Duration(seconds: 45),
    sampleInterval: Duration(seconds: 20),
  );

  /// در حال شارژ همیشه حالت عادی؛ وگرنه بر اساس درصد باتری.
  static TrackingProfile forBattery(int? level, {bool charging = false}) {
    if (charging || level == null) return normal;
    if (level <= 10) return critical;
    if (level <= 30) return saver;
    return normal;
  }
}

/// قواعد خالص (بدون وابستگی به پلتفرم) برای فیلتر و تصمیم ارسال.
class TrackingRules {
  TrackingRules._();

  static const double maxAccuracyM = 50;
  static const double maxSpeedKmh = 150;
  static const Duration blackout = Duration(seconds: 120);
  static const double headingChangeDeg = 30;

  static const Distance _distance = Distance();

  static double meters(TrackPoint a, TrackPoint b) =>
      _distance(a.latLng, b.latLng);

  /// اختلاف زاویه‌ی دو سمت (۰ تا ۱۸۰).
  static double headingDelta(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  /// آیا نمونه‌ی GPS قابل اعتماد است؟
  /// - دقت بدتر از ۵۰ متر رد می‌شود، مگر مدتی طولانی نقطه‌ای نرسیده باشد
  ///   (تونل/ساختمان‌های بلند)؛ آن وقت تا ۱۵۰ متر پذیرفته می‌شود.
  /// - پرش غیرممکن (سرعت بیش از ۱۵۰ km/h نسبت به نقطه‌ی قبلی) رد می‌شود.
  static bool isAcceptable(TrackPoint fix, TrackPoint? last, DateTime now) {
    final accuracy = fix.accuracy;
    if (accuracy != null) {
      final starving =
          last == null || now.difference(last.recordedAt) > blackout;
      final limit = starving ? 150.0 : maxAccuracyM;
      if (accuracy > limit) return false;
    }

    if (last != null) {
      final seconds =
          fix.recordedAt.difference(last.recordedAt).inMilliseconds / 1000;
      if (seconds <= 0) return false;
      final kmh = meters(last, fix) / seconds * 3.6;
      if (kmh > maxSpeedKmh) return false;
    }
    return true;
  }

  /// آیا این نقطه الان باید به صف ارسال برود؟
  static bool shouldSend(
    TrackPoint fix,
    TrackPoint? lastSent,
    TrackingProfile profile,
  ) {
    if (lastSent == null) return true;

    final dt = fix.recordedAt.difference(lastSent.recordedAt);
    if (dt >= profile.heartbeat) return true;
    if (dt < profile.minSendInterval) return false;

    if (meters(lastSent, fix) >= profile.distanceFilterM) return true;

    final a = fix.heading;
    final b = lastSent.heading;
    final moving = (fix.speedKmh ?? 0) > 7;
    if (moving && a != null && b != null) {
      return headingDelta(a, b) >= headingChangeDeg;
    }
    return false;
  }

  /// m/s ← km/h برای GPS و بالعکس؛ مقدار منفی/نامعتبر به null.
  static double? speedKmhFromMs(double? ms) {
    if (ms == null || ms.isNaN || ms < 0) return null;
    return math.min(ms * 3.6, 300);
  }
}
