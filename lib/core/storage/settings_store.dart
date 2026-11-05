import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تنظیمات سبک کاربر روی دستگاه.
class SettingsStore {
  static const String _themeKey = 'theme_mode';
  static const String _langKey = 'language';
  static const String _biometricKey = 'biometric_enabled';
  static const String _avatarPrefix = 'avatar_path_';

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// پیش‌فرض روشن است (مطابق طرح)؛ «سیستم» فقط وقتی کاربر انتخاب کند.
  Future<ThemeMode> readThemeMode() async {
    final prefs = await _prefs();
    switch (prefs?.getString(_themeKey)) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
    }
    return ThemeMode.light;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await _prefs();
    await prefs?.setString(_themeKey, mode.name);
  }

  /// null یعنی کاربر هنوز زبان انتخاب نکرده است.
  Future<String?> readLanguage() async {
    final prefs = await _prefs();
    final value = prefs?.getString(_langKey);
    return (value == 'fa' || value == 'en') ? value : null;
  }

  Future<void> saveLanguage(String code) async {
    final prefs = await _prefs();
    await prefs?.setString(_langKey, code);
  }

  Future<bool> readBiometricEnabled() async {
    final prefs = await _prefs();
    return prefs?.getBool(_biometricKey) ?? false;
  }

  Future<void> saveBiometricEnabled(bool value) async {
    final prefs = await _prefs();
    await prefs?.setBool(_biometricKey, value);
  }

  Future<String?> readAvatarPath(int userId) async {
    final prefs = await _prefs();
    return prefs?.getString('$_avatarPrefix$userId');
  }

  Future<void> saveAvatarPath(int userId, String? path) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    if (path == null) {
      await prefs.remove('$_avatarPrefix$userId');
    } else {
      await prefs.setString('$_avatarPrefix$userId', path);
    }
  }

  /// فعالیت‌های کاربر (JSON)، جدا برای هر کاربر.
  Future<String?> readActivity(int userId) async {
    final prefs = await _prefs();
    return prefs?.getString('activity_$userId');
  }

  Future<void> saveActivity(int userId, String json) async {
    final prefs = await _prefs();
    await prefs?.setString('activity_$userId', json);
  }

  /// آیا اعلان این دسته به‌صورت نوتیفیکیشن دستگاه هم نمایش داده شود؟
  Future<bool> readDeviceNotify(int userId, String category) async {
    final prefs = await _prefs();
    return prefs?.getBool('notify_${userId}_$category') ?? true;
  }

  Future<void> saveDeviceNotify(int userId, String category, bool value) async {
    final prefs = await _prefs();
    await prefs?.setBool('notify_${userId}_$category', value);
  }
}
