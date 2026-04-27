import 'package:cloud_firestore/cloud_firestore.dart';

enum AdventDayStatus { pending, accepted, skipped }

class AdventDay {
  const AdventDay({
    required this.id,
    required this.userId,
    required this.date,
    required this.dateKey,
    required this.taskId,
    required this.title,
    required this.description,
    required this.category,
    required this.intensity,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String userId;
  final DateTime date;
  final String dateKey;
  final String taskId;
  final String title;
  final String description;
  final String category;
  final int intensity;
  final AdventDayStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  bool get isPending => status == AdventDayStatus.pending;
  bool get isAccepted => status == AdventDayStatus.accepted;
  bool get isSkipped => status == AdventDayStatus.skipped;

  static String statusToStorage(AdventDayStatus status) {
    switch (status) {
      case AdventDayStatus.pending:
        return 'pending';
      case AdventDayStatus.accepted:
        return 'accepted';
      case AdventDayStatus.skipped:
        return 'skipped';
    }
  }

  static AdventDayStatus statusFromStorage(String? value) {
    switch (value) {
      case 'accepted':
        return AdventDayStatus.accepted;
      case 'skipped':
        return AdventDayStatus.skipped;
      case 'pending':
      default:
        return AdventDayStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'dateKey': dateKey,
      'taskId': taskId,
      'title': title,
      'description': description,
      'category': category,
      'intensity': intensity,
      'status': statusToStorage(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt == null
          ? null
          : Timestamp.fromDate(respondedAt!),
    };
  }

  static AdventDay fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return AdventDay(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      date: DateTime(date.year, date.month, date.day),
      dateKey: data['dateKey'] as String? ?? '',
      taskId: data['taskId'] as String? ?? '',
      title: data['title'] as String? ?? 'Задание дня',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      intensity: data['intensity'] as int? ?? 1,
      status: statusFromStorage(data['status'] as String?),
      createdAt: createdAt,
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }
}
