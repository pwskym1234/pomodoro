import 'package:flutter/material.dart';
import 'package:pomodoro_desktop/data/model/cycle_record.dart';

class CycleHistoryPopup extends StatefulWidget {
  final Map<String, List<CycleRecord>> history;
  final List<CycleRecord> todayCycles;
  final VoidCallback onClose;

  const CycleHistoryPopup({
    super.key,
    required this.history,
    required this.todayCycles,
    required this.onClose,
  });

  @override
  State<CycleHistoryPopup> createState() => _CycleHistoryPopupState();
}

class _CycleHistoryPopupState extends State<CycleHistoryPopup> {
  late String _selectedDate;
  late Map<String, List<CycleRecord>> _allHistory;

  @override
  void initState() {
    super.initState();
    final today = _todayString();
    _allHistory = {...widget.history, today: widget.todayCycles};
    _selectedDate = today;
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cycles = _allHistory[_selectedDate] ?? [];
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            value: _selectedDate,
            items: _allHistory.keys
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDate = v ?? _selectedDate),
          ),
          IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
        ],
      ),
      content: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('목표')),
            DataColumn(label: Text('난이도')),
            DataColumn(label: Text('에너지')),
          ],
          rows: List.generate(cycles.length, (index) {
            final c = cycles[index];
            return DataRow(cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(c.goal)),
              DataCell(Text('${c.complexity}')),
              DataCell(Text('${c.energy}')),
            ]);
          }),
        ),
      ),
    );
  }
}
