import 'package:flutter/widgets.dart';

import 'package:hammasir_driver/core/network/api_client.dart';
import 'package:hammasir_driver/core/security/biometric_service.dart';
import 'package:hammasir_driver/core/storage/settings_store.dart';
import 'package:hammasir_driver/core/storage/token_store.dart';
import 'package:hammasir_driver/data/repositories/auth_repository.dart';
import 'package:hammasir_driver/data/repositories/driver_repository.dart';
import 'package:hammasir_driver/data/repositories/notification_repository.dart';
import 'package:hammasir_driver/data/repositories/routing_repository.dart';

/// همه‌ی وابستگی‌های شبکه/داده؛ یک بار ساخته می‌شود و با InheritedWidget در دسترس است.
class Deps {
  Deps({
    TokenStore? tokens,
    ApiClient? api,
    SettingsStore? settings,
    BiometricService? biometric,
  })  : tokens = tokens ?? SecureTokenStore(),
        settings = settings ?? SettingsStore(),
        biometric = biometric ?? BiometricService() {
    this.api = api ?? ApiClient(tokens: this.tokens);
    auth = AuthRepository(api: this.api, tokens: this.tokens);
    driver = DriverRepository(this.api);
    notifications = NotificationRepository(this.api);
    routing = RoutingRepository();
  }

  final TokenStore tokens;
  final SettingsStore settings;
  final BiometricService biometric;
  late final ApiClient api;
  late final AuthRepository auth;
  late final DriverRepository driver;
  late final NotificationRepository notifications;
  late final RoutingRepository routing;

  void dispose() {
    api.close();
    routing.close();
  }
}

class DepsScope extends InheritedWidget {
  const DepsScope({super.key, required this.deps, required super.child});

  final Deps deps;

  /// برای initState (بدون ثبت وابستگی).
  static Deps read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<DepsScope>();
    assert(scope != null, 'DepsScope در درخت ویجت پیدا نشد');
    return scope!.deps;
  }

  static Deps of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DepsScope>();
    assert(scope != null, 'DepsScope در درخت ویجت پیدا نشد');
    return scope!.deps;
  }

  @override
  bool updateShouldNotify(DepsScope oldWidget) => deps != oldWidget.deps;
}
