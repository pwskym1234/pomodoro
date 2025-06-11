import 'package:flutter/material.dart';
import '../../data/firebase_service.dart';
import '../../data/model/schedule.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  String _userId = '';
  bool _loading = true;
  final TextEditingController _focusController = TextEditingController();
  final TextEditingController _breakController = TextEditingController();
  final TextEditingController _longBreakController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController();

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _startHour = 7;
  static const _endHour = 23;
  static const _scheduleCycleCount = 17;

  static List<String> _generateTimeOptions() {
    final times = <String>['none'];
    for (var h = _startHour; h <= _endHour; h++) {
      for (var m = 0; m < 60; m++) {
        times.add(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
    }
    return times;
  }

  final List<String> _timeOptions = _generateTimeOptions();

  DateTime _parseTime(String t) {
    final parts = t.split(':');
    return DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _adjustFollowingCycles(String day, int startIndex) {
    final cycles = _schedule[day]!;
    if (cycles[startIndex] == 'none') {
      for (int i = startIndex + 1; i < cycles.length; i++) {
        cycles[i] = 'none';
      }
      return;
    }

    final focus = int.tryParse(_focusController.text) ?? 25;
    final brk = int.tryParse(_breakController.text) ?? 5;
    final longBrk = int.tryParse(_longBreakController.text) ?? 15;
    final interval = int.tryParse(_intervalController.text) ?? 4;

    var time = _parseTime(cycles[startIndex]);
    for (int i = startIndex + 1; i < cycles.length; i++) {
      final isLong = (i % interval == 0);
      time = time.add(Duration(minutes: focus + (isLong ? longBrk : brk)));
      cycles[i] = _formatTime(time);
    }
  }

  void _applyDefaultSchedule() {
    for (final day in _dayKeys) {
      final cycles = _schedule[day]!;
      if (cycles[0] == 'none') {
        cycles[0] = '07:00';
      }
      _adjustFollowingCycles(day, 0);
    }
  }

  Map<String, List<String>> _schedule = {
    for (var d in _dayKeys) d: List.filled(_scheduleCycleCount, 'none'),
  };

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
          _focusController.text = '${data['focusMinutes'] ?? 25}';
          _breakController.text = '${data['breakMinutes'] ?? 5}';
          _longBreakController.text = '${data['longBreakMinutes'] ?? 15}';
          _intervalController.text = '${data['longBreakInterval'] ?? 4}';
          if (data['schedule'] != null) {
            final schedJson = Map<String, dynamic>.from(data['schedule']);
            _schedule = {
              for (var e in schedJson.entries)
                e.key: (e.value as List).map((v) => v.toString()).toList()
            };
          }
          _applyDefaultSchedule();
          _loading = false;
        });
      }
    });
  }

  void _save() {
    final focus = int.tryParse(_focusController.text) ?? 25;
    final brk = int.tryParse(_breakController.text) ?? 5;
    final longBrk = int.tryParse(_longBreakController.text) ?? 15;
    final interval = int.tryParse(_intervalController.text) ?? 4;
    _firebaseService.saveUserData(_userId, {
      'focusMinutes': focus,
      'breakMinutes': brk,
      'longBreakMinutes': longBrk,
      'longBreakInterval': interval,
      // Pass Schedule object directly so FirebaseService can serialize it
      'schedule': Schedule(days: _schedule),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장되었습니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _focusController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '집중 시간(분)'),
            ),
            TextField(
              controller: _breakController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '휴식 시간(분)'),
            ),
            TextField(
              controller: _longBreakController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '긴 휴식 시간(분)'),
            ),
            TextField(
              controller: _intervalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '긴 휴식 주기(사이클)'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text('Day')),
                      for (var c = 1; c <= _scheduleCycleCount; c++)
                        DataColumn(label: Text('Cycle $c')),
                    ],
                    rows: _dayKeys.map((day) {
                      final cycles = _schedule[day]!;
                      return DataRow(
                        cells: [
                          DataCell(Text(day.toUpperCase())),
                          for (var i = 0; i < cycles.length; i++)
                            DataCell(
                              DropdownButton<String>(
                                value: cycles[i],
                                items: _timeOptions
                                    .map((t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    cycles[i] = v!;
                                    _adjustFollowingCycles(day, i);
                                  });
                                },
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusController.dispose();
    _breakController.dispose();
    _longBreakController.dispose();
    _intervalController.dispose();
    super.dispose();
  }
}
