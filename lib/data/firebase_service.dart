import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pomodoro_desktop/data/model/shop_item.dart';
import 'package:pomodoro_desktop/data/model/day_record.dart';
import 'package:pomodoro_desktop/data/model/cycle_record.dart';
import 'package:pomodoro_desktop/data/model/schedule.dart';
import '../firebase_options.dart';

class FirebaseService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  String? userId;

  Future<void> initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
  }

  Future<String?> authenticateUser() async {
    try {
      final user = auth.currentUser;
      if (user != null) return user.uid;

      final credential = await auth.signInAnonymously();
      userId = credential.user?.uid;
      return userId;
    } catch (e) {
      rethrow;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDataStream(
      String userId) {
    return db
        .collection('artifacts')
        .doc('default-app-id')
        .collection('users')
        .doc(userId)
        .collection('pomodoroData')
        .doc('userState')
        .snapshots();
  }

  Future<void> saveUserData(
      String userId, Map<String, dynamic> dataToSave) async {
    if (dataToSave.containsKey('inventory')) {
      dataToSave['inventory'] = (dataToSave['inventory'] as List<ShopItem>)
          .map((item) => item.toJson())
          .toList();
    }
    if (dataToSave.containsKey('todayCycles')) {
      dataToSave['todayCycles'] =
          (dataToSave['todayCycles'] as List<CycleRecord>)
              .map((e) => e.toJson())
              .toList();
    }
    if (dataToSave.containsKey('history')) {
      dataToSave['history'] = (dataToSave['history'] as List<DayRecord>)
          .map((e) => e.toJson())
          .toList();
    }
    if (dataToSave.containsKey('schedule')) {
      dataToSave['schedule'] =
          (dataToSave['schedule'] as Schedule).toJson();
    }

    await db
        .collection('artifacts')
        .doc('default-app-id')
        .collection('users')
        .doc(userId)
        .collection('pomodoroData')
        .doc('userState')
        .set(dataToSave, SetOptions(merge: true));
  }

  Future<void> appendCycleData({
    required String userId,
    required int energy,
    required int complexity,
    required int cycleCount,
    required List<CycleRecord> todayCycles,
  }) async {
    await db
        .collection('artifacts')
        .doc('default-app-id')
        .collection('users')
        .doc(userId)
        .collection('pomodoroData')
        .doc('userState')
        .set({
          'energyHistory': FieldValue.arrayUnion([energy]),
          'complexityHistory': FieldValue.arrayUnion([complexity]),
          'cycleCount': cycleCount,
          'todayCycles': todayCycles.map((e) => e.toJson()).toList(),
        }, SetOptions(merge: true));
  }

  Future<void> createInitialUserDataIfNotExists(String userId) async {
    final docRef = db
        .collection('artifacts')
        .doc('default-app-id')
        .collection('users')
        .doc(userId)
        .collection('pomodoroData')
        .doc('userState');

    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'xp': 0,
        'level': 1,
        'coins': 0,
        'currentGoal': '',
        'focusMinutes': 25,
        'breakMinutes': 5,
        'longBreakMinutes': 15,
        'longBreakInterval': 4,
        'inventory': [],
        'cycleCount': 0,
        'energyHistory': [],
        'complexityHistory': [],
        'currentComplexity': 1,
        'todayCycles': [],
        'history': [],
        'schedule': Schedule.empty(
          const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
          17,
        ).toJson(),
      });
      print('✅ 사용자 초기 데이터 생성 완료');
    }
  }
}
