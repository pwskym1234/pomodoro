class CycleRecord {
  final String goal;
  final int complexity;
  final int energy;
  final String startTime;

  CycleRecord({
    required this.goal,
    required this.complexity,
    required this.energy,
    required this.startTime,
  });

  factory CycleRecord.fromJson(Map<String, dynamic> json) {
    return CycleRecord(
      goal: json['goal'] ?? '',
      complexity: json['complexity'] ?? 1,
      energy: json['energy'] ?? 1,
      startTime: json['startTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal': goal,
      'complexity': complexity,
      'energy': energy,
      'startTime': startTime,
    };
  }
}
