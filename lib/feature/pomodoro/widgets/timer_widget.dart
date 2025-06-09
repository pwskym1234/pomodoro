import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final bool isFocusMode;
  final int minutes;
  final int seconds;
  final bool isActive;
  final bool isPaused;
  final VoidCallback onStartPauseResume;
  final VoidCallback onReset;

  const TimerDisplay({
    super.key,
    required this.isFocusMode,
    required this.minutes,
    required this.seconds,
    required this.isActive,
    required this.isPaused,
    required this.onStartPauseResume,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isFocusMode ? '집중 시간!' : '휴식 시간!',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.purple[600]),
        ),
        const SizedBox(height: 12),
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onStartPauseResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[500],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  elevation: 6,
                ),
                icon: Icon(isActive
                    ? (isPaused ? Icons.play_arrow : Icons.pause)
                    : Icons.play_arrow),
                label: Text(
                  isActive ? (isPaused ? '재개' : '일시정지') : '시작',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  elevation: 6,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('초기화',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
