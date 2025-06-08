import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({
    Key? key,
    required this.result,
    required this.onTap,
  }) : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  String get _name {
    return result.device.platformName;
  }

  String get _id {
    return result.device.remoteId.toString();
  }

  int get _rssi {
    return result.rssi;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.white,
      child: ListTile(
        title: Text(
          _name.isEmpty ? 'Неизвестное устройство' : _name,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _id,
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: Text(
          '$_rssi dBm',
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
