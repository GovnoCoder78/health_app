import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/app/home/pedometer/utils/steps_utils.dart';

class StepsRings extends StatelessWidget {
  final int steps;
  final double targetSteps;
  final double targetKilometers;
  final double targetCalories;

  const StepsRings({
    super.key,
    required this.steps,
    required this.targetSteps,
    required this.targetKilometers,
    required this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    final kilometers = StepsUtils.calculateKilometers(steps);
    final calories = StepsUtils.calculateCalories(steps);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Внешнее кольцо (шаги)
          SizedBox(
            width: 300,
            height: 300,
            child: CustomPaint(
              painter: RingPainter(
                progress: steps / targetSteps,
                color: Colors.blue,
                strokeWidth: 20,
              ),
            ),
          ),
          // Среднее кольцо (километры)
          SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: RingPainter(
                progress: kilometers / targetKilometers,
                color: Colors.red,
                strokeWidth: 20,
              ),
            ),
          ),
          // Внутреннее кольцо (калории)
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: RingPainter(
                progress: calories / targetCalories,
                color: Colors.green,
                strokeWidth: 20,
              ),
            ),
          ),
          // Центральный текст
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$steps',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'шагов',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Рисуем фон кольца
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Рисуем прогресс
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Начинаем с верхней точки (-90 градусов)
      progress * 6.2832, // 2 * PI
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
} 