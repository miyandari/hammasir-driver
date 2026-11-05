import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:hammasir_driver/core/network/api_exception.dart';
import 'package:hammasir_driver/core/utils/load_status.dart';
import 'package:hammasir_driver/core/utils/safe_notifier.dart';
import 'package:hammasir_driver/data/models/notification_item.dart';
import 'package:hammasir_driver/data/repositories/notification_repository.dart';

class NotificationsStore extends ChangeNotifier with SafeNotifier {
  NotificationsStore(this._repository);

  static const Duration pollInterval = Duration(seconds: 60);

  final NotificationRepository _repository;

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  List<NotificationItem> _items = const [];
  int _unread = 0;
  Timer? _timer;

  LoadStatus get status => _status;
  String? get error => _error;
  List<NotificationItem> get items => _items;
  int get unread => _unread;

  /// شمارش خوانده‌نشده‌ها را هر ۶۰ ثانیه تازه می‌کند (فقط وقتی اپ باز است).
  void startPolling() {
    _timer ??= Timer.periodic(pollInterval, (_) => refreshCount());
    unawaited(refreshCount());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refreshCount() async {
    try {
      final count = await _repository.unreadCount();
      if (count != _unread) {
        _unread = count;
        notifyListeners();
      }
    } on ApiException {
      // شمارنده حیاتی نیست؛ بی‌صدا رد می‌شود.
    }
  }

  Future<void> load() async {
    if (_items.isEmpty) {
      _status = LoadStatus.loading;
      notifyListeners();
    }

    try {
      _items = await _repository.list();
      _unread = _items.where((n) => !n.isRead).length;
      _status = LoadStatus.ready;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      if (_items.isEmpty) _status = LoadStatus.error;
    }

    notifyListeners();
  }

  Future<void> markRead(NotificationItem item) async {
    if (item.isRead) return;

    _items = [
      for (final n in _items) n.id == item.id ? n.markRead() : n,
    ];
    if (_unread > 0) _unread--;
    notifyListeners();

    try {
      await _repository.markRead(item.id);
    } on ApiException {
      // دفعه‌ی بعد که لیست بارگذاری شد وضعیت واقعی جایگزین می‌شود.
    }
  }

  Future<void> markAllRead() async {
    _items = [for (final n in _items) n.markRead()];
    _unread = 0;
    notifyListeners();

    try {
      await _repository.markAllRead();
    } on ApiException {
      await load();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
