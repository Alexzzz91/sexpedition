import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/models/game_session.dart';

const String _gameSessionsCol = 'game_sessions';

class GameStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(_gameSessionsCol);

  Future<String?> startScratchPoseSession({
    required String poseId,
    required String poseLabel,
    bool visibleToPartners = false,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    final now = DateTime.now();
    final ref = await _sessions.add({
      'userId': uid,
      'type': GameSession.typeToStorage(GameSessionType.scratchPose),
      'status': GameSession.statusToStorage(GameSessionStatus.started),
      'createdAt': Timestamp.fromDate(now),
      'completedAt': null,
      'durationMs': null,
      'attemptCount': 1,
      'skipCount': 0,
      'visibleToPartners': visibleToPartners,
      'participants': [uid],
      'poseId': poseId,
      'poseLabel': poseLabel,
      'place': null,
      'dicePose': null,
      'rollHistory': const [],
    });
    return ref.id;
  }

  Future<String?> startDiceSession({
    bool visibleToPartners = false,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    final now = DateTime.now();
    final ref = await _sessions.add({
      'userId': uid,
      'type': GameSession.typeToStorage(GameSessionType.dice),
      'status': GameSession.statusToStorage(GameSessionStatus.started),
      'createdAt': Timestamp.fromDate(now),
      'completedAt': null,
      'durationMs': null,
      'attemptCount': 0,
      'skipCount': 0,
      'visibleToPartners': visibleToPartners,
      'participants': [uid],
      'poseId': null,
      'poseLabel': null,
      'place': null,
      'dicePose': null,
      'rollHistory': const [],
    });
    return ref.id;
  }

  Future<void> recordDiceRoll({
    required String sessionId,
    required String place,
    required String dicePose,
  }) async {
    await _sessions.doc(sessionId).update({
      'place': place,
      'dicePose': dicePose,
      'attemptCount': FieldValue.increment(1),
      'rollHistory': FieldValue.arrayUnion([
        {
          'place': place,
          'dicePose': dicePose,
          'rolledAt': Timestamp.fromDate(DateTime.now()),
        },
      ]),
    });
  }

  Future<void> completeScratchPoseSession({
    required String sessionId,
    required GameSessionStatus status,
    required DateTime startedAt,
  }) async {
    await _completeSession(
      sessionId: sessionId,
      status: status,
      startedAt: startedAt,
    );
  }

  Future<void> completeDiceSession({
    required String sessionId,
    required GameSessionStatus status,
    required DateTime startedAt,
  }) async {
    await _completeSession(
      sessionId: sessionId,
      status: status,
      startedAt: startedAt,
    );
  }

  Future<void> _completeSession({
    required String sessionId,
    required GameSessionStatus status,
    required DateTime startedAt,
  }) async {
    final completedAt = DateTime.now();
    await _sessions.doc(sessionId).update({
      'status': GameSession.statusToStorage(status),
      'completedAt': Timestamp.fromDate(completedAt),
      'durationMs': completedAt.difference(startedAt).inMilliseconds,
      if (status == GameSessionStatus.skipped)
        'skipCount': FieldValue.increment(1),
    });
  }

  Stream<List<GameSession>> watchMyGameSessions() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _sessions
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map(GameSession.fromFirestore).toList();
    });
  }
}

