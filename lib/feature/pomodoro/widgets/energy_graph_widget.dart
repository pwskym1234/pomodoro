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
        size: const Size(330, 170),
        painter: EnergyPainter(levels),
      ),
    );
  }
}


class EnergyPainter extends CustomPainter {
  final List<int> levels;
  EnergyPainter(this.levels);

  // Reduced left margin so the graph width reflects the number of cycles.
  static const double _leftMargin = 40;
  static const double _bottomMargin = 20;

  /// Logs the calculated points for the given [levels] and [size]. This can be
  /// used outside of the painting context to debug the values that will be
  /// drawn on the canvas.
  static void printEnergyPoints(List<int> levels, Size size) {
    final chartWidth = size.width - _leftMargin;
    final chartHeight = size.height - _bottomMargin;
    final stepX = chartWidth / (levels.length - 1 == 0 ? 1 : levels.length - 1);
    final stepY = chartHeight / 3;

    for (var i = 0; i < levels.length; i++) {
      final x = _leftMargin + i * stepX;
      final y = levels[i] * stepY;
      debugPrint('Point $i: x=$x, y=$y, level=${levels[i]}');
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - _leftMargin;
    final chartHeight = size.height - _bottomMargin;

    final paint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final stepX = chartWidth / (levels.length - 1 == 0 ? 1 : levels.length - 1);
    final stepY = chartHeight / 3;

    final path = Path();
    for (var i = 0; i < levels.length; i++) {
      final x = _leftMargin + i * stepX;
      final y = levels[i] * stepY;
      debugPrint('Point $i: x=$x, y=$y, level=${levels[i]}');
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Draw circles for each point so they are visible on the graph.
    final pointPaint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.fill;
    for (var i = 0; i < levels.length; i++) {
      final x = _leftMargin + i * stepX;
      final y = levels[i] * stepY;
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }

    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    canvas.drawLine(Offset(_leftMargin, chartHeight),
        Offset(size.width, chartHeight), axisPaint);
    canvas.drawLine(
        Offset(_leftMargin, 0), Offset(_leftMargin, chartHeight), axisPaint);

    // y-axis labels
    for (var i = 1; i <= 3; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
            text: '$i',
            style: const TextStyle(color: Colors.black, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
          canvas,
          Offset(_leftMargin - 8 - textPainter.width,
              i * stepY - textPainter.height / 2));
    }

    // x-axis labels (minutes)
    const cycleMinutes = 25;
    for (var i = 0; i < levels.length; i++) {
      final minute = (i + 1) * cycleMinutes;
      final textPainter = TextPainter(
        text: TextSpan(
            text: '$minute',
            style: const TextStyle(color: Colors.black, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
          canvas,
          Offset(_leftMargin + i * stepX - textPainter.width / 2,
              chartHeight + 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EnergyGraphPanel extends StatelessWidget {
  final List<int> levels;
  final String title;

  const EnergyGraphPanel({super.key, required this.levels, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          width: double.infinity,
          child: CustomPaint(
            painter: EnergyPainter(levels),
          ),
        ),
      ],
    );
  }
}
