import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'utils/notification_history_manager.dart';

class MessageHistoryScreen extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final NotificationHistoryManager historyManager;

  const MessageHistoryScreen({
    super.key,
    required this.characteristic,
    required this.historyManager,
  });

  @override
  Widget build(BuildContext context) {
    final notifications = historyManager.getHistory(characteristic.uuid.toString()) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('История сообщений: ${characteristic.uuid}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              historyManager.clearHistory(characteristic.uuid.toString());
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text('Нет сохраненных сообщений'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Время: ${notification.timestamp.toString()}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          'HEX: ${notification.value.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          'DEC: ${notification.value.join(', ')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
} 