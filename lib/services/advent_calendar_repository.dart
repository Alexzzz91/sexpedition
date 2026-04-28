import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/data/advent_tasks.dart';
import 'package:sexpedition_application_1/models/advent_day.dart';

const String _adventDaysCollection = 'advent_days';

class AdventCalendarRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _days =>
      _firestore.collection(_adventDaysCollection);

  Stream<List<AdventDay>> watchMonth(DateTime month) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return _days
        .where('userId', isEqualTo: uid)
        .where('dateKey', isGreaterThanOrEqualTo: dateKey(start))
        .where('dateKey', isLessThan: dateKey(end))
        .orderBy('dateKey')
        .snapshots()
        .map((snapshot) {
          final days = snapshot.docs.map(AdventDay.fromFirestore).toList();
          days.sort((a, b) => a.date.compareTo(b.date));
          return days;
        });
  }

  Future<AdventDay?> ensureDay(DateTime day) async {
    final uid = _uid;
    if (uid == null) return null;
    final normalized = DateTime(day.year, day.month, day.day);
    final key = dateKey(normalized);
    final existing = await _days
        .where('userId', isEqualTo: uid)
        .where('dateKey', isEqualTo: key)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return AdventDay.fromFirestore(existing.docs.first);
    }

    final ref = _days.doc(_documentId(uid, key));
    final task = _taskFor(uid, key);
    final model = AdventDay(
      id: ref.id,
      userId: uid,
      date: normalized,
      dateKey: key,
      taskId: task.id,
      title: task.title,
      description: task.description,
      category: task.category,
      intensity: task.intensity,
      status: AdventDayStatus.pending,
      createdAt: DateTime.now(),
    );
    await ref.set(model.toMap());
    return model;
  }

  Future<void> respond(String dayId, AdventDayStatus status) async {
    if (status == AdventDayStatus.pending) return;
    await _days.doc(dayId).update({
      'status': AdventDay.statusToStorage(status),
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  static String dateKey(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final dayPart = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$dayPart';
  }

  static String _documentId(String uid, String key) => '${uid}_$key';

  AdventTask _taskFor(String uid, String key) {
    var hash = 0;
    for (final unit in '$uid:$key'.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return adventTasks[hash % adventTasks.length];
  }
}
