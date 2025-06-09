import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pomodoro_desktop/data/model/shop_item.dart';
import 'package:pomodoro_desktop/data/firebase_service.dart';
import 'package:pomodoro_desktop/data/gemini_service.dart';
import 'package:pomodoro_desktop/feature/pomodoro/logic/goal_logic.dart';
import 'package:pomodoro_desktop/feature/pomodoro/logic/timer_logic.dart';
import 'package:pomodoro_desktop/feature/pomodoro/widgets/goal_widget.dart';
import 'package:pomodoro_desktop/feature/pomodoro/widgets/popup_widget.dart';
import 'package:pomodoro_desktop/feature/pomodoro/widgets/shop_widget.dart';
import 'package:pomodoro_desktop/feature/pomodoro/widgets/timer_widget.dart';
import 'package:pomodoro_desktop/feature/pomodoro/widgets/energy_graph_widget.dart';
import 'package:pomodoro_desktop/widgets/custom_dialog.dart';

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
<<<<<<< HEAD
  final TextEditingController _goalController = TextEditingController();
=======
  late final TextEditingController _goalController;
>>>>>>> 53814c7bed75e68c6ded978a104ed9a6df7dfd86

  int _focusMinutes = 25;
  int _breakMinutes = 5;
  int _minutes = 25;
  int _seconds = 0;
  bool _isActive = false;
  bool _isPaused = false;
  bool _isFocusMode = true;
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
  int _currentComplexity = 1;
  bool _showEnergyPopup = false;
  final List<ShopItem> _shopItems = [
    ShopItem(id: 1, name: '집중 물약', cost: 10, description: '다음 집중 사이클 +5분'),
    ShopItem(id: 2, name: '휴식 담요', cost: 5, description: '다음 휴식 사이클 +2분'),
    ShopItem(id: 3, name: '행운의 부적', cost: 15, description: '목표 달성 시 추가 XP 획득'),
  ];

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController();
    _goalController.addListener(_onGoalChanged);
    _initialize();
  }

  void _onGoalChanged() {
    final text = _goalController.text;
    if (text == _currentGoal) return;
    setState(() {
      _currentGoal = text;
      _refinedGoal = '';
      _showGoalSuggestion = false;
    });
    if (_userId.isNotEmpty) {
      _firebaseService.saveUserData(_userId, {'currentGoal': _currentGoal});
    }
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
          _minutes = _focusMinutes;
          _seconds = 0;
          _isLoading = false;
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
        _recordComplexity();
      }
      _timerController.startTimer(
        minutes: _minutes,
        onComplete: () {
          setState(() {
            _isActive = false;
            if (_isFocusMode) {
              _showGoalPopup = true;
            } else {
              _showEnergyPopup = true;
            }
          });
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
      _minutes = _focusMinutes;
      _seconds = 0;
    });
  }

  void _switchMode() {
    final goingToFocus = !_isFocusMode;
    setState(() {
      _isFocusMode = !_isFocusMode;
      _minutes = _isFocusMode ? _focusMinutes : _breakMinutes;
      _seconds = 0;
      _isActive = true;
      _isPaused = false;
      if (goingToFocus) {
        _cycleCount += 1;
      }
    });
    if (goingToFocus) {
      _recordComplexity();
    }
    _startOrPauseTimer();
  }

  void _completeGoal() {
    final earned = GoalLogic.calculateXPEarned(_inventory);
    setState(() {
      _xp += earned;
      _currentGoal = '';
      _showGoalPopup = false;
    });
    _firebaseService
        .saveUserData(_userId, {'xp': _xp, 'currentGoal': _currentGoal});
    _switchMode();
  }

  void _failGoal() {
    setState(() {
      _currentGoal = '';
      _showGoalPopup = false;
    });
    _firebaseService.saveUserData(_userId, {'currentGoal': _currentGoal});
    _switchMode();
  }

  void _recordEnergy(int level) {
    _energyHistory.add(level);
    _firebaseService.saveUserData(_userId, {
      'energyHistory': _energyHistory,
      'cycleCount': _cycleCount,
    });
  }

  void _recordComplexity() {
    _complexityHistory.add(_currentComplexity);
    _firebaseService.saveUserData(_userId, {
      'complexityHistory': _complexityHistory,
      'cycleCount': _cycleCount,
    });
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

  @override
  void dispose() {
    _goalController.dispose();
    _timerController.cancel();
    super.dispose();
  }

  @override
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
                const SizedBox(height: 20),
                TextField(
                  decoration: const InputDecoration(
                    labelText: '오늘의 목표',
                    border: OutlineInputBorder(),
                  ),
                  controller: _goalController,
<<<<<<< HEAD
                  onChanged: (v) {
                    setState(() {
                      _currentGoal = v;
                      _refinedGoal = '';
                      _showGoalSuggestion = false;
                    });
                    _firebaseService
                        .saveUserData(_userId, {'currentGoal': _currentGoal});
                  },
=======
>>>>>>> 53814c7bed75e68c6ded978a104ed9a6df7dfd86
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
                      setState(() => _showEnergyPopup = false);
                      _recordEnergy(level);
                      _switchMode();
                    },
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
                    levels: _energyHistory,
                    onClose: () => setState(() => _showGraph = false),
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
    _goalController.dispose();
    super.dispose();
  }
}
