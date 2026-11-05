import 'package:flutter/material.dart';

import 'package:hammasir_driver/app/stores.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/utils/persian.dart';
import 'package:hammasir_driver/core/widgets/app_card.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/core/widgets/user_avatar.dart';
import 'package:hammasir_driver/features/profile/about_screen.dart';
import 'package:hammasir_driver/features/profile/contact_screen.dart';
import 'package:hammasir_driver/features/profile/settings_screen.dart';
import 'package:hammasir_driver/features/shared/page_header.dart';
import 'package:hammasir_driver/features/shared/ui_helpers.dart';
import 'package:hammasir_driver/l10n/l10n.dart';
import 'package:hammasir_driver/state/session_controller.dart';

/// پروفایل راننده: مشخصات، خودرو، تنظیمات، درباره، خروج.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.session});

  final SessionController session;

  Future<void> _logout(BuildContext context) async {
    final stores = StoresScope.read(context);
    final active = stores.tracking.isRunning;

    final ok = await confirm(
      context,
      title: context.t('profile.logout_title'),
      message: context.t(
        active ? 'drv.logout_active_msg' : 'profile.logout_message',
      ),
      confirmLabel: context.t('profile.logout'),
      icon: Icons.logout_rounded,
      destructive: true,
      tone: Tone.danger,
    );
    if (ok) await session.logout();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stores = StoresScope.read(context);

    return ListenableBuilder(
      listenable: Listenable.merge([stores.trips, session]),
      builder: (context, _) {
        final me = stores.trips.me;
        final name = me?.fullName.isNotEmpty == true
            ? me!.fullName
            : (session.profile?.fullName ?? '');
        final vehicle = me?.vehicle;

        return Column(
          children: [
            PageHeader(title: context.t('profile.title')),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        UserAvatar(name: name, size: 60),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.t('drv.role'),
                                style: TextStyle(color: p.textMuted),
                              ),
                              if (me?.phone != null)
                                Text(
                                  Fa.digits(me!.phone),
                                  style: TextStyle(
                                    color: p.textMuted,
                                    fontSize: 12.5,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (vehicle != null) ...[
                    const SizedBox(height: 10),
                    AppCard(
                      child: Row(
                        children: [
                          Icon(Icons.directions_bus_rounded, color: p.brand),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.t('drv.vehicle'),
                                  style: TextStyle(
                                    color: p.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${Fa.digits(vehicle.plate)} · ${Fa.digits(vehicle.capacity)} ${context.t('drv.seat')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    title: context.t('settings.title'),
                    page: const SettingsScreen(),
                  ),
                  _MenuTile(
                    icon: Icons.info_outline,
                    title: context.t('profile.about'),
                    page: const AboutScreen(),
                  ),
                  _MenuTile(
                    icon: Icons.support_agent_outlined,
                    title: context.t('profile.contact'),
                    page: const ContactScreen(),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: Icon(Icons.logout_rounded, color: p.danger),
                    label: Text(
                      context.t('profile.logout'),
                      style: TextStyle(color: p.danger),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(color: p.dangerBorder),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.page,
  });

  final IconData icon;
  final String title;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => page),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.palette.brand),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      ),
    );
  }
}
