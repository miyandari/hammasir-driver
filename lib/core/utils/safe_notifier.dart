import 'package:flutter/foundation.dart';

/// جلوگیری از notifyListeners بعد از dispose (خطای رایج با کارهای async).
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
