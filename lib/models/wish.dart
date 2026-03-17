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
  /// Для type == action: типы секса (как в записи о сексе).
  final List<String> sexTypes;
  /// Для type == action: id поз из справочника.
  final List<String> poseIds;
  /// Для type == action: id или названия игрушек.
  final List<String> toyIds;

  const Wish({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    this.isForNearFuture = false,
    this.visibleToPartners = true,
    required this.createdAt,
    this.sexTypes = const [],
    this.poseIds = const [],
    this.toyIds = const [],
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
    final map = <String, dynamic>{
      'userId': userId,
      'type': type.name,
      'content': content,
      'isForNearFuture': isForNearFuture,
      'visibleToPartners': visibleToPartners,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (sexTypes.isNotEmpty) map['sexTypes'] = sexTypes;
    if (poseIds.isNotEmpty) map['poseIds'] = poseIds;
    if (toyIds.isNotEmpty) map['toyIds'] = toyIds;
    return map;
  }

  static Wish fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final sexTypes = data['sexTypes'] as List<dynamic>?;
    final poseIds = data['poseIds'] as List<dynamic>?;
    final toyIds = data['toyIds'] as List<dynamic>?;
    return Wish(
      id: doc.id,
      userId: data['userId'] as String,
      type: WishType.values.byName((data['type'] as String?) ?? 'action'),
      content: data['content'] as String? ?? '',
      isForNearFuture: data['isForNearFuture'] as bool? ?? false,
      visibleToPartners: data['visibleToPartners'] as bool? ?? true,
      createdAt: createdAt,
      sexTypes: sexTypes?.map((e) => e.toString()).toList() ?? const [],
      poseIds: poseIds?.map((e) => e.toString()).toList() ?? const [],
      toyIds: toyIds?.map((e) => e.toString()).toList() ?? const [],
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
    List<String>? sexTypes,
    List<String>? poseIds,
    List<String>? toyIds,
  }) {
    return Wish(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      isForNearFuture: isForNearFuture ?? this.isForNearFuture,
      visibleToPartners: visibleToPartners ?? this.visibleToPartners,
      createdAt: createdAt ?? this.createdAt,
      sexTypes: sexTypes ?? this.sexTypes,
      poseIds: poseIds ?? this.poseIds,
      toyIds: toyIds ?? this.toyIds,
    );
  }
}
