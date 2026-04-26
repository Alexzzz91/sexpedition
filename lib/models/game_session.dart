import 'package:cloud_firestore/cloud_firestore.dart';

enum GameSessionType { scratchPose, dice }

enum GameSessionStatus { started, accepted, skipped }

class GameRoll {
  const GameRoll({
    required this.place,
    required this.dicePose,
    required this.rolledAt,
  });

  final String place;
  final String dicePose;
  final DateTime rolledAt;

  Map<String, dynamic> toMap() {
    return {
      'place': place,
      'dicePose': dicePose,
      'rolledAt': Timestamp.fromDate(rolledAt),
    };
  }

  static GameRoll fromMap(Map<String, dynamic> map) {
    return GameRoll(
      place: map['place'] as String? ?? '',
      dicePose: map['dicePose'] as String? ?? '',
      rolledAt: (map['rolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class GameSession {
  const GameSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.durationMs,
    this.attemptCount = 0,
    this.skipCount = 0,
    this.visibleToPartners = false,
    this.participants = const [],
    this.poseId,
    this.poseLabel,
    this.place,
    this.dicePose,
    this.rollHistory = const [],
  });

  final String id;
  final String userId;
  final GameSessionType type;
  final GameSessionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? durationMs;
  final int attemptCount;
  final int skipCount;
  final bool visibleToPartners;
  final List<String> participants;
  final String? poseId;
  final String? poseLabel;
  final String? place;
  final String? dicePose;
  final List<GameRoll> rollHistory;

  static String typeToStorage(GameSessionType type) {
    switch (type) {
      case GameSessionType.scratchPose:
        return 'scratch_pose';
      case GameSessionType.dice:
        return 'dice';
    }
  }

  static GameSessionType typeFromStorage(String? value) {
    switch (value) {
      case 'dice':
        return GameSessionType.dice;
      case 'scratch_pose':
      default:
        return GameSessionType.scratchPose;
    }
  }

  static String statusToStorage(GameSessionStatus status) {
    switch (status) {
      case GameSessionStatus.started:
        return 'started';
      case GameSessionStatus.accepted:
        return 'accepted';
      case GameSessionStatus.skipped:
        return 'skipped';
    }
  }

  static GameSessionStatus statusFromStorage(String? value) {
    switch (value) {
      case 'accepted':
        return GameSessionStatus.accepted;
      case 'skipped':
        return GameSessionStatus.skipped;
      case 'started':
      default:
        return GameSessionStatus.started;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': typeToStorage(type),
      'status': statusToStorage(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'durationMs': durationMs,
      'attemptCount': attemptCount,
      'skipCount': skipCount,
      'visibleToPartners': visibleToPartners,
      'participants': participants,
      'poseId': poseId,
      'poseLabel': poseLabel,
      'place': place,
      'dicePose': dicePose,
      'rollHistory': rollHistory.map((roll) => roll.toMap()).toList(),
    };
  }

  static GameSession fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawParticipants = data['participants'] as List<dynamic>?;
    final rawHistory = data['rollHistory'] as List<dynamic>?;
    return GameSession(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: typeFromStorage(data['type'] as String?),
      status: statusFromStorage(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      durationMs: data['durationMs'] as int?,
      attemptCount: data['attemptCount'] as int? ?? 0,
      skipCount: data['skipCount'] as int? ?? 0,
      visibleToPartners: data['visibleToPartners'] as bool? ?? false,
      participants:
          rawParticipants?.map((value) => value.toString()).toList() ??
              const [],
      poseId: data['poseId'] as String?,
      poseLabel: data['poseLabel'] as String?,
      place: data['place'] as String?,
      dicePose: data['dicePose'] as String?,
      rollHistory: rawHistory
              ?.whereType<Map<String, dynamic>>()
              .map(GameRoll.fromMap)
              .toList() ??
          const [],
    );
  }
}

