import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_steps_tracker/app/home/devices/utils/notification_history_manager.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepsUtils {
  static const double stepLength = 0.8; // 80 см в метрах
  static const double caloriesPerStep = 0.04; // Примерно 0.04 ккал на шаг для человека среднего веса
  
  // Пороговые значения для определения шагов
  static const double stepThreshold = 7.0; // Порог для определения шага
  static const double shakeThreshold = 15.0; // Порог для определения тряски
  static const int minStepInterval = 300; // Минимальный интервал между шагами (мс)
  static const int magnitudeWindowSize = 5; // Размер окна для анализа

  static double calculateKilometers(int steps) {
    return (steps * stepLength) / 1000; // Конвертируем метры в километры
  }

  static double calculateCalories(int steps) {
    return steps * caloriesPerStep;
  }

  static double getMagnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  static bool isValidStep(double magnitude, double previousMagnitude, DateTime? lastStepTime, List<double> recentMagnitudes) {
    final now = DateTime.now();
    
    // Проверяем минимальный интервал между шагами
    if (lastStepTime != null) {
      final timeSinceLastStep = now.difference(lastStepTime).inMilliseconds;
      if (timeSinceLastStep < minStepInterval) {
        return false;
      }
    }

    // Проверяем на тряску
    if (recentMagnitudes.length >= magnitudeWindowSize) {
      // Вычисляем среднее значение и максимальное отклонение
      double sum = 0;
      double maxDeviation = 0;
      for (var mag in recentMagnitudes) {
        sum += mag;
      }
      double average = sum / recentMagnitudes.length;
      
      for (var mag in recentMagnitudes) {
        double deviation = (mag - average).abs();
        if (deviation > maxDeviation) {
          maxDeviation = deviation;
        }
      }

      // Если максимальное отклонение слишком большое, считаем это тряской
      if (maxDeviation > shakeThreshold) {
        return false;
      }
    }

    // Проверяем, что изменение ускорения находится в разумных пределах
    double distance = magnitude - previousMagnitude;
    if (distance > stepThreshold && distance < shakeThreshold) {
      return true;
    }

    return false;
  }

  static Future<double> getPreviousMagnitude() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getDouble("preValue") ?? 0.0;
  }

  static Future<void> savePreviousMagnitude(double magnitude) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setDouble("preValue", magnitude);
  }

  static Future<void> setupStepCounterNotifications(
    BluetoothDevice device,
    NotificationHistoryManager historyManager,
    Function(List<int>) onDataReceived,
  ) async {
    try {
      // Находим все характеристики с уведомлениями
      final services = await device.discoverServices();
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
        await ffd2Char.setNotifyValue(true);
      }

      // Активируем уведомления на ffd3
      if (ffd3Char != null) {
        await ffd3Char.setNotifyValue(true);

        // Последовательность команд для активации шагомера
        if (ffd3Char.properties.write) {
          final activationSequence = [
            [0x01, 0x00], // Инициализация
            [0x02, 0x01], // Активация шагомера
            [0x03, 0x01], // Включение уведомлений
            [0x04, 0x01], // Запрос данных
          ];

          for (var cmd in activationSequence) {
            await ffd3Char.write(cmd);
            await Future.delayed(const Duration(seconds: 2));
          }
        }

        // Добавляем listener для получения данных
        ffd3Char.onValueReceived.listen(
          (value) {
            historyManager.addNotification(ffd3Char!.uuid.toString(), value);
            onDataReceived(value);
          },
          onError: (error) {
            print('Ошибка при получении уведомления: $error');
          },
        );
      }
    } catch (e) {
      print('Ошибка при настройке уведомлений: $e');
      rethrow;
    }
  }
} 