import 'package:cloud_firestore/cloud_firestore.dart';

enum KinkQuizLevel { low, medium, high, max }

class KinkQuizAnswer {
  const KinkQuizAnswer({this.tried = false, this.loved = false});

  final bool tried;
  final bool loved;

  Map<String, dynamic> toMap() {
    return {'tried': tried, 'loved': loved};
  }

  static KinkQuizAnswer fromMap(Map<String, dynamic>? map) {
    return KinkQuizAnswer(
      tried: map?['tried'] as bool? ?? false,
      loved: map?['loved'] as bool? ?? false,
    );
  }
}

class KinkQuizResult {
  const KinkQuizResult({
    required this.id,
    required this.userId,
    required this.answers,
    required this.score,
    required this.maxScore,
    required this.scoreRatio,
    required this.level,
    required this.visibleToPartners,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final Map<String, KinkQuizAnswer> answers;
  final int score;
  final int maxScore;
  final double scoreRatio;
  final KinkQuizLevel level;
  final bool visibleToPartners;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime updatedAt;

  static String levelToStorage(KinkQuizLevel level) {
    switch (level) {
      case KinkQuizLevel.low:
        return 'low';
      case KinkQuizLevel.medium:
        return 'medium';
      case KinkQuizLevel.high:
        return 'high';
      case KinkQuizLevel.max:
        return 'max';
    }
  }

  static KinkQuizLevel levelFromStorage(String? value) {
    switch (value) {
      case 'medium':
        return KinkQuizLevel.medium;
      case 'high':
        return KinkQuizLevel.high;
      case 'max':
        return KinkQuizLevel.max;
      case 'low':
      default:
        return KinkQuizLevel.low;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'answers': answers.map((key, value) => MapEntry(key, value.toMap())),
      'score': score,
      'maxScore': maxScore,
      'scoreRatio': scoreRatio,
      'level': levelToStorage(level),
      'visibleToPartners': visibleToPartners,
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static KinkQuizResult fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawAnswers = data['answers'] as Map<String, dynamic>? ?? {};
    final rawParticipants = data['participants'] as List<dynamic>?;
    return KinkQuizResult(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      answers: rawAnswers.map((key, value) {
        return MapEntry(
          key,
          KinkQuizAnswer.fromMap(value as Map<String, dynamic>?),
        );
      }),
      score: data['score'] as int? ?? 0,
      maxScore: data['maxScore'] as int? ?? 0,
      scoreRatio: (data['scoreRatio'] as num?)?.toDouble() ?? 0,
      level: levelFromStorage(data['level'] as String?),
      visibleToPartners: data['visibleToPartners'] as bool? ?? false,
      participants:
          rawParticipants?.map((value) => value.toString()).toList() ??
          const [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
