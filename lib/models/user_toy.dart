import 'package:cloud_firestore/cloud_firestore.dart';

/// Игрушка пользователя (справочник для записей о сексе).
class UserToy {
  final String id;
  final String userId;
  final String name;

  const UserToy({
    required this.id,
    required this.userId,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
    };
  }

  static UserToy fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserToy(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String? ?? '',
    );
  }

  UserToy copyWith({String? id, String? userId, String? name}) {
    return UserToy(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
    );
  }
}
