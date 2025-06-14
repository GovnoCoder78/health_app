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

class _StepsCounterScreenState extends State<StepsCounterScreen>
with WidgetsBindingObserver{
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
    return modDistance;
  }

  Future<void> _initializeSteps() async {
    final savedSteps = await _database.getSteps();
    await _initializePreviousDistance();
    setState(() {
      steps = savedSteps;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicSave();
  }

  void getPoints() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      showSnackBar(context, "Поздравляем, вы получили 10 очков!");
      _database.updatePoints();
    });
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
    setState(() {
      previousDistacne = pref.getDouble("preValue") ?? 0.0;
    });
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
    if (distance > 7) {
      setState(() {
        steps++;
        _hasUnsavedSteps = true;
      });
    }
    if (steps % 10 == 0 && steps > 10) {
      getPoints();
      _saveStepsToDatabase();
    }
  }

  Widget stepsBuilder(
      BuildContext context, AsyncSnapshot<AccelerometerEvent> snapshot) {
    if (snapshot.hasData) {
      x = snapshot.data!.x;
      y = snapshot.data!.y;
      z = snapshot.data!.z;
      distance = getValue(x, y, z);
      
      Future.microtask(() => _updateSteps());
      
      return Text(
        "Вы прошли ${steps} шагов! Так держать",
        style: const TextStyle(fontSize: 20),
      );
    }
    return const Text("No data");
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
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
                    child: StreamBuilder<AccelerometerEvent>(
                      stream: SensorsPlatform.instance.accelerometerEvents,
                      builder: stepsBuilder,
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
