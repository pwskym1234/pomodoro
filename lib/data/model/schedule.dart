class Schedule {
  final Map<String, List<String>> days;

  Schedule({required this.days});

  factory Schedule.empty(List<String> dayKeys, int slotCount) {
    return Schedule(
      days: {
        for (var d in dayKeys) d: List.filled(slotCount, 'none'),
      },
    );
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    final map = <String, List<String>>{};
    for (final entry in json.entries) {
      map[entry.key] = (entry.value as List).map((e) => e.toString()).toList();
    }
    return Schedule(days: map);
  }

  Map<String, dynamic> toJson() => days;
}
