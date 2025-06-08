import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_details_screen.dart';
import 'utils/info_snackbar.dart';
import 'package:flutter_steps_tracker/widgets/system_device_tile.dart';
import 'package:flutter_steps_tracker/widgets/scan_results_tile.dart';
import 'utils/extra.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Ошибка сканирования:", e), success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() {
          _isScanning = state;
        });
      }
    });

    // Автоматически начинаем сканирование при открытии экрана
    onScanPressed();
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      // Получаем системные устройства
      _systemDevices = await FlutterBluePlus.systemDevices([]);
      setState(() {});
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Ошибка системных устройств:", e), success: false);
    }
    
    try {
      // Останавливаем предыдущее сканирование, если оно активно
      if (_isScanning) {
        await FlutterBluePlus.stopScan();
      }
      
      // Начинаем новое сканирование
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Ошибка начала сканирования:", e), success: false);
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    device.connectAndUpdateStream().catchError((e) {
      Snackbar.show(ABC.c, prettyException("Ошибка подключения:", e), success: false);
    });
    MaterialPageRoute route = MaterialPageRoute(
        builder: (context) => DeviceDetailsScreen(
          device: device,
          menuScreenContext: context,
        ),
        settings: const RouteSettings(name: '/DeviceScreen'));
    Navigator.of(context).push(route);
  }

  Future onRefresh() async {
    await onScanPressed();
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget buildScanButton() {
    return Row(children: [
      if (_isScanning)
        buildSpinner()
      else
        ElevatedButton(
            onPressed: onScanPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("ПОИСК"))
    ]);
  }

  Widget buildSpinner() {
    return const Padding(
      padding: EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  List<Widget> _buildSystemDeviceTiles() {
    return _systemDevices
        .map(
          (d) => SystemDeviceTile(
            device: d,
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DeviceDetailsScreen(
                  device: d,
                  menuScreenContext: context,
                ),
                settings: const RouteSettings(name: '/DeviceScreen'),
              ),
            ),
            onConnect: () => onConnectPressed(d),
          ),
        )
        .toList();
  }

  Iterable<Widget> _buildScanResultTiles() {
    return _scanResults.map((r) => ScanResultTile(
          result: r, 
          onTap: () => onConnectPressed(r.device)
        ));
  }

  Widget _buildEmptyList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bluetooth_searching,
            size: 64,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            _isScanning ? 'Поиск устройств...' : 'Устройства не найдены',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (!_isScanning)
            ElevatedButton(
              onPressed: onScanPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('ПОИСК'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Поиск устройств'),
          actions: [buildScanButton(), const SizedBox(width: 15)],
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: _systemDevices.isEmpty && _scanResults.isEmpty
              ? _buildEmptyList()
              : ListView(
                  children: <Widget>[
                    ..._buildSystemDeviceTiles(),
                    ..._buildScanResultTiles(),
                  ],
                ),
        ),
      ),
    );
  }
}
