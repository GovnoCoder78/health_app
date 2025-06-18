import 'package:flutter/material.dart';

class NotificationHistoryCard extends StatelessWidget {
  final String characteristicId;
  final List<List<int>> notifications;
  final VoidCallback onClear;

  const NotificationHistoryCard({
    super.key,
    required this.characteristicId,
    required this.notifications,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('История уведомлений:', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Очистить'),
                  onPressed: onClear,
                ),
              ],
            ),
            const Divider(),
            ...notifications.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              return Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Уведомление #${index + 1}:',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      SelectableText(
                        'HEX: ${value.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      SelectableText(
                        'DEC: ${value.join(' ')}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
} 