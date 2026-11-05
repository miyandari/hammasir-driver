import 'package:hammasir_driver/core/network/api_client.dart';
import 'package:hammasir_driver/core/utils/json_utils.dart';
import 'package:hammasir_driver/data/models/notification_item.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<List<NotificationItem>> list({int limit = 50}) async {
    final data = await _api.get(
      '/notifications/',
      query: {'limit': '$limit'},
    );
    return [for (final item in asMapList(data)) NotificationItem.fromJson(item)];
  }

  Future<int> unreadCount() async {
    final data = await _api.get('/notifications/unread-count');
    return asInt(asMap(data)?['unread_count']) ?? 0;
  }

  Future<void> markRead(int id) async {
    await _api.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.patch('/notifications/read-all');
  }
}
