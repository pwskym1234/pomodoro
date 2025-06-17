import 'dart:async';
import 'package:flutter/material.dart';

class TimerController {
  Timer? _timer;
  bool isPaused = false;

  void startTimer({
    required int minutes,
    required VoidCallback onComplete,
    required void Function(int minutes, int seconds) onTick,
  }) {
    int totalSeconds = minutes * 60;
    _timer?.cancel();
    onTick(totalSeconds ~/ 60, totalSeconds % 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isPaused) return;
      totalSeconds--;
      if (totalSeconds < 0) {
        timer.cancel();
        onComplete();
      } else {
        onTick(totalSeconds ~/ 60, totalSeconds % 60);
      }
    });
  }

  void pause() {
    isPaused = true;
  }

  void resume() {
    isPaused = false;
  }

  void cancel() {
    _timer?.cancel();
  }

  bool get isRunning => _timer?.isActive ?? false;
}
