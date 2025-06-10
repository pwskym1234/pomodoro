import 'package:flutter/material.dart';

class EnergyGraph extends StatelessWidget {
  final List<int> levels;
  final VoidCallback onClose;

  const EnergyGraph({super.key, required this.levels, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('하루 에너지 그래프',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        ],
      ),
      content: CustomPaint(
        size: const Size(300, 150),
        painter: _EnergyPainter(levels),
      ),
    );
  }
}

class HourlyGraph extends StatelessWidget {
  final List<double> levels;
  final String title;

  const HourlyGraph({super.key, required this.levels, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          width: double.infinity,
          child: CustomPaint(painter: _HourlyPainter(levels)),
        ),
      ],
    );
  }
}

class _HourlyPainter extends CustomPainter {
  final List<double> levels;

  _HourlyPainter(this.levels);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final stepX = size.width / (levels.length - 1 == 0 ? 1 : levels.length - 1);
    final stepY = size.height / 3;
    final path = Path();
    for (var i = 0; i < levels.length; i++) {
      final x = i * stepX;
      final y = size.height - levels[i] * stepY;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _EnergyPainter extends CustomPainter {
  final List<int> levels;
  _EnergyPainter(this.levels);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final stepX = size.width / (levels.length - 1 == 0 ? 1 : levels.length - 1);
    final stepY = size.height / 3;
    final path = Path();
    for (var i = 0; i < levels.length; i++) {
      final x = i * stepX;
      final y = size.height - levels[i] * stepY;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

