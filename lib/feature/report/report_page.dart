import 'package:flutter/material.dart';
import '../../data/firebase_service.dart';
import '../../data/model/day_record.dart';
import '../../data/model/cycle_record.dart';
import '../pomodoro/widgets/energy_graph_widget.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final FirebaseService _firebaseService = FirebaseService();
  String _userId = '';
  List<DayRecord> _history = [];
  List<CycleRecord> _todayCycles = [];
  bool _loading = true;
  String _selectedDate = '';

  static const _startHour = 7;
  static const _endHour = 23;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _firebaseService.initializeFirebase();
    _userId = (await _firebaseService.authenticateUser()) ?? '';
    _firebaseService.getUserDataStream(_userId).listen((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        setState(() {
          _history = (data['history'] as List? ?? [])
              .map((e) => DayRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _todayCycles = (data['todayCycles'] as List? ?? [])
              .map((e) => CycleRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _selectedDate = _formatDate(DateTime.now());
          _loading = false;
        });
      }
    });
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  List<String> _availableDates() {
    final dates = _history.map((e) => e.date).toSet().toList();
    final today = _formatDate(DateTime.now());
    if (!dates.contains(today)) dates.add(today);
    dates.sort();
    return dates;
  }

  List<CycleRecord> _getCycles(String date) {
    if (date == _formatDate(DateTime.now())) {
      return _todayCycles;
    }
    return _history
            .firstWhere((d) => d.date == date, orElse: () => DayRecord(date: date, cycles: const []))
            .cycles;
  }

  Map<String, int> _weeklyMinutes() {
    final now = DateTime.now();
    final map = <String, int>{};
    for (var i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = _formatDate(day);
      final cycles = _getCycles(key);
      map[key] = cycles.length * 25;
    }
    final ordered = map.keys.toList()..sort();
    return {for (var k in ordered) k: map[k] ?? 0};
  }

  List<double> _hourlyLevels(String date, {required bool energy}) {
    final cycles = _getCycles(date);
    final hours = _endHour - _startHour + 1;
    final buckets = List.generate(hours, (_) => <int>[]);
    for (final c in cycles) {
      final parts = c.startTime.split(':');
      final hour = int.tryParse(parts.first) ?? 0;
      if (hour >= _startHour && hour <= _endHour) {
        buckets[hour - _startHour].add(energy ? c.energy : c.complexity);
      }
    }
    return buckets
        .map((b) => b.isEmpty ? 0.0 : b.reduce((a, b) => a + b) / b.length)
        .toList();
  }

  Widget _buildSummary() {
    final weekly = _weeklyMinutes();
    final dates = _availableDates();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DataTable(
            columns: const [
              DataColumn(label: Text('날짜')),
              DataColumn(label: Text('집중 시간(분)')),
            ],
            rows: weekly.entries
                .map((e) => DataRow(cells: [
                      DataCell(Text(e.key)),
                      DataCell(Text('${e.value}')),
                    ]))
                .toList(),
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            value: _selectedDate,
            items: dates
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDate = v ?? _selectedDate),
          ),
          const SizedBox(height: 12),
          HourlyGraph(
            levels: _hourlyLevels(_selectedDate, energy: true),
            title: '시간별 에너지 레벨',
          ),
          const SizedBox(height: 20),
          HourlyGraph(
            levels: _hourlyLevels(_selectedDate, energy: false),
            title: '시간별 난이도 레벨',
          ),
        ],
      ),
    );
  }

  Widget _buildDetail() {
    final dates = _availableDates();
    final cycles = _getCycles(_selectedDate);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<String>(
            value: _selectedDate,
            items: dates
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDate = v ?? _selectedDate),
          ),
          const SizedBox(height: 12),
          DataTable(
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('목표')),
            ],
            rows: List.generate(cycles.length, (i) {
              return DataRow(cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text(cycles[i].goal)),
              ]);
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('레포트'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Summary'),
            Tab(text: 'Detail'),
          ]),
        ),
        body: TabBarView(
          children: [
            _buildSummary(),
            _buildDetail(),
          ],
        ),
      ),
    );
  }
}
