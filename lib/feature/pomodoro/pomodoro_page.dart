import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pomodoro_desktop/data/model/shop_item.dart';
import 'package:pomodoro_desktop/data/firebase_service.dart';
import 'package:pomodoro_desktop/data/gemini_service.dart';
import 'package:pomodoro_desktop/data/model/schedule.dart';
import 'package:pomodoro_desktop/feature/pomodoro/logic/goal_logic.dart';
import 'package:pomodoro_desktop/feature/pomodoro/logic/timer_logic.dart';
import 'package:pomodoro_desktop/feature/pomodoro/widgets/goal_widget.dart';
import 'package:pomodoro_desktop/feature/pomodoro/widgets/popup_widget.dart';
import 'package:pomodoro_desktop/feature/pomodoro/widgets/shop_widget.dart';
import 'package:pomodoro_desktop/feature/pomodoro/widgets/timer_widget.dart';
import 'package:pomodoro_desktop/feature/pomodoro/widgets/energy_graph_widget.dart';
import 'package:pomodoro_desktop/feature/pomodoro/widgets/cycle_history_widget.dart';
import 'package:pomodoro_desktop/data/model/cycle_record.dart';
import 'package:pomodoro_desktop/data/model/day_record.dart';
import 'package:pomodoro_desktop/widgets/custom_dialog.dart';
import '../report/report_page.dart';
import '../settings/settings_page.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final GeminiService _geminiService =
      GeminiService("YOUR_GEMINI_API_KEY_HERE");
  final TimerController _timerController = TimerController();
  final TextEditingController _goalController = TextEditingController();

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _scheduleCycleCount = 17;
  Map<String, List<String>> _schedule =
      Schedule.empty(_dayKeys, _scheduleCycleCount).days;

  int _focusMinutes = 25;
  int _breakMinutes = 5;
  int _longBreakMinutes = 15;
  int _longBreakInterval = 4;
  int _minutes = 25;
  int _seconds = 0;
  bool _isActive = false;
  bool _isPaused = false;
  bool _isFocusMode = true;
  bool _isLongBreak = false;
  bool _isLoading = true;

  String _userId = '';
  int _xp = 0;
  int _level = 1;
  int _coins = 0;
  String _currentGoal = '';
  String _refinedGoal = '';
  bool _showGoalPopup = false;
  bool _showGoalSuggestion = false;
  bool _isGoalRefining = false;
  bool _isGeneratingBreakIdea = false;
  bool _showShop = false;
  bool _showGraph = false;
  List<ShopItem> _inventory = [];
  int _cycleCount = 0;
  List<int> _energyHistory = [];
  List<int> _complexityHistory = [];
  Timer? _goalSaveDebounce;
  int _currentComplexity = 1;
  bool _showEnergyPopup = false;
  final TextEditingController _startTimeController = TextEditingController();
  String _currentStartTime = '';
  List<CycleRecord> _todayCycles = [];
  Map<String, List<CycleRecord>> _history = {};
  bool _showHistory = false;
  String _lastCycleGoal = '';
  final List<ShopItem> _shopItems = [
    ShopItem(id: 1, name: '집중 물약', cost: 10, description: '다음 집중 사이클 +5분'),
    ShopItem(id: 2, name: '휴식 담요', cost: 5, description: '다음 휴식 사이클 +2분'),
    ShopItem(id: 3, name: '행운의 부적', cost: 15, description: '목표 달성 시 추가 XP 획득'),
  ];

  int _selectedDayIndex = DateTime.now().weekday - 1;

  String _currentDayKey() => _dayKeys[_selectedDayIndex];

  String _getScheduledStartTime() {
    final list = _schedule[_currentDayKey()];
    final index = max(_cycleCount - 1, 0);
    if (list != null && index >= 0 && index < list.length) {
      final t = list[index];
      if (t != 'none') return t;
    }
    return _formatTime(DateTime.now());
  }

  void _updateStartTimeFromSchedule() {
    final time = _getScheduledStartTime();
    _startTimeController.text = time;
    _currentStartTime = time;
  }

  void _saveCurrentStartTime(String time) {
    final key = _currentDayKey();
    final list = _schedule[key];
    final index = _cycleCount - 1;
    if (list != null && index >= 0 && index < list.length) {
      list[index] = time.isEmpty ? 'none' : time;
      _firebaseService.saveUserData(
        _userId,
        {'schedule': Schedule(days: _schedule)},
      );
    }
  }

  void _saveGoalAndComplexity() {
    _firebaseService.saveUserData(_userId, {
      'currentGoal': _currentGoal,
      'currentComplexity': _currentComplexity,
    });
    showCustomMessageBox(context, '저장되었습니다');
  }

  void _onGoalChanged(String text) {
    if (text == _currentGoal) return;
    setState(() {
      _currentGoal = text;
      _refinedGoal = '';
      _showGoalSuggestion = false;
    });
    if (_userId.isEmpty) return;
    _goalSaveDebounce?.cancel();
    _goalSaveDebounce = Timer(const Duration(milliseconds: 500), () {
      _firebaseService.saveUserData(_userId, {'currentGoal': _currentGoal});
    });
  }

  @override
  void initState() {
    super.initState();
    // Listen to goal changes via onChanged callback instead of a controller
    // listener to avoid duplicate updates.
    _startTimeController.text = _formatTime(DateTime.now());
    _currentStartTime = _startTimeController.text;
    _initialize();
  }

  Future<void> _initialize() async {
    await _firebaseService.initializeFirebase();
    _userId = (await _firebaseService.authenticateUser()) ?? '';
    await _firebaseService.createInitialUserDataIfNotExists(_userId);
    _firebaseService.getUserDataStream(_userId).listen((snapshot) {
      // print(
      //     '📡 Firestore Snapshot received: exists=${snapshot.exists}, hasData=${snapshot.data() != null}');
      final data = snapshot.data();
      if (data != null) {
        setState(() {
          _xp = data['xp'] ?? 0;
          _level = data['level'] ?? 1;
          _coins = data['coins'] ?? 0;
          _currentGoal = data['currentGoal'] ?? '';
          _goalController.text = _currentGoal;
          _focusMinutes = data['focusMinutes'] ?? 25;
          _breakMinutes = data['breakMinutes'] ?? 5;
          _longBreakMinutes = data['longBreakMinutes'] ?? 15;
          _longBreakInterval = data['longBreakInterval'] ?? 4;
          _inventory = (data['inventory'] as List?)
                  ?.map((e) => ShopItem.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              [];
          _cycleCount = data['cycleCount'] ?? 0;
          _energyHistory =
              (data['energyHistory'] as List?)?.map((e) => e as int).toList() ??
                  [];
          _complexityHistory = (data['complexityHistory'] as List?)
                  ?.map((e) => e as int)
                  .toList() ??
              [];
          _currentComplexity = data['currentComplexity'] ?? 1;
          _todayCycles = (data['todayCycles'] as List?)
                  ?.map(
                      (e) => CycleRecord.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              [];
          if (data['schedule'] != null) {
            final schedJson = Map<String, dynamic>.from(data['schedule']);
            _schedule = {
              for (var e in schedJson.entries)
                e.key: (e.value as List).map((v) => v.toString()).toList()
            };
          }
          _history = {};
          (data['history'] as List?)?.forEach((day) {
            final record = DayRecord.fromJson(Map<String, dynamic>.from(day));
            _history[record.date] = record.cycles;
          });
          _minutes = _focusMinutes;
          _seconds = 0;
          _isLoading = false;
          _updateStartTimeFromSchedule();
        });
        if (_goalController.text != _currentGoal) {
          _goalController.text = _currentGoal;
        }
      } else {
        print('⚠️ 사용자 문서가 존재하지 않음. 초기 데이터가 필요함.');
        // 초기 문서를 만들어주는 코드도 고려 가능
        setState(() => _isLoading = false); // 일단 UI 진입하게 함
      }
    });
  }

  void _startOrPauseTimer() {
    if (_isActive) {
      setState(() => _isPaused = !_isPaused);
      _isPaused ? _timerController.pause() : _timerController.resume();
    } else {
      setState(() {
        _isActive = true;
        _isPaused = false;
      });
      if (_cycleCount == 0 && _isFocusMode) {
        _cycleCount = 1;
        _updateStartTimeFromSchedule();
        _isLongBreak = false;
        if (_userId.isNotEmpty) {
          _firebaseService.saveUserData(_userId, {'cycleCount': _cycleCount});
        }
      }
      _timerController.startTimer(
        minutes: _minutes,
        onComplete: () {
          setState(() {
            _isActive = false;
          });
          if (_isFocusMode) {
            setState(() => _showGoalPopup = true);
          } else {
            _switchMode();
          }
        },
        onTick: (m, s) {
          setState(() {
            _minutes = m;
            _seconds = s;
          });
        },
      );
    }
  }

  void _resetTimer() {
    _timerController.cancel();
    setState(() {
      _isActive = false;
      _isPaused = false;
      _isFocusMode = true;
      _isLongBreak = false;
      _minutes = _focusMinutes;
      _seconds = 0;
      _startTimeController.text = _formatTime(DateTime.now());
      _currentStartTime = _startTimeController.text;
    });
  }

  void _resetDailyCycles() {
    final date = DateTime.now();
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_todayCycles.isNotEmpty) {
      _history[key] = List<CycleRecord>.from(_todayCycles);
    }
    _todayCycles.clear();
    _cycleCount = 0;
    _energyHistory.clear();
    _complexityHistory.clear();
    _isLongBreak = false;
    _firebaseService.saveUserData(_userId, {
      'cycleCount': _cycleCount,
      'energyHistory': _energyHistory,
      'complexityHistory': _complexityHistory,
      'todayCycles': _todayCycles,
      'history': _history.entries
          .map((e) => DayRecord(date: e.key, cycles: e.value))
          .toList(),
    });
    setState(() {});
  }

  void _switchMode() {
    final goingToFocus = !_isFocusMode;
    setState(() {
      _isFocusMode = !_isFocusMode;
      if (_isFocusMode) {
        _minutes = _focusMinutes;
        _isLongBreak = false;
      } else {
        _isLongBreak = _cycleCount % _longBreakInterval == 0 && _cycleCount > 0;
        _minutes = _isLongBreak ? _longBreakMinutes : _breakMinutes;
      }
      _seconds = 0;
      _isActive = false;
      _isPaused = false;
      if (goingToFocus) {
        _cycleCount += 1;
        if (_userId.isNotEmpty) {
          _firebaseService.saveUserData(_userId, {'cycleCount': _cycleCount});
        }
      }
      if (goingToFocus) {
        _updateStartTimeFromSchedule();
      }
    });
  }

  void _completeGoal() {
    final earned = GoalLogic.calculateXPEarned(_inventory);
    setState(() {
      _xp += earned;
      _lastCycleGoal = _currentGoal;
      _currentGoal = '';
      _showGoalPopup = false;
      _showEnergyPopup = true;
    });
    _firebaseService
        .saveUserData(_userId, {'xp': _xp, 'currentGoal': _currentGoal});
  }

  void _failGoal() {
    setState(() {
      _lastCycleGoal = _currentGoal;
      _currentGoal = '';
      _showGoalPopup = false;
      _showEnergyPopup = true;
    });
    _firebaseService.saveUserData(_userId, {'currentGoal': _currentGoal});
  }

  int? _pendingEnergy;
  bool _showComplexityPopup = false;

  void _recordEnergy(int level) {
    setState(() {
      _showEnergyPopup = false;
      _pendingEnergy = level;
      _showComplexityPopup = true;
    });
  }

  void _recordCycle(int energy, int complexity) {
    final record = CycleRecord(
      goal: _lastCycleGoal,
      complexity: complexity,
      energy: energy,
      startTime: _currentStartTime,
    );
    _todayCycles.add(record);
    _lastCycleGoal = '';
  }

  void _recordComplexity(int level) {
    final energy = _pendingEnergy ?? 1;
    setState(() {
      _currentComplexity = level;
      // Create new list instances so widgets depending on these values
      // receive updated references and repaint correctly.
      _complexityHistory = List<int>.from(_complexityHistory)..add(level);
      _energyHistory = List<int>.from(_energyHistory)..add(energy);
      debugPrint('_energyHistory: $_energyHistory');
      // Print graph coordinates each time energy is recorded for easier
      // debugging without requiring the graph to be visible.
      EnergyPainter.printEnergyPoints(
        _energyHistory,
        const Size(330, 170),
      );
      _pendingEnergy = null;
      _showComplexityPopup = false;
    });

    _recordCycle(energy, level);
    _firebaseService.appendCycleData(
      userId: _userId,
      energy: energy,
      complexity: level,
      cycleCount: _cycleCount,
      todayCycles: _todayCycles,
    );
    _switchMode();
  }

  void _buyItem(ShopItem item) {
    if (!GoalLogic.canAfford(item, _coins)) {
      showCustomMessageBox(context, '코인이 부족합니다!');
      return;
    }
    setState(() {
      _coins -= item.cost;
      _inventory.add(item);
    });
    GoalLogic.applyItemEffects(
      item: item,
      onFocusBoost: (min) => setState(() => _focusMinutes += min),
      onBreakBoost: (min) => setState(() => _breakMinutes += min),
    );
    _firebaseService.saveUserData(_userId, {
      'coins': _coins,
      'inventory': _inventory,
      'focusMinutes': _focusMinutes,
      'breakMinutes': _breakMinutes,
    });
  }

  Future<void> _refineGoal() async {
    setState(() => _isGoalRefining = true);
    try {
      final refined = await _geminiService.refineGoal(_currentGoal);
      setState(() {
        _refinedGoal = refined ?? '';
        _showGoalSuggestion = true;
      });
    } catch (e) {
      showCustomMessageBox(context, '목표 구체화 실패: $e');
    } finally {
      setState(() => _isGoalRefining = false);
    }
  }

  Future<void> _getBreakIdea() async {
    setState(() => _isGeneratingBreakIdea = true);
    try {
      final idea = await _geminiService.getBreakIdea();
      if (idea != null) showCustomMessageBox(context, "💡 휴식 아이디어: $idea");
    } catch (e) {
      showCustomMessageBox(context, '휴식 아이디어 오류: $e');
    } finally {
      setState(() => _isGeneratingBreakIdea = false);
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF673AB7),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TimerDisplay(
                  isFocusMode: _isFocusMode,
                  isLongBreak: _isLongBreak,
                  minutes: _minutes,
                  seconds: _seconds,
                  isActive: _isActive,
                  isPaused: _isPaused,
                  onStartPauseResume: _startOrPauseTimer,
                  onReset: _resetTimer,
                ),
                const SizedBox(height: 8),
                Text('사이클: $_cycleCount',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _resetDailyCycles,
                  child: const Text('사이클 초기화'),
                ),
                const SizedBox(height: 20),
                DropdownButton<int>(
                  value: _selectedDayIndex,
                  items: List.generate(
                    _dayKeys.length,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(_dayLabels[i]),
                    ),
                  ),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedDayIndex = v);
                    _updateStartTimeFromSchedule();
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _startTimeController,
                  decoration: const InputDecoration(
                    labelText: '시작 시각(HH:mm)',
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: const InputDecoration(
                    labelText: '오늘의 목표',
                    border: OutlineInputBorder(),
                  ),
                  controller: _goalController,
                  onChanged: _onGoalChanged,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('복잡도:'),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: _currentComplexity,
                      items: const [1, 2, 3]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('$e'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _currentComplexity = v ?? 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isGoalRefining ? null : _refineGoal,
                  child: Text(_isGoalRefining ? '구체화 중...' : '✨ 목표 구체화'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _saveGoalAndComplexity,
                  child: const Text('저장'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => setState(() => _showShop = true),
                  child: const Text('상점 열기'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() => _showGraph = true),
                  child: const Text('에너지 그래프'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() => _showHistory = true),
                  child: const Text('기록 보기'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                  child: const Text('설정 페이지'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportPage()),
                  ),
                  child: const Text('레포트 페이지'),
                ),
                if (_inventory.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text('내 아이템:'),
                      ..._inventory.map((item) => Text('• ${item.name}')),
                    ],
                  ),
                if (_showGoalPopup)
                  GoalAchievedPopup(
                    goalText: _currentGoal,
                    onConfirm: _completeGoal,
                    onCancel: _failGoal,
                  ),
                if (_showEnergyPopup)
                  EnergyLevelPopup(
                    onSelect: (level) {
                      _recordEnergy(level);
                    },
                  ),
                if (_showComplexityPopup)
                  ComplexityLevelPopup(
                    onSelect: (level) => _recordComplexity(level),
                  ),
                if (_showGoalSuggestion && _refinedGoal.isNotEmpty)
                  GoalSuggestionPopup(
                    originalGoal: _currentGoal,
                    refinedGoal: _refinedGoal,
                    onAccept: () {
                      setState(() {
                        _currentGoal = _refinedGoal;
                        _showGoalSuggestion = false;
                      });
                      _firebaseService
                          .saveUserData(_userId, {'currentGoal': _currentGoal});
                    },
                    onReject: () => setState(() => _showGoalSuggestion = false),
                  ),
                if (_showShop)
                  ShopModal(
                    shopItems: _shopItems,
                    onBuy: _buyItem,
                    onClose: () => setState(() => _showShop = false),
                  ),
                if (_showGraph)
                  EnergyGraph(
                    key: ValueKey(_energyHistory.length),
                    levels: _energyHistory,
                    onClose: () => setState(() => _showGraph = false),
                  ),
                if (_showHistory)
                  CycleHistoryPopup(
                    history: _history,
                    todayCycles: _todayCycles,
                    onClose: () => setState(() => _showHistory = false),
                  ),
                if (!_isFocusMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: _isGeneratingBreakIdea ? null : _getBreakIdea,
                      child: Text(_isGeneratingBreakIdea
                          ? '아이디어 생성 중...'
                          : '💡 휴식 아이디어'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _goalSaveDebounce?.cancel();
    _goalController.dispose();
    _startTimeController.dispose();
    _timerController.cancel();
    super.dispose();
  }
}
