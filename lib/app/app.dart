import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:hammasir_driver/app/deps.dart';
import 'package:hammasir_driver/app/settings_scope.dart';
import 'package:hammasir_driver/app/shell.dart';
import 'package:hammasir_driver/app/stores.dart';
import 'package:hammasir_driver/core/theme/app_theme.dart';
import 'package:hammasir_driver/features/auth/language_screen.dart';
import 'package:hammasir_driver/features/auth/lock_screen.dart';
import 'package:hammasir_driver/features/auth/login_screen.dart';
import 'package:hammasir_driver/features/auth/splash_screen.dart';
import 'package:hammasir_driver/l10n/l10n.dart';
import 'package:hammasir_driver/state/locale_controller.dart';
import 'package:hammasir_driver/state/session_controller.dart';
import 'package:hammasir_driver/state/theme_controller.dart';

/// ریشه‌ی برنامه: وابستگی‌ها، نشست، تم، زبان و ذخیره‌گاه‌های مشترک.
class HammasirApp extends StatefulWidget {
  const HammasirApp({super.key, this.deps});

  /// برای تست می‌توان Deps ساختگی داد.
  final Deps? deps;

  @override
  State<HammasirApp> createState() => _HammasirAppState();
}

class _HammasirAppState extends State<HammasirApp> {
  late final Deps _deps = widget.deps ?? Deps();
  late final SessionController _session = SessionController(
    auth: _deps.auth,
    settings: _deps.settings,
    biometric: _deps.biometric,
  );
  late final ThemeController _theme = ThemeController(_deps.settings);
  late final LocaleController _locale = LocaleController(_deps.settings);

  Stores? _stores;

  @override
  void initState() {
    super.initState();
    _deps.api.onUnauthorized = _session.expire;
    _session.addListener(_syncStores);
    _boot();
  }

  /// اول زبان و تم خوانده می‌شود تا صفحه‌ی اول با زبان درست ساخته شود.
  Future<void> _boot() async {
    await Future.wait([_theme.load(), _locale.load()]);
    await _session.restore();
  }

  /// با هر ورود، ذخیره‌گاه‌های تازه؛ با هر خروج، دور ریختن آن‌ها.
  void _syncStores() {
    final loggedIn = _session.status == SessionStatus.loggedIn;

    if (loggedIn && _stores == null) {
      final stores = Stores(_deps, session: _session);
      setState(() => _stores = stores);
    } else if (!loggedIn && _stores != null) {
      final old = _stores!;
      setState(() => _stores = null);
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  @override
  void dispose() {
    _session.removeListener(_syncStores);
    _session.dispose();
    _theme.dispose();
    _locale.dispose();
    _stores?.dispose();
    if (widget.deps == null) _deps.dispose();
    super.dispose();
  }

  Widget _home() {
    if (!_locale.loaded) return SplashScreen(session: _session);

    switch (_session.status) {
      case SessionStatus.starting:
        return SplashScreen(session: _session);
      case SessionStatus.locked:
        return LockScreen(session: _session);
      case SessionStatus.loggedOut:
        return _locale.chosen
            ? LoginScreen(session: _session)
            : const LanguageScreen();
      case SessionStatus.loggedIn:
        // ذخیره‌گاه‌ها در همین فریم ساخته می‌شوند؛ این گارد فقط محافظ است.
        if (_stores == null) return SplashScreen(session: _session);
        return Shell(session: _session);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DepsScope(
      deps: _deps,
      child: ListenableBuilder(
        listenable: Listenable.merge([_session, _theme, _locale]),
        builder: (context, _) {
          final app = MaterialApp(
            onGenerateTitle: (context) => context.t('app.name'),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _theme.mode,
            locale: _locale.locale,
            supportedLocales: L10n.supported,
            localizationsDelegates: const [
              appLocalizationsDelegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _home(),
          );

          final scoped = SettingsScope(
            theme: _theme,
            locale: _locale,
            child: app,
          );
          final stores = _stores;
          if (stores == null) return scoped;
          return StoresScope(stores: stores, child: scoped);
        },
      ),
    );
  }
}
