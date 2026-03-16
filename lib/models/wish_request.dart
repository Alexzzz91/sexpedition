import 'package:cloud_firestore/cloud_firestore.dart';

enum WishRequestStatus { pending, answered }

class WishRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final DateTime createdAt;
  final WishRequestStatus status;
  final DateTime? answeredAt;

  const WishRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.createdAt,
    required this.status,
    this.answeredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'answeredAt': answeredAt != null ? Timestamp.fromDate(answeredAt!) : null,
    };
  }

  static WishRequest fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final answeredAt = (data['answeredAt'] as Timestamp?)?.toDate();
    return WishRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      createdAt: createdAt,
      status: WishRequestStatus.values.byName((data['status'] as String?) ?? 'pending'),
      answeredAt: answeredAt,
    );
  }
}
