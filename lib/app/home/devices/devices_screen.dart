import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'bluetooth_off_screen.dart';
import 'scan_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key, required this.menuScreenContext});
  final BuildContext menuScreenContext;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _adapterStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_adapterState == BluetoothAdapterState.on) {
      return const ScanScreen();
    } else {
      return BluetoothOffScreen(adapterState: _adapterState);
    }
  }
}

