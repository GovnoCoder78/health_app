import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/services/my_database.dart';
import 'package:flutter_steps_tracker/utils/colors.dart';
import 'package:flutter_steps_tracker/utils/show_snack_bar.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_steps_tracker/app/home/devices/utils/notification_history_manager.dart';
import 'package:flutter_steps_tracker/app/home/pedometer/utils/steps_utils.dart';
import 'package:flutter_steps_tracker/app/home/pedometer/widgets/steps_rings.dart';

String formatDate(DateTime d) {
  return d.toString().substring(0, 19);
}

class StepsCounterScreen extends StatefulWidget {
  const StepsCounterScreen({
    super.key,
    required this.menuScreenContext,
  });
  
  final BuildContext menuScreenContext;

  @override
  State<StepsCounterScreen> createState() => _StepsCounterScreenState();
}

class _StepsCounterScreenState extends State<StepsCounterScreen> with WidgetsBindingObserver {
  int _steps = 0;
  double _previousMagnitude = 0.0;
  DateTime? _lastStepTime;
  List<double> _recentMagnitudes = [];
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _saveTimer;
  bool _hasUnsavedSteps = false;

  // Целевые значения
  static const double targetSteps = 10000;
  static const double targetKilometers = 8; // 8 км
  static const double targetCalories = 400; // 400 ккал

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSteps();
    _startAccelerometerSubscription();
    _startPeriodicSave();
  }

  Future<void> _initializeSteps() async {
    _previousMagnitude = await StepsUtils.getPreviousMagnitude();
    // Загружаем сохраненные шаги из базы данных
    final database = Provider.of<MyDatabase>(context, listen: false);
    final savedSteps = await database.getSteps();
    setState(() {
      _steps = savedSteps;
    });
  }

  void _startAccelerometerSubscription() {
    _accelerometerSubscription = SensorsPlatform.instance.accelerometerEvents.listen((event) {
      final magnitude = StepsUtils.getMagnitude(event.x, event.y, event.z);
      
      // Добавляем значение в окно анализа
      _recentMagnitudes.add(magnitude);
      if (_recentMagnitudes.length > StepsUtils.magnitudeWindowSize) {
        _recentMagnitudes.removeAt(0);
      }

      if (StepsUtils.isValidStep(magnitude, _previousMagnitude, _lastStepTime, _recentMagnitudes)) {
        setState(() {
          _steps++;
          _hasUnsavedSteps = true;
          _lastStepTime = DateTime.now();
        });
      }

      _previousMagnitude = magnitude;
      StepsUtils.savePreviousMagnitude(magnitude);
    });
  }

  void _startPeriodicSave() {
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_hasUnsavedSteps) {
        _saveStepsToDatabase();
        _hasUnsavedSteps = false;
      }
    });
  }

  Future<void> _saveStepsToDatabase() async {
    if (_steps > 0) {
      final database = Provider.of<MyDatabase>(context, listen: false);
      await database.updateSteps(_steps);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accelerometerSubscription?.cancel();
    _saveTimer?.cancel();
    if (_hasUnsavedSteps) {
      _saveStepsToDatabase();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      if (_hasUnsavedSteps) {
        _saveStepsToDatabase();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Шагомер'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Шагомер использует акселерометр для подсчета шагов'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          StepsRings(
            steps: _steps,
            targetSteps: targetSteps,
            targetKilometers: targetKilometers,
            targetCalories: targetCalories,
          ),
          const SizedBox(height: 40),
          // Статистика
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Километры',
                  '${StepsUtils.calculateKilometers(_steps).toStringAsFixed(1)}',
                  Colors.red,
                ),
                _buildStatItem(
                  'Калории',
                  '${StepsUtils.calculateCalories(_steps).toStringAsFixed(0)}',
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
