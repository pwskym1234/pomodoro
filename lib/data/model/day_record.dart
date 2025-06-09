import 'cycle_record.dart';

class DayRecord {
  final String date;
  final List<CycleRecord> cycles;

  DayRecord({required this.date, required this.cycles});

  factory DayRecord.fromJson(Map<String, dynamic> json) {
    return DayRecord(
      date: json['date'] ?? '',
      cycles: (json['cycles'] as List? ?? [])
          .map((e) => CycleRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'cycles': cycles.map((e) => e.toJson()).toList(),
    };
  }
}
