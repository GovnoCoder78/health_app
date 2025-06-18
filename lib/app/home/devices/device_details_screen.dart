import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'utils/info_snackbar.dart';
import 'utils/extra.dart';
import 'utils/notification_history_manager.dart';
import 'message_history_screen.dart';

class DeviceDetailsScreen extends StatefulWidget {
  const DeviceDetailsScreen({
    super.key, 
    required this.device,
    required this.menuScreenContext,
  });
  
  final BluetoothDevice device;
  final BuildContext menuScreenContext;

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  int? _rssi;
  int? _mtuSize;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isDiscoveringServices = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  final NotificationHistoryManager _historyManager = NotificationHistoryManager();

  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;
  late StreamSubscription<int> _mtuSubscription;

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription = widget.device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // must rediscover services
        _historyManager.clearAllHistory();
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await widget.device.readRssi();
      }
      if (mounted) {
        setState(() {});
      }
    });

    _mtuSubscription = widget.device.mtu.listen((value) {
      _mtuSize = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isConnectingSubscription = widget.device.isConnecting.listen((value) {
      _isConnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isDisconnectingSubscription = widget.device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _mtuSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future onConnectPressed() async {
    try {
      await widget.device.connectAndUpdateStream();
      Snackbar.show(ABC.c, "Подключено успешно", success: true);
    } catch (e, backtrace) {
      if (e is FlutterBluePlusException && e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ABC.c, prettyException("Ошибка подключения:", e), success: false);
        print(e);
        print("backtrace: $backtrace");
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ABC.c, "Отменено успешно", success: true);
    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Ошибка отмены:", e), success: false);
      print("$e");
      print("backtrace: $backtrace");
    }
  }

  Future onDisconnectPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream();
      Snackbar.show(ABC.c, "Отключено успешно", success: true);
    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Ошибка отключения:", e), success: false);
      print("$e backtrace: $backtrace");
    }
  }

  Future onDiscoverServicesPressed() async {
    if (mounted) {
      setState(() {
        _isDiscoveringServices = true;
      });
    }
    try {
      _services = await widget.device.discoverServices();
      Snackbar.show(ABC.c, "Сервисы найдены успешно", success: true);
    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Ошибка поиска сервисов:", e), success: false);
      print(e);
      print("backtrace: $backtrace");
    }
    if (mounted) {
      setState(() {
        _isDiscoveringServices = false;
      });
    }
  }

  Future onRequestMtuPressed() async {
    try {
      await widget.device.requestMtu(223, predelay: 0);
      Snackbar.show(ABC.c, "MTU изменен успешно", success: true);
    } catch (e, backtrace) {
      Snackbar.show(ABC.c, prettyException("Ошибка изменения MTU:", e), success: false);
      print(e);
      print("backtrace: $backtrace");
    }
  }

  Widget buildSpinner(BuildContext context) {
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

  Widget buildRemoteId(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('${widget.device.remoteId}'),
    );
  }

  Widget buildRssiTile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isConnected ? const Icon(Icons.bluetooth_connected) : const Icon(Icons.bluetooth_disabled),
        Text(((isConnected && _rssi != null) ? '${_rssi!} dBm' : ''), 
          style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

  Widget buildGetServices(BuildContext context) {
    return IndexedStack(
      index: (_isDiscoveringServices) ? 1 : 0,
      children: <Widget>[
        TextButton(
          onPressed: onDiscoverServicesPressed,
          child: const Text("Найти сервисы"),
        ),
        const IconButton(
          icon: SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.grey),
            ),
          ),
          onPressed: null,
        )
      ],
    );
  }

  Widget buildMtuTile(BuildContext context) {
    return ListTile(
      title: const Text('Размер MTU'),
      subtitle: Text('$_mtuSize байт'),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: onRequestMtuPressed,
      )
    );
  }

  Widget buildConnectButton(BuildContext context) {
    return Row(children: [
      if (_isConnecting || _isDisconnecting) buildSpinner(context),
      ElevatedButton(
        onPressed: _isConnecting ? onCancelPressed : (isConnected ? onDisconnectPressed : onConnectPressed),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        child: Text(
          _isConnecting ? "ОТМЕНА" : (isConnected ? "ОТКЛЮЧИТЬ" : "ПОДКЛЮЧИТЬ"),
          style: Theme.of(context).primaryTextTheme.labelLarge?.copyWith(color: Colors.white),
        )
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyC,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.device.platformName),
          actions: [buildConnectButton(context), const SizedBox(width: 15)],
        ),
        body: ListView(
            children: <Widget>[
              buildRemoteId(context),
              ListTile(
                leading: buildRssiTile(context),
                title: Text('Устройство ${_connectionState.toString().split('.')[1]}.'),
                trailing: buildGetServices(context),
              ),
              buildMtuTile(context),
            if (_services.isNotEmpty) 
              ..._services.map((service) => ExpansionTile(
                title: Text('Сервис: ${service.uuid}'),
                children: service.characteristics.map((c) {
                  return ExpansionTile(
                    title: Text('Характеристика: ${c.uuid}'),
                    children: [
                      if (c.lastValue != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Последнее значение (HEX):', style: TextStyle(fontWeight: FontWeight.bold)),
                              SelectableText(
                                c.lastValue!.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' '),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                              const SizedBox(height: 8),
                              const Text('Последнее значение (DEC):', style: TextStyle(fontWeight: FontWeight.bold)),
                              SelectableText(
                                c.lastValue!.join(' '),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
            ],
          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (c.properties.read)
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Прочитать значение',
                                onPressed: () async {
                                  try {
                                    final value = await c.read();
                                    print('Прочитано значение от ${c.uuid}: ${value.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')}');
                                    _historyManager.addNotification(c.uuid.toString(), value);
                                    setState(() {});
                                  } catch (e) {
                                    print('Ошибка при чтении значения: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Ошибка: $e')),
                                    );
                                  }
                                },
                              ),
                            if (c.properties.write)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Записать значение',
                                onPressed: () {
                                  // TODO: Добавить диалог для ввода значения
                                },
                              ),
                            if (c.properties.notify)
                              IconButton(
                                icon: const Icon(Icons.history),
                                tooltip: 'История уведомлений (${_historyManager.getNotificationCount(c.uuid.toString())})',
                                onPressed: () async {
                                  try {
                                    print('Попытка включить уведомления для характеристики: ${c.uuid}');
                                    print('Текущие свойства характеристики:');
                                    print('- Read: ${c.properties.read}');
                                    print('- Write: ${c.properties.write}');
                                    print('- Notify: ${c.properties.notify}');
                                    print('- Indicate: ${c.properties.indicate}');
                                    
                                    // Проверяем состояние подключения
                                    final isConnected = await widget.device.isConnected;
                                    print('Состояние подключения: $isConnected');
                                    if (!isConnected) {
                                      print('Устройство отключено, пытаемся подключиться...');
                                      await widget.device.connect();
                                      print('Подключение выполнено');
                                    }

                                    // Находим все характеристики с уведомлениями
                                    final services = await widget.device.discoverServices();
                                    BluetoothCharacteristic? ffd2Char;
                                    BluetoothCharacteristic? ffd3Char;

                                    for (var service in services) {
                                      for (var characteristic in service.characteristics) {
                                        if (characteristic.uuid.toString().toLowerCase().contains('ffd2')) {
                                          ffd2Char = characteristic;
                                        } else if (characteristic.uuid.toString().toLowerCase().contains('ffd3')) {
                                          ffd3Char = characteristic;
                                        }
                                      }
                                    }

                                    // Активируем уведомления на ffd2
                                    if (ffd2Char != null) {
                                      print('Активируем уведомления на ffd2...');
                                      await ffd2Char.setNotifyValue(true);
                                      print('Уведомления на ffd2 включены');
                                    }

                                    // Активируем уведомления на ffd3
                                    if (ffd3Char != null) {
                                      print('Активируем уведомления на ffd3...');
                                      await ffd3Char.setNotifyValue(true);
                                      print('Уведомления на ffd3 включены');

                                      // Пробуем специальные команды для активации шагомера
                                      if (ffd3Char.properties.write) {
                                        print('Отправляем специальные команды активации...');
                                        
                                        // Последовательность команд для активации
                                        final activationSequence = [
                                          [0x01, 0x00], // Инициализация
                                          [0x02, 0x01], // Активация шагомера
                                          [0x03, 0x01], // Включение уведомлений
                                          [0x04, 0x01], // Запрос данных
                                        ];

                                        for (var cmd in activationSequence) {
                                          print('Отправляем команду: ${cmd.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')}');
                                          await ffd3Char.write(cmd);
                                          print('Команда отправлена, ждем уведомлений...');
                                          await Future.delayed(const Duration(seconds: 2));
                                        }
                                      }
                                    }
                                    
                                    // Добавляем listener с подробным логированием
                                    c.onValueReceived.listen(
                                      (value) {
                                        print('=== ПОЛУЧЕНО УВЕДОМЛЕНИЕ ===');
                                        print('От характеристики: ${c.uuid}');
                                        print('Значение (HEX): ${value.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')}');
                                        print('Значение (DEC): ${value.join(', ')}');
                                        print('Длина данных: ${value.length} байт');
                                        print('========================');
                                        _historyManager.addNotification(c.uuid.toString(), value);
                                        setState(() {}); // Обновляем UI
                                      },
                                      onError: (error) {
                                        print('Ошибка при получении уведомления: $error');
                                      },
                                    );
                                    
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MessageHistoryScreen(
                                          characteristic: c,
                                          historyManager: _historyManager,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    print('Ошибка при работе с уведомлениями: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Ошибка: $e')),
                                    );
                                  }
                                },
                              ),
                            // Добавляем кнопку истории для всех характеристик
                            IconButton(
                              icon: const Icon(Icons.history),
                              tooltip: 'История значений (${_historyManager.getNotificationCount(c.uuid.toString())})',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessageHistoryScreen(
                                      characteristic: c,
                                      historyManager: _historyManager,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              )).toList(),
          ],
        ),
      ),
    );
  }
} 