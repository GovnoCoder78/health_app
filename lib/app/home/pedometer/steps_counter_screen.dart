import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/services/my_database.dart';
import 'package:flutter_steps_tracker/utils/colors.dart';
import 'package:flutter_steps_tracker/utils/show_snack_bar.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

class StepsCounterScreen extends StatefulWidget {
  const StepsCounterScreen({super.key, required this.menuScreenContext});
  final BuildContext menuScreenContext;

  @override
  State<StepsCounterScreen> createState() => _StepsCounterScreenState();
}

class _StepsCounterScreenState extends State<StepsCounterScreen> with WidgetsBindingObserver {
  double x = 0.0;
  double y = 0.0;
  double z = 0.0;
  int steps = 0;
  double distance = 0.0;
  Timer? _saveTimer;
  bool _hasUnsavedSteps = false;
  double previousDistacne = 0.0;
  late MyDatabase _database;
  bool _isInitialized = false;
  int _lastAwardedStep = 0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Переменные для опредедения шагов и тряски
  static const double _stepThreshold = 7.0; // Порог для определения шага
  static const double _shakeThreshold = 15.0; // Порог для определения тряски
  static const int _minStepInterval = 300; // Минимальный интервал между шагами (мс)
  DateTime? _lastStepTime;
  List<double> _recentMagnitudes = []; // Хранит последние значения магнитуды
  static const int _magnitudeWindowSize = 5; // Размер окна для анализа

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _database = Provider.of<MyDatabase>(context, listen: false);
    if (!_isInitialized) {
      _initializeSteps();
      _isInitialized = true;
    }
  }

  double getValue(double x, double y, double z) {
    double magnitude = sqrt(x * x + y * y + z * z);
    getPreviousValue();
    double modDistance = magnitude - previousDistacne;
    setPreviousValue(magnitude);
    
    // Добавляем значение в окно анализа
    _recentMagnitudes.add(modDistance);
    if (_recentMagnitudes.length > _magnitudeWindowSize) {
      _recentMagnitudes.removeAt(0);
    }
    
    return modDistance;
  }

  Future<void> _initializeSteps() async {
    final savedSteps = await _database.getSteps();
    await _initializePreviousDistance();
    setState(() {
      steps = savedSteps;
      _lastAwardedStep = (steps ~/ 10) * 10;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicSave();
    _startAccelerometerSubscription();
  }

  void _startAccelerometerSubscription() {
    _accelerometerSubscription = SensorsPlatform.instance.accelerometerEvents.listen((event) {
      x = event.x;
      y = event.y;
      z = event.z;
      distance = getValue(x, y, z);
      _updateSteps();
    });
  }

  bool _isValidStep() {
    final now = DateTime.now();
    
    // Проверяем минимальный интервал между шагами
    if (_lastStepTime != null) {
      final timeSinceLastStep = now.difference(_lastStepTime!).inMilliseconds;
      if (timeSinceLastStep < _minStepInterval) {
        return false;
      }
    }

    // Проверяем на тряску
    if (_recentMagnitudes.length >= _magnitudeWindowSize) {
      // Вычисляем среднее значение и максимальное отклонение
      double sum = 0;
      double maxDeviation = 0;
      for (var magnitude in _recentMagnitudes) {
        sum += magnitude;
      }
      double average = sum / _recentMagnitudes.length;
      
      for (var magnitude in _recentMagnitudes) {
        double deviation = (magnitude - average).abs();
        if (deviation > maxDeviation) {
          maxDeviation = deviation;
        }
      }

      // Если максимальное отклонение слишком большое, считаем это тряской
      if (maxDeviation > _shakeThreshold) {
        return false;
      }
    }

    // Проверяем, что изменение ускорения находится в разумных пределах
    if (distance > _stepThreshold && distance < _shakeThreshold) {
      _lastStepTime = now;
      return true;
    }

    return false;
  }

  void getPoints() {
    if (steps > _lastAwardedStep) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        showSnackBar(context, "Поздравляем, вы получили 10 очков!");
        _database.updatePoints();
        _lastAwardedStep = steps;
      });
    }
  }

  void setPreviousValue(double distance) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setDouble("preValue", distance);
  }

  Future<void> _initializePreviousDistance() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    previousDistacne = pref.getDouble("preValue") ?? 0.0;
  }

  void getPreviousValue() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    previousDistacne = pref.getDouble("preValue") ?? 0.0;
  }

  void _startPeriodicSave() {
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (steps > 0) {
        _hasUnsavedSteps = true;
        _saveStepsToDatabase();
      }
    });
  }

  void _saveStepsToDatabase() {
    if (steps > 0) {
      _database.updateSteps(steps);
      _hasUnsavedSteps = false;
    }
  }

  void _updateSteps() {
    if (_isValidStep()) {
      setState(() {
        steps++;
        _hasUnsavedSteps = true;
      });
      
      if (steps % 10 == 0 && steps > _lastAwardedStep) {
        getPoints();
        _saveStepsToDatabase();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _accelerometerSubscription?.cancel();
    if (_hasUnsavedSteps && steps > 0) {
      _database.updateSteps(steps);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      if (steps > 0) {
        _hasUnsavedSteps = true;
        _saveStepsToDatabase();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: darkGrey,
          title: const Text("Шагомер"),
          actions: [
            IconButton(
                onPressed: () {
                  showSnackBar(context,
                      "За каждые 10 шагов ты получишь 10 монет. Монеты можно обменять на реальные призы");
                },
                icon: const Icon(Icons.question_mark_rounded))
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "Вы прошли ${steps} шагов! Так держать",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
