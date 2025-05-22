import 'package:flutter/material.dart';

enum DeviceType {
  watch,
  scale,
  headphones,
  smartphone,
  tablet,
}

class Device {
  final String name;
  final DeviceType type;
  final bool isConnected;
  final String? batteryLevel;

  const Device({
    required this.name,
    required this.type,
    required this.isConnected,
    this.batteryLevel,
  });
}

class DevicesList extends StatefulWidget {
  const DevicesList({Key? key}) : super(key: key);

  @override
  State<DevicesList> createState() => _DevicesListState();
}

class _DevicesListState extends State<DevicesList> {
  // Пример списка устройств
  final List<Device> _devices = [
    const Device(
      name: 'Apple Watch Series 8',
      type: DeviceType.watch,
      isConnected: true,
      batteryLevel: '85%',
    ),
  ];

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.watch:
        return Icons.watch;
      case DeviceType.scale:
        return Icons.monitor_weight;
      case DeviceType.headphones:
        return Icons.headphones;
      case DeviceType.smartphone:
        return Icons.smartphone;
      case DeviceType.tablet:
        return Icons.tablet;
    }
  }

  Color _getDeviceIconColor(DeviceType type, bool isConnected) {
    if (!isConnected) {
      return Colors.grey;
    }

    switch (type) {
      case DeviceType.watch:
        return Colors.blue;
      case DeviceType.scale:
        return Colors.green;
      case DeviceType.headphones:
        return Colors.purple;
      case DeviceType.smartphone:
        return Colors.orange;
      case DeviceType.tablet:
        return Colors.red;
    }
  }

  void _toggleConnection(int index) {
    setState(() {
      final device = _devices[index];
      _devices[index] = Device(
        name: device.name,
        type: device.type,
        isConnected: !device.isConnected,
        batteryLevel: device.batteryLevel,
      );
    });

    final action = _devices[index].isConnected ? 'подключено' : 'отключено';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_devices[index].name} $action'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Устройства не найдены',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Нажмите "Найти устройства" для поиска',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final device = _devices[index];

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _toggleConnection(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Иконка устройства
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getDeviceIconColor(device.type, device.isConnected)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getDeviceIcon(device.type),
                      color: _getDeviceIconColor(device.type, device.isConnected),
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Информация об устройстве
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            // Статус подключения
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: device.isConnected
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                device.isConnected ? 'Подключено' : 'Не подключено',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: device.isConnected
                                      ? Colors.green[700]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            // Уровень батареи (если доступен)
                            if (device.isConnected && device.batteryLevel != null) ...[
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.battery_full,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    device.batteryLevel!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Индикатор подключения
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: device.isConnected ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}