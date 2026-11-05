import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:hammasir_driver/core/network/api_exception.dart';
import 'package:hammasir_driver/core/tracking/location_queue.dart';
import 'package:hammasir_driver/core/tracking/tracking_policy.dart';
import 'package:hammasir_driver/core/utils/safe_notifier.dart';
import 'package:hammasir_driver/data/repositories/driver_repository.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

enum TrackingState { idle, starting, running, noPermission, gpsOff }

/// ردیابی موقعیت راننده در طول سفر.
///
/// - سرویس پیش‌زمینه‌ی اندروید (اعلان ثابت) تا ردیابی با بسته شدن صفحه قطع نشود
/// - نمونه‌برداری تطبیقی بر اساس شارژ باتری ([TrackingProfile])
/// - فیلتر نقاط نامعتبر ([TrackingRules])
/// - صف ماندگار + ارسال دسته‌ای؛ بدون اینترنت نقاط جمع و بعداً با زمان واقعی
///   ارسال می‌شوند
class TrackingController extends ChangeNotifier with SafeNotifier {
  TrackingController({
    required DriverRepository repository,
    LocationQueue? queue,
    Battery? battery,
  })  : _repo = repository,
        _queue = queue ?? LocationQueue(),
        _battery = battery ?? Battery();

  final DriverRepository _repo;
  final LocationQueue _queue;
  final Battery _battery;

  TrackingState _state = TrackingState.idle;
  TrackingProfile _profile = TrackingProfile.normal;
  int? _batteryLevel;
  bool _charging = false;
  int? _tripId;
  TrackPoint? _lastFix;
  TrackPoint? _lastQueued;
  DateTime? _lastUploadAt;
  String? _lastError;
  bool _flushing = false;
  bool _offline = false;

  StreamSubscription<Position>? _positions;
  StreamSubscription<BatteryState>? _batterySub;
  Timer? _flushTimer;
  Timer? _heartbeatTimer;
  Timer? _batteryTimer;

  /// وقتی سرور بگوید سفر دیگر فعال نیست صدا زده می‌شود.
  VoidCallback? onTripEnded;

  TrackingState get state => _state;
  TrackingProfile get profile => _profile;
  PowerMode get powerMode => _profile.mode;
  int? get batteryLevel => _batteryLevel;
  bool get charging => _charging;
  int? get tripId => _tripId;
  int get pending => _queue.length;
  DateTime? get lastUploadAt => _lastUploadAt;
  TrackPoint? get lastFix => _lastFix;
  bool get offline => _offline;
  bool get isRunning => _state == TrackingState.running;
  String? get lastError => _lastError;

  /// ردیابی سفر را شروع می‌کند (برای سفر در حال سوار کردن/حرکت).
  Future<void> start(int tripId) async {
    if (_tripId == tripId && (isRunning || _state == TrackingState.starting)) {
      return;
    }
    await _teardown();

    _tripId = tripId;
    _state = TrackingState.starting;
    _lastError = null;
    notifyListeners();

    await _queue.open(tripId);

    if (!await Geolocator.isLocationServiceEnabled()) {
      _state = TrackingState.gpsOff;
      notifyListeners();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _state = TrackingState.noPermission;
      notifyListeners();
      return;
    }

    await _readBattery();
    _batterySub = _battery.onBatteryStateChanged.listen((s) {
      _charging = s == BatteryState.charging || s == BatteryState.full;
      unawaited(_readBattery());
    });
    _batteryTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(_readBattery()),
    );

    _openStream();
    _restartTimers();
    _state = TrackingState.running;
    notifyListeners();

    // اولین نقطه بلافاصله، تا دانشجوها زودتر خودرو را ببینند.
    try {
      final first = await Geolocator.getCurrentPosition(
        locationSettings: _settings(),
      );
      _onPosition(first);
    } catch (_) {
      // جریان اصلی نقطه‌ها را می‌رساند.
    }
  }

  Future<void> stop({bool flush = true}) async {
    if (_tripId == null) return;
    if (flush) await _flush();
    await _queue.close(discard: true);
    await _teardown();
    _state = TrackingState.idle;
    _tripId = null;
    notifyListeners();
  }

  /// بعد از تغییر دسترسی/GPS در تنظیمات گوشی.
  Future<void> retry() async {
    final id = _tripId;
    if (id == null) return;
    _tripId = null;
    await start(id);
  }

  // --- باتری ---

  Future<void> _readBattery() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
    } catch (_) {
      _batteryLevel = null;
    }

    final next = TrackingProfile.forBattery(_batteryLevel, charging: _charging);
    if (next.mode != _profile.mode) {
      _profile = next;
      if (_state == TrackingState.running) {
        _openStream();
        _restartTimers();
      }
    }
    notifyListeners();
  }

  // --- GPS ---

  LocationSettings _settings() {
    final distance = _profile.distanceFilterM;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distance,
        intervalDuration: _profile.sampleInterval,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: L10n.t('track.notif_title'),
          notificationText: L10n.t('track.notif_text'),
          notificationChannelName: L10n.t('track.notif_channel'),
          setOngoing: true,
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distance,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distance,
    );
  }

  void _openStream() {
    _positions?.cancel();
    _positions = Geolocator.getPositionStream(locationSettings: _settings())
        .listen(
      _onPosition,
      onError: (Object _) {
        _state = TrackingState.gpsOff;
        notifyListeners();
      },
    );
  }

  void _onPosition(Position position) {
    if (_state == TrackingState.gpsOff) _state = TrackingState.running;

    final now = DateTime.now().toUtc();
    var at = position.timestamp.toUtc();
    if (at.isAfter(now)) at = now;

    final fix = TrackPoint(
      lat: position.latitude,
      lng: position.longitude,
      recordedAt: at,
      speedKmh: TrackingRules.speedKmhFromMs(position.speed),
      heading: position.heading >= 0 ? position.heading : null,
      accuracy: position.accuracy,
    );

    if (!TrackingRules.isAcceptable(fix, _lastFix, now)) return;
    _lastFix = fix;

    if (TrackingRules.shouldSend(fix, _lastQueued, _profile)) {
      _enqueue(fix);
    }
    notifyListeners();
  }

  void _enqueue(TrackPoint point) {
    _lastQueued = point;
    _queue.add(point);
    unawaited(_queue.save());
  }

  // --- ارسال ---

  void _restartTimers() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(
      _profile.flushInterval,
      (_) => unawaited(_flush()),
    );

    // ضربان: وقتی خودرو ایستاده، آخرین نقطه با زمان تازه ثبت می‌شود.
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_profile.heartbeat, (_) {
      final last = _lastFix;
      final queued = _lastQueued;
      if (last == null) return;
      final now = DateTime.now().toUtc();
      if (queued != null &&
          now.difference(queued.recordedAt) < _profile.heartbeat) {
        return;
      }
      // نقطه‌ی بیش از دو دقیقه قدیمی را به‌جای حال جا نمی‌زنیم.
      if (now.difference(last.recordedAt) > const Duration(minutes: 2)) return;
      _enqueue(
        TrackPoint(
          lat: last.lat,
          lng: last.lng,
          recordedAt: now,
          speedKmh: 0,
          heading: last.heading,
        ),
      );
    });
  }

  Future<void> _flush() async {
    final id = _tripId;
    if (id == null || _flushing || _queue.isEmpty) return;
    _flushing = true;

    try {
      while (!_queue.isEmpty) {
        final batch = _queue.peek(100);
        final result = await _repo.uploadLocations(id, batch);
        _queue.removeFirst(batch.length);
        _offline = false;
        _lastError = null;
        _lastUploadAt = DateTime.now();

        if (!result.tripActive) {
          await _queue.close(discard: true);
          await _teardown();
          _state = TrackingState.idle;
          _tripId = null;
          notifyListeners();
          onTripEnded?.call();
          return;
        }
      }
      await _queue.save();
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _offline = true; // نقاط در صف می‌مانند.
      } else {
        // خطای دائمی (مثل 400/403): دسته را دور می‌ریزیم تا صف گیر نکند.
        _lastError = e.message;
        _queue.removeFirst(100);
        await _queue.save();
      }
    } finally {
      _flushing = false;
      notifyListeners();
    }
  }

  Future<void> _teardown() async {
    await _positions?.cancel();
    await _batterySub?.cancel();
    _positions = null;
    _batterySub = null;
    _flushTimer?.cancel();
    _heartbeatTimer?.cancel();
    _batteryTimer?.cancel();
    _flushTimer = _heartbeatTimer = _batteryTimer = null;
    _lastFix = null;
    _lastQueued = null;
  }

  @override
  void dispose() {
    unawaited(_teardown());
    super.dispose();
  }
}
