import 'package:cloud_firestore/cloud_firestore.dart';

class WishNotification {
  final String id;
  final String wishId;
  final String fromUserId;
  final String toUserId;
  final String type;
  final String wishType;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final List<String> participants;

  const WishNotification({
    required this.id,
    required this.wishId,
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    required this.wishType,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.participants,
  });

  static WishNotification fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return WishNotification(
      id: doc.id,
      wishId: data['wishId'] as String? ?? '',
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      type: data['type'] as String? ?? 'wish_created',
      wishType: data['wishType'] as String? ?? 'action',
      title: data['title'] as String? ?? 'Новое уведомление',
      body: data['body'] as String? ?? '',
      createdAt: createdAt,
      isRead: data['isRead'] as bool? ?? false,
      participants: (data['participants'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
