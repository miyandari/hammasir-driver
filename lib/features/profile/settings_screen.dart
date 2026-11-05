import 'package:flutter/material.dart';

import 'package:hammasir_driver/app/deps.dart';
import 'package:hammasir_driver/app/settings_scope.dart';
import 'package:hammasir_driver/app/stores.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/widgets/app_card.dart';
import 'package:hammasir_driver/core/widgets/choice_tile.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/features/profile/change_password_screen.dart';
import 'package:hammasir_driver/features/shared/page_header.dart';
import 'package:hammasir_driver/features/shared/ui_helpers.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

/// تنظیمات: زبان، تم، ورود با اثر انگشت، رمز عبور و نسخه.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _categories = ['trip', 'system'];

  bool _biometric = false;
  bool _loaded = false;
  final Map<String, bool> _notify = {};

  @override
  void initState() {
    super.initState();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final settings = DepsScope.read(context).settings;
    final userId = StoresScope.read(context).session.profile?.id;
    final enabled = await settings.readBiometricEnabled();
    final notify = <String, bool>{};
    if (userId != null) {
      for (final c in _categories) {
        notify[c] = await settings.readDeviceNotify(userId, c);
      }
    }
    if (!mounted) return;
    setState(() {
      _biometric = enabled;
      _notify.addAll(notify);
      _loaded = true;
    });
  }

  Future<void> _toggleNotify(String category, bool value) async {
    final userId = StoresScope.read(context).session.profile?.id;
    if (userId == null) return;
    setState(() => _notify[category] = value);
    await DepsScope.read(context).settings.saveDeviceNotify(
          userId,
          category,
          value,
        );
  }

  Future<void> _toggleBiometric(bool value) async {
    final deps = DepsScope.read(context);

    if (!value) {
      await deps.settings.saveBiometricEnabled(false);
      if (!mounted) return;
      setState(() => _biometric = false);
      return;
    }

    if (!await deps.biometric.isAvailable()) {
      if (!mounted) return;
      await confirm(
        context,
        title: context.t('settings.bio_unavailable_title'),
        message: context.t('settings.bio_unavailable_msg'),
        confirmLabel: context.t('common.ok'),
        cancelLabel: context.t('common.cancel'),
        icon: Icons.fingerprint,
      );
      return;
    }

    final ok = await deps.biometric.authenticate(
      L10n.t('biometric.reason_enable'),
    );
    if (!ok) return;

    await deps.settings.saveBiometricEnabled(true);
    if (!mounted) return;
    setState(() => _biometric = true);
    showMessage(context, context.t('settings.bio_enabled'), tone: Tone.success);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final settings = SettingsScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('settings.title'))),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings.theme, settings.locale]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              SectionTitle(context.t('settings.language')),
              for (final option in const [('fa', 'فارسی'), ('en', 'English')])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ChoiceTile(
                    title: option.$2,
                    selected: settings.locale.code == option.$1,
                    onTap: () => settings.locale.setLanguage(option.$1),
                  ),
                ),
              SectionTitle(context.t('settings.theme')),
              for (final option in [
                (ThemeMode.system, context.t('settings.theme_system')),
                (ThemeMode.light, context.t('settings.theme_light')),
                (ThemeMode.dark, context.t('settings.theme_dark')),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ChoiceTile(
                    title: option.$2,
                    selected: settings.theme.mode == option.$1,
                    onTap: () => settings.theme.setMode(option.$1),
                  ),
                ),
              SectionTitle(context.t('settings.notifications')),
              AppCard(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final c in _categories)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.t('notify.$c'),
                              style: TextStyle(color: p.text),
                            ),
                          ),
                          Switch(
                            value: _notify[c] ?? true,
                            onChanged: _loaded
                                ? (v) => _toggleNotify(c, v)
                                : null,
                          ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 6),
                      child: Text(
                        context.t('settings.notify_hint'),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.7,
                          color: p.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SectionTitle(context.t('settings.security')),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.fingerprint, color: p.brand, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('settings.bio_title'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: p.text,
                            ),
                          ),
                          Text(
                            context.t('settings.bio_hint'),
                            style: TextStyle(fontSize: 12, color: p.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _biometric,
                      onChanged: _loaded ? _toggleBiometric : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: p.brand),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.t('pw.title'),
                        style: TextStyle(color: p.text),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: p.textMuted),
                  ],
                ),
              ),
              SectionTitle(context.t('settings.about')),
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: p.brand),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.t('app.name'),
                        style: TextStyle(color: p.text),
                      ),
                    ),
                    Text('1.0.0', style: TextStyle(color: p.textMuted)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
