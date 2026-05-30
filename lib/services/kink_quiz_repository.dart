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
  DocumentReference<Map<String, dynamic>> _myResultDoc(String uid) =>
      _results.doc(uid);

  Stream<KinkQuizResult?> watchMyResult() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _myResultDoc(uid)
        .snapshots()
        .map((snap) => snap.exists ? KinkQuizResult.fromFirestore(snap) : null);
  }

  Stream<KinkQuizResult?> watchPartnerResult(String partnerUserId) {
    return _myResultDoc(partnerUserId)
        .snapshots()
        .map((snap) {
          if (!snap.exists) return null;
          final result = KinkQuizResult.fromFirestore(snap);
          if (!result.visibleToPartners) return null;
          return result;
        });
  }

  Future<String?> saveResult({
    String? existingId,
    required Map<String, KinkQuizAnswer> answers,
    required int score,
    required int maxScore,
    required double scoreRatio,
    required KinkQuizLevel level,
    required bool visibleToPartners,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    final docId = existingId ?? uid;
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
      'createdAt': Timestamp.fromDate(now),
    };
    await _results.doc(docId).set(data, SetOptions(merge: true));
    return docId;
  }
}
