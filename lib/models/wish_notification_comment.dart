import 'package:cloud_firestore/cloud_firestore.dart';

class WishNotificationComment {
  final String id;
  final String notificationId;
  final String authorUserId;
  final String text;
  final DateTime createdAt;

  const WishNotificationComment({
    required this.id,
    required this.notificationId,
    required this.authorUserId,
    required this.text,
    required this.createdAt,
  });

  static WishNotificationComment fromFirestore(
    String notificationId,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return WishNotificationComment(
      id: doc.id,
      notificationId: notificationId,
      authorUserId: data['authorUserId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}
