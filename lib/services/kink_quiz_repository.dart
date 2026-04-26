import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/models/kink_quiz_result.dart';

const String _kinkQuizResultsCol = 'kink_quiz_results';

class KinkQuizRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _results =>
      _firestore.collection(_kinkQuizResultsCol);

  Stream<KinkQuizResult?> watchMyResult() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _results
        .where('userId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return KinkQuizResult.fromFirestore(snap.docs.first);
        });
  }

  Stream<KinkQuizResult?> watchPartnerResult(String partnerUserId) {
    return _results
        .where('userId', isEqualTo: partnerUserId)
        .where('visibleToPartners', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return KinkQuizResult.fromFirestore(snap.docs.first);
        });
  }

  Future<void> saveResult({
    String? existingId,
    required Map<String, KinkQuizAnswer> answers,
    required int score,
    required int maxScore,
    required double scoreRatio,
    required KinkQuizLevel level,
    required bool visibleToPartners,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final now = DateTime.now();
    final data = {
      'userId': uid,
      'answers': answers.map((key, value) => MapEntry(key, value.toMap())),
      'score': score,
      'maxScore': maxScore,
      'scoreRatio': scoreRatio,
      'level': KinkQuizResult.levelToStorage(level),
      'visibleToPartners': visibleToPartners,
      'participants': [uid],
      'updatedAt': Timestamp.fromDate(now),
    };
    if (existingId == null) {
      await _results.add({...data, 'createdAt': Timestamp.fromDate(now)});
    } else {
      await _results.doc(existingId).set(data, SetOptions(merge: true));
    }
  }
}
