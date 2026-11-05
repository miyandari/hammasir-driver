import 'package:flutter/material.dart';

import 'package:hammasir_driver/app/stores.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/utils/load_status.dart';
import 'package:hammasir_driver/core/utils/persian.dart';
import 'package:hammasir_driver/core/widgets/app_card.dart';
import 'package:hammasir_driver/core/widgets/state_views.dart';
import 'package:hammasir_driver/data/models/notification_item.dart';
import 'package:hammasir_driver/features/shared/page_header.dart';
import 'package:hammasir_driver/features/trips/trip_screen.dart';
import 'package:hammasir_driver/l10n/l10n.dart';
import 'package:hammasir_driver/state/notifications_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsStore _store;

  @override
  void initState() {
    super.initState();
    _store = StoresScope.read(context).notifications;
    _store.load();
  }

  void _open(NotificationItem item) {
    _store.markRead(item);

    final tripId = item.tripId;
    if (tripId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TripScreen(tripId: tripId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        return Column(
          children: [
            PageHeader(
              title: context.t('notif.title'),
              trailing: _store.unread > 0
                  ? TextButton(
                      onPressed: _store.markAllRead,
                      child: Text(context.t('notif.mark_all')),
                    )
                  : null,
            ),
            Expanded(child: _body(context)),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    if (_store.status == LoadStatus.loading && _store.items.isEmpty) {
      return const CenteredLoader();
    }

    if (_store.status == LoadStatus.error && _store.items.isEmpty) {
      return ErrorState(
        message: _store.error ?? context.t('notif.load_failed'),
        onRetry: _store.load,
      );
    }

    return RefreshIndicator(
      onRefresh: _store.load,
      child: _store.items.isEmpty
          ? EmptyState(
              icon: Icons.notifications_none,
              message: context.t('notif.empty'),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _store.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _store.items[index];
                return _NotificationTile(item: item, onTap: () => _open(item));
              },
            ),
    );
  }
}

IconData _iconFor(String type) {
  if (type.contains('arrival')) return Icons.directions_bus_rounded;
  if (type.contains('penalty') || type.contains('block')) {
    return Icons.warning_amber_rounded;
  }
  if (type.contains('boarding')) return Icons.how_to_reg_rounded;
  if (type.contains('reservation') || type.contains('waitlist')) {
    return Icons.event_available_rounded;
  }
  return Icons.notifications_rounded;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context); // با تغییر زبان، زمان نسبی دوباره ساخته شود
    final p = context.palette;

    return AppCard(
      onTap: onTap,
      color: item.isRead ? p.surface : p.brandSoft,
      borderColor: item.isRead ? p.border : p.brandSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.isRead ? p.brandSoft : p.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(_iconFor(item.type), size: 22, color: p.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: TextStyle(color: p.text, height: 1.7, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  Fa.relative(item.createdAt),
                  style: TextStyle(color: p.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!item.isRead)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(Icons.circle, size: 10, color: p.brand),
            ),
        ],
      ),
    );
  }
}
