import 'package:flutter/foundation.dart';

import 'package:hammasir_driver/core/network/api_exception.dart';
import 'package:hammasir_driver/core/security/biometric_service.dart';
import 'package:hammasir_driver/core/storage/settings_store.dart';
import 'package:hammasir_driver/core/utils/safe_notifier.dart';
import 'package:hammasir_driver/data/models/user_profile.dart';
import 'package:hammasir_driver/data/repositories/auth_repository.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// locked: توکن ذخیره است ولی تا تأیید اثر انگشت وارد نشده‌ایم.
enum SessionStatus { starting, locked, loggedOut, loggedIn }

/// وضعیت ورود کاربر؛ تنها منبع حقیقت برای «وارد شده‌ام یا نه».
class SessionController extends ChangeNotifier with SafeNotifier {
  SessionController({
    required AuthRepository auth,
    SettingsStore? settings,
    BiometricService? biometric,
  })  : _auth = auth,
        _settings = settings,
        _biometric = biometric;

  final AuthRepository _auth;
  final SettingsStore? _settings;
  final BiometricService? _biometric;

  SessionStatus _status = SessionStatus.starting;
  UserProfile? _profile;
  String? _startupError;
  String? _notice;
  bool _busy = false;

  SessionStatus get status => _status;
  UserProfile? get profile => _profile;

  /// خطای شبکه هنگام باز شدن اپ (با دکمه‌ی تلاش دوباره).
  String? get startupError => _startupError;

  /// پیام یک‌بار مصرف برای صفحه‌ی ورود (مثل «نشست منقضی شد»).
  String? get notice => _notice;
  bool get busy => _busy;

  int? get driverId => _profile?.driverId;

  /// هنگام باز شدن اپ: اگر توکن ذخیره دارد، حساب را بررسی می‌کند.
  Future<void> restore() async {
    _startupError = null;
    _status = SessionStatus.starting;
    notifyListeners();

    if (!await _auth.hasToken()) {
      _status = SessionStatus.loggedOut;
      notifyListeners();
      return;
    }

    if (await _biometricRequired()) {
      _status = SessionStatus.locked;
      notifyListeners();
      return;
    }

    await _resume();
  }

  Future<bool> _biometricRequired() async {
    final settings = _settings;
    if (settings == null) return false;
    return settings.readBiometricEnabled();
  }

  /// صفحه‌ی قفل: با اثر انگشت درست، ورود ادامه پیدا می‌کند.
  Future<bool> unlock() async {
    final biometric = _biometric;
    final ok = biometric != null &&
        await biometric.authenticate(L10n.t('biometric.reason_unlock'));
    if (!ok) return false;

    await _resume();
    return true;
  }

  /// تلاش دوباره بعد از خطای شبکه هنگام باز شدن اپ.
  Future<void> retry() => _resume();

  /// انصراف از اثر انگشت: خروج و ورود با رمز.
  Future<void> usePassword() => logout();

  Future<void> _resume() async {
    _startupError = null;
    _status = SessionStatus.starting;
    notifyListeners();

    try {
      await _enter(await _auth.fetchProfile());
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _startupError = e.message;
      } else {
        await _auth.logout();
        _status = SessionStatus.loggedOut;
      }
      notifyListeners();
    }
  }

  /// true یعنی ورود موفق بود. در خطا [error] پیام را برمی‌گرداند.
  Future<String?> login(String username, String password) async {
    if (_busy) return null;
    _busy = true;
    _notice = null;
    notifyListeners();

    try {
      await _auth.login(username, password);
      await _enter(await _auth.fetchProfile());
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _enter(UserProfile profile) async {
    if (!profile.isDriver || profile.driverId == null) {
      await _auth.logout();
      _status = SessionStatus.loggedOut;
      throw ApiException(L10n.t('err.not_driver'));
    }

    _profile = profile;
    _status = SessionStatus.loggedIn;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.logout();
    _reset();
    notifyListeners();
  }

  /// وقتی سرور توکن را رد کرد (401).
  void expire() {
    if (_status != SessionStatus.loggedIn) return;
    _auth.logout();
    _reset();
    _notice = L10n.t('err.session_expired_login');
    notifyListeners();
  }

  void _reset() {
    _profile = null;
    _status = SessionStatus.loggedOut;
    _settings?.saveBiometricEnabled(false);
  }
}
