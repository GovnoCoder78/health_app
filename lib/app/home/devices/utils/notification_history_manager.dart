import 'package:flutter/material.dart';

class NotificationEntry {
  final List<int> value;
  final DateTime timestamp;

  NotificationEntry(this.value) : timestamp = DateTime.now();
}

class NotificationHistoryManager {
  final Map<String, List<NotificationEntry>> _notificationHistory = {};

  void addNotification(String characteristicId, List<int> value) {
    if (!_notificationHistory.containsKey(characteristicId)) {
      _notificationHistory[characteristicId] = [];
    }
    _notificationHistory[characteristicId]!.add(NotificationEntry(value));
    // Ограничиваем историю последними 10 значениями
    if (_notificationHistory[characteristicId]!.length > 10) {
      _notificationHistory[characteristicId]!.removeAt(0);
    }
  }

  void clearHistory(String characteristicId) {
    _notificationHistory[characteristicId]?.clear();
  }

  void clearAllHistory() {
    _notificationHistory.clear();
  }

  List<NotificationEntry>? getHistory(String characteristicId) {
    return _notificationHistory[characteristicId];
  }

  bool hasNotifications(String characteristicId) {
    return _notificationHistory[characteristicId]?.isNotEmpty ?? false;
  }

  int getNotificationCount(String characteristicId) {
    return _notificationHistory[characteristicId]?.length ?? 0;
  }
} 