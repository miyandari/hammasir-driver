import 'package:hammasir_driver/core/utils/json_utils.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  /// اگر اعلان به یک سفر مربوط باشد شناسه‌اش را برمی‌گرداند.
  int? get tripId => asInt(data?['trip_id']);

  NotificationItem markRead() {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: true,
      createdAt: createdAt,
      data: data,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: asInt(json['id']) ?? 0,
      type: asString(json['notification_type']),
      title: asString(json['title']),
      message: asString(json['message']),
      isRead: asBool(json['is_read']),
      createdAt: asDate(json['created_at']) ?? DateTime.now(),
      data: asMap(json['data']),
    );
  }
}
