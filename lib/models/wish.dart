import 'package:cloud_firestore/cloud_firestore.dart';

enum WishType { action, thing, movie }

class Wish {
  final String id;
  final String userId;
  final WishType type;
  final String content;
  final bool isForNearFuture;
  final bool visibleToPartners;
  final DateTime createdAt;

  const Wish({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    this.isForNearFuture = false,
    this.visibleToPartners = true,
    required this.createdAt,
  });

  String get typeLabel {
    switch (type) {
      case WishType.action:
        return 'Действие';
      case WishType.thing:
        return 'Вещь';
      case WishType.movie:
        return 'Фильм';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'content': content,
      'isForNearFuture': isForNearFuture,
      'visibleToPartners': visibleToPartners,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static Wish fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Wish(
      id: doc.id,
      userId: data['userId'] as String,
      type: WishType.values.byName((data['type'] as String?) ?? 'action'),
      content: data['content'] as String? ?? '',
      isForNearFuture: data['isForNearFuture'] as bool? ?? false,
      visibleToPartners: data['visibleToPartners'] as bool? ?? true,
      createdAt: createdAt,
    );
  }

  Wish copyWith({
    String? id,
    String? userId,
    WishType? type,
    String? content,
    bool? isForNearFuture,
    bool? visibleToPartners,
    DateTime? createdAt,
  }) {
    return Wish(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      isForNearFuture: isForNearFuture ?? this.isForNearFuture,
      visibleToPartners: visibleToPartners ?? this.visibleToPartners,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
