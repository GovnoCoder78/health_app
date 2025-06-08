import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SystemDeviceTile extends StatelessWidget {
  const SystemDeviceTile({
    Key? key,
    required this.device,
    required this.onOpen,
    required this.onConnect,
  }) : super(key: key);

  final BluetoothDevice device;
  final VoidCallback onOpen;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      child: ListTile(
        title: Text(
          device.platformName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          device.remoteId.toString(),
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: const Text('ОТКРЫТЬ'),
            ),
            TextButton(
              onPressed: onConnect,
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              child: const Text('ПОДКЛЮЧИТЬ'),
            ),
          ],
        ),
      ),
    );
  }
}
