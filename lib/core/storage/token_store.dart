import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// نگهداری توکن ورود.
abstract class TokenStore {
  Future<String?> read();
  Future<void> save(String token);
  Future<void> clear();
}

/// پیاده‌سازی امن (Keystore در اندروید، Keychain در iOS).
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'access_token';

  final FlutterSecureStorage _storage;
  String? _cache;

  @override
  Future<String?> read() async {
    if (_cache != null) return _cache;
    try {
      _cache = await _storage.read(key: _key);
    } catch (_) {
      _cache = null;
    }
    return _cache;
  }

  @override
  Future<void> save(String token) async {
    _cache = token;
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {
      // اگر ذخیره‌سازی ناموفق بود، توکن فقط تا پایان اجرا در حافظه می‌ماند.
    }
  }

  @override
  Future<void> clear() async {
    _cache = null;
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
