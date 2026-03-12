import 'package:cloud_firestore/cloud_firestore.dart';

enum ConnectionStatus { pending, accepted }

/// Запрос/связь между двумя пользователями.
class PartnerConnection {
  final String id;
  final String fromUserId;
  final String toUserId;
  final ConnectionStatus status;
  final DateTime createdAt;

  const PartnerConnection({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  String get otherUserId => fromUserId; // для входящих запросов "другой" — отправитель
  String partnerUserId(String myUserId) => fromUserId == myUserId ? toUserId : fromUserId;

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static PartnerConnection fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return PartnerConnection(
      id: doc.id,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      status: ConnectionStatus.values.byName((data['status'] as String?) ?? 'pending'),
      createdAt: createdAt,
    );
  }
}
