import 'package:flutter_test/flutter_test.dart';

import 'package:hammasir_driver/core/tracking/tracking_policy.dart';

TrackPoint pt(double lat, double lng, DateTime t,
    {double? acc, double? heading, double? speed}) {
  return TrackPoint(
    lat: lat,
    lng: lng,
    recordedAt: t,
    accuracy: acc,
    heading: heading,
    speedKmh: speed,
  );
}

void main() {
  final t0 = DateTime.utc(2026, 11, 4, 8);

  group('TrackingProfile.forBattery', () {
    test('شارژ بالا یا در حال شارژ: عادی', () {
      expect(TrackingProfile.forBattery(80).mode, PowerMode.normal);
      expect(TrackingProfile.forBattery(5, charging: true).mode,
          PowerMode.normal);
      expect(TrackingProfile.forBattery(null).mode, PowerMode.normal);
    });

    test('۳۰٪ و ۱۰٪ مرز حالت‌ها هستند', () {
      expect(TrackingProfile.forBattery(31).mode, PowerMode.normal);
      expect(TrackingProfile.forBattery(30).mode, PowerMode.saver);
      expect(TrackingProfile.forBattery(11).mode, PowerMode.saver);
      expect(TrackingProfile.forBattery(10).mode, PowerMode.critical);
    });

    test('در حالت کم‌مصرف فاصله‌ها بیشتر می‌شود', () {
      expect(TrackingProfile.saver.minSendInterval,
          greaterThan(TrackingProfile.normal.minSendInterval));
      expect(TrackingProfile.critical.flushInterval,
          greaterThan(TrackingProfile.saver.flushInterval));
    });
  });

  group('TrackingRules.isAcceptable', () {
    test('دقت بد رد می‌شود', () {
      final last = pt(36.67, 48.49, t0);
      final fix = pt(36.6701, 48.49, t0.add(const Duration(seconds: 5)),
          acc: 80);
      expect(
        TrackingRules.isAcceptable(
            fix, last, t0.add(const Duration(seconds: 5))),
        isFalse,
      );
    });

    test('بعد از قطعی طولانی دقت متوسط پذیرفته می‌شود', () {
      final last = pt(36.67, 48.49, t0);
      final at = t0.add(const Duration(minutes: 5));
      final fix = pt(36.671, 48.49, at, acc: 90);
      expect(TrackingRules.isAcceptable(fix, last, at), isTrue);
    });

    test('پرش غیرممکن رد می‌شود', () {
      final last = pt(36.67, 48.49, t0);
      final at = t0.add(const Duration(seconds: 5));
      final fix = pt(36.9, 48.49, at, acc: 10); // ~25 km در ۵ ثانیه
      expect(TrackingRules.isAcceptable(fix, last, at), isFalse);
    });

    test('نقطه‌ی عادی پذیرفته می‌شود', () {
      final last = pt(36.67, 48.49, t0);
      final at = t0.add(const Duration(seconds: 10));
      final fix = pt(36.6705, 48.49, at, acc: 8);
      expect(TrackingRules.isAcceptable(fix, last, at), isTrue);
    });

    test('زمان غیرصعودی رد می‌شود', () {
      final last = pt(36.67, 48.49, t0);
      final fix = pt(36.6701, 48.49, t0, acc: 8);
      expect(TrackingRules.isAcceptable(fix, last, t0), isFalse);
    });
  });

  group('TrackingRules.shouldSend', () {
    test('اولین نقطه همیشه ارسال می‌شود', () {
      expect(
        TrackingRules.shouldSend(pt(36.67, 48.49, t0), null,
            TrackingProfile.normal),
        isTrue,
      );
    });

    test('ایستاده: تا ضربان ارسال نمی‌شود، بعد از آن می‌شود', () {
      final last = pt(36.67, 48.49, t0);
      final soon = pt(36.67, 48.49, t0.add(const Duration(seconds: 10)));
      final late = pt(36.67, 48.49, t0.add(const Duration(seconds: 31)));
      expect(TrackingRules.shouldSend(soon, last, TrackingProfile.normal),
          isFalse);
      expect(TrackingRules.shouldSend(late, last, TrackingProfile.normal),
          isTrue);
    });

    test('جابه‌جایی کافی بعد از حداقل فاصله‌ی زمانی', () {
      final last = pt(36.67, 48.49, t0);
      // ~22 متر شمال
      final moved = pt(36.6702, 48.49, t0.add(const Duration(seconds: 6)));
      expect(TrackingRules.shouldSend(moved, last, TrackingProfile.normal),
          isTrue);
      // در حالت بحرانی ۸۰ متر لازم است
      final movedLate =
          pt(36.6702, 48.49, t0.add(const Duration(seconds: 30)));
      expect(
          TrackingRules.shouldSend(movedLate, last, TrackingProfile.critical),
          isFalse);
    });

    test('پیچ تند در حال حرکت ارسال می‌شود', () {
      final last = pt(36.67, 48.49, t0, heading: 10);
      final turn = pt(36.67001, 48.49, t0.add(const Duration(seconds: 6)),
          heading: 90, speed: 30);
      expect(TrackingRules.shouldSend(turn, last, TrackingProfile.normal),
          isTrue);
    });
  });

  test('headingDelta کوتاه‌ترین زاویه را می‌دهد', () {
    expect(TrackingRules.headingDelta(350, 10), 20);
    expect(TrackingRules.headingDelta(10, 350), 20);
    expect(TrackingRules.headingDelta(0, 180), 180);
  });

  test('speedKmhFromMs', () {
    expect(TrackingRules.speedKmhFromMs(10), closeTo(36, 0.001));
    expect(TrackingRules.speedKmhFromMs(-1), isNull);
    expect(TrackingRules.speedKmhFromMs(null), isNull);
  });

  test('TrackPoint: ذخیره و بازیابی و قالب API', () {
    final p = pt(36.67, 48.49, t0, heading: 45, speed: 20);
    final back = TrackPoint.fromStore(p.toStore())!;
    expect(back.lat, 36.67);
    expect(back.recordedAt, t0);
    expect(back.heading, 45);

    final api = p.toApi();
    expect(api['recorded_at'], endsWith('Z'));
    expect(api['speed'], 20);
    expect(TrackPoint.fromStore('x'), isNull);
  });
}
