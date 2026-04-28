import 'package:cloud_firestore/cloud_firestore.dart';

enum WishType { action, thing, movie }
enum WishVisibility { secretUntilMatch, shared }
enum WishStatus { newWish, discuss, planned, done }

class Wish {
  final String id;
  final String userId;
  final String connectionId;
  final String authorUid;
  final WishType type;
  final String content;
  final bool isForNearFuture;
  final bool visibleToPartners;
  final WishVisibility visibility;
  final WishStatus status;
  final List<String> normalizedTags;
  final String? matchedWithWishId;
  final DateTime? matchedAt;
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
    this.connectionId = '',
    this.authorUid = '',
    required this.type,
    required this.content,
    this.isForNearFuture = false,
    this.visibleToPartners = true,
    this.visibility = WishVisibility.secretUntilMatch,
    this.status = WishStatus.newWish,
    this.normalizedTags = const [],
    this.matchedWithWishId,
    this.matchedAt,
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
      'connectionId': connectionId,
      'authorUid': authorUid,
      'type': type.name,
      'content': content,
      'isForNearFuture': isForNearFuture,
      'visibleToPartners': visibleToPartners,
      'visibility': _wishVisibilityToFirestore(visibility),
      'status': _wishStatusToFirestore(status),
      'normalizedTags': normalizedTags,
      'matchedWithWishId': matchedWithWishId,
      'matchedAt': matchedAt != null ? Timestamp.fromDate(matchedAt!) : null,
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
    final matchedAt = (data['matchedAt'] as Timestamp?)?.toDate();
    final sexTypes = data['sexTypes'] as List<dynamic>?;
    final poseIds = data['poseIds'] as List<dynamic>?;
    final toyIds = data['toyIds'] as List<dynamic>?;
    final normalizedTags = data['normalizedTags'] as List<dynamic>?;
    return Wish(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      connectionId: (data['connectionId'] as String?) ?? '',
      authorUid: (data['authorUid'] as String?) ?? (data['userId'] as String?) ?? '',
      type: _parseWishType(data['type'] as String?),
      content: data['content'] as String? ?? '',
      isForNearFuture: data['isForNearFuture'] as bool? ?? false,
      visibleToPartners: data['visibleToPartners'] as bool? ?? true,
      visibility: _parseWishVisibility(data['visibility'] as String?),
      status: _parseWishStatus(data['status'] as String?),
      normalizedTags: normalizedTags?.map((e) => e.toString()).toList() ?? const [],
      matchedWithWishId: data['matchedWithWishId'] as String?,
      matchedAt: matchedAt,
      createdAt: createdAt,
      sexTypes: sexTypes?.map((e) => e.toString()).toList() ?? const [],
      poseIds: poseIds?.map((e) => e.toString()).toList() ?? const [],
      toyIds: toyIds?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Wish copyWith({
    String? id,
    String? userId,
    String? connectionId,
    String? authorUid,
    WishType? type,
    String? content,
    bool? isForNearFuture,
    bool? visibleToPartners,
    WishVisibility? visibility,
    WishStatus? status,
    List<String>? normalizedTags,
    String? matchedWithWishId,
    DateTime? matchedAt,
    DateTime? createdAt,
    List<String>? sexTypes,
    List<String>? poseIds,
    List<String>? toyIds,
  }) {
    return Wish(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      connectionId: connectionId ?? this.connectionId,
      authorUid: authorUid ?? this.authorUid,
      type: type ?? this.type,
      content: content ?? this.content,
      isForNearFuture: isForNearFuture ?? this.isForNearFuture,
      visibleToPartners: visibleToPartners ?? this.visibleToPartners,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      normalizedTags: normalizedTags ?? this.normalizedTags,
      matchedWithWishId: matchedWithWishId ?? this.matchedWithWishId,
      matchedAt: matchedAt ?? this.matchedAt,
      createdAt: createdAt ?? this.createdAt,
      sexTypes: sexTypes ?? this.sexTypes,
      poseIds: poseIds ?? this.poseIds,
      toyIds: toyIds ?? this.toyIds,
    );
  }
}

WishType _parseWishType(String? rawValue) {
  if (rawValue == null) return WishType.action;
  for (final value in WishType.values) {
    if (value.name == rawValue) return value;
  }
  return WishType.action;
}

WishVisibility _parseWishVisibility(String? rawValue) {
  if (rawValue == null) return WishVisibility.secretUntilMatch;
  if (rawValue == 'secret_until_match') return WishVisibility.secretUntilMatch;
  for (final value in WishVisibility.values) {
    if (value.name == rawValue) return value;
  }
  return WishVisibility.secretUntilMatch;
}

WishStatus _parseWishStatus(String? rawValue) {
  if (rawValue == null) return WishStatus.newWish;
  if (rawValue == 'new' || rawValue == 'new_wish') return WishStatus.newWish;
  for (final value in WishStatus.values) {
    if (value.name == rawValue) return value;
  }
  return WishStatus.newWish;
}

String _wishVisibilityToFirestore(WishVisibility value) {
  switch (value) {
    case WishVisibility.secretUntilMatch:
      return 'secret_until_match';
    case WishVisibility.shared:
      return 'shared';
  }
}

String _wishStatusToFirestore(WishStatus value) {
  switch (value) {
    case WishStatus.newWish:
      return 'new';
    case WishStatus.discuss:
      return 'discuss';
    case WishStatus.planned:
      return 'planned';
    case WishStatus.done:
      return 'done';
  }
}
