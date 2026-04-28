import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sexpedition_application_1/models/wish.dart';
import 'package:sexpedition_application_1/models/wish_request.dart';
import 'package:sexpedition_application_1/services/analytics_service.dart';

const String _wishesCol = 'wishes';
const String _wishRequestsCol = 'wish_requests';
const String _connectionsCol = 'connections';

class WishesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _wishes => _firestore.collection(_wishesCol);
  CollectionReference<Map<String, dynamic>> get _wishRequests => _firestore.collection(_wishRequestsCol);
  CollectionReference<Map<String, dynamic>> get _connections =>
      _firestore.collection(_connectionsCol);

  Stream<List<Wish>> watchMyWishes() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _wishes
        .where('userId', isEqualTo: uid)
        .snapshots()
        .handleError((error, stackTrace) {
          _logFirestoreIndexLink(
            error,
            streamName: 'watchMyWishes',
          );
        })
        .map((s) {
          final list = s.docs.map((d) => Wish.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> addWish(Wish wish) async {
    final uid = _uid;
    if (uid == null) return;
    await _wishes.add(wish.copyWith(userId: uid).toMap());
  }

  Future<void> createSecretWish(Wish wish) async {
    final uid = _uid;
    if (uid == null) return;

    final normalizedTags = _normalizeTags(wish.normalizedTags);
    await _wishes.add(
      wish
          .copyWith(
            userId: uid,
            authorUid: uid,
            visibility: WishVisibility.secretUntilMatch,
            status: WishStatus.newWish,
            normalizedTags: normalizedTags,
            matchedWithWishId: null,
            matchedAt: null,
          )
          .toMap(),
    );
    await _analytics.logEvent(
      'wish_created_secret',
      parameters: {
        'has_connection_id': wish.connectionId.isNotEmpty,
        'tags_count': normalizedTags.length,
      },
    );
  }

  Future<void> updateWish(Wish wish) async {
    await _wishes.doc(wish.id).update(wish.toMap());
  }

  Future<void> deleteWish(String wishId) async {
    await _wishes.doc(wishId).delete();
  }

  Stream<List<Wish>> watchOwnUnmatchedWishes(String connectionId, String uid) {
    return _wishes
        .where('connectionId', isEqualTo: connectionId)
        .where('authorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error, stackTrace) {
          _logFirestoreIndexLink(
            error,
            streamName: 'watchOwnUnmatchedWishes',
          );
        })
        .map((s) {
          final list = s.docs
              .map((d) => Wish.fromFirestore(d))
              .where((wish) => wish.matchedWithWishId == null || wish.matchedWithWishId!.isEmpty)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<Wish>> watchMatchedWishes(String connectionId) {
    return _wishes
        .where('connectionId', isEqualTo: connectionId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error, stackTrace) {
          _logFirestoreIndexLink(
            error,
            streamName: 'watchMatchedWishes',
          );
        })
        .map((s) {
          final list = s.docs
              .map((d) => Wish.fromFirestore(d))
              .where((wish) => (wish.matchedWithWishId?.isNotEmpty ?? false) || wish.matchedAt != null)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> updateWishStatus(String wishId, WishStatus status) async {
    await _wishes.doc(wishId).update({
      'status': _wishStatusToFirestore(status),
    });
    await _analytics.logEvent(
      'wish_status_changed',
      parameters: {
        'status': _wishStatusToFirestore(status),
      },
    );
  }

  Future<bool> sendSoftSuggestion({
    required Wish wish,
    required String message,
  }) async {
    final uid = _uid;
    if (uid == null) return false;
    if (wish.connectionId.isEmpty || wish.id.isEmpty) return false;

    final partnerId = await _resolvePartnerId(
      connectionId: wish.connectionId,
      currentUserId: uid,
    );
    if (partnerId == null || partnerId.isEmpty) return false;

    await _wishes.doc(wish.id).update({
      'lastSoftSuggestionMessage': message,
      'lastSoftSuggestionFromUserId': uid,
      'lastSoftSuggestionToUserId': partnerId,
      'lastSoftSuggestionAt': FieldValue.serverTimestamp(),
      'softSuggestionCount': FieldValue.increment(1),
    });
    await _analytics.logEvent(
      'wish_soft_suggestion_sent',
      parameters: {
        'message_template': message,
      },
    );
    return true;
  }

  Future<int> runMatch(String connectionId) async {
    final snapshot = await _wishes
        .where('connectionId', isEqualTo: connectionId)
        .orderBy('createdAt', descending: false)
        .get();

    final candidates = snapshot.docs
        .map((doc) => Wish.fromFirestore(doc))
        .where((wish) => _isMatchCandidate(wish))
        .toList();
    final matchedIds = <String>{};
    var createdMatches = 0;

    for (var i = 0; i < candidates.length; i++) {
      final first = candidates[i];
      if (matchedIds.contains(first.id)) continue;

      for (var j = i + 1; j < candidates.length; j++) {
        final second = candidates[j];
        if (matchedIds.contains(second.id)) continue;
        if (_authorId(first) == _authorId(second)) continue;
        if (!_hasTagIntersection(first.normalizedTags, second.normalizedTags)) continue;

        final pairMatched = await _applyMatch(first.id, second.id);
        if (!pairMatched) continue;

        matchedIds.add(first.id);
        matchedIds.add(second.id);
        createdMatches += 1;
        await _analytics.logEvent(
          'wish_matched',
          parameters: {
            'matches_created': createdMatches,
          },
        );
        break;
      }
    }

    return createdMatches;
  }

  Stream<List<Wish>> watchPartnerWishes(String partnerUserId) {
    return _wishes
        .where('userId', isEqualTo: partnerUserId)
        .where('visibleToPartners', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Wish.fromFirestore(d)).toList());
  }

  Stream<List<Wish>> watchPartnerNearFutureWishes(String partnerUserId) {
    return _wishes
        .where('userId', isEqualTo: partnerUserId)
        .where('visibleToPartners', isEqualTo: true)
        .where('isForNearFuture', isEqualTo: true)
        .snapshots()
        .handleError((error, stackTrace) {
          _logFirestoreIndexLink(
            error,
            streamName: 'watchPartnerNearFutureWishes',
          );
        })
        .map((s) {
          final list = s.docs.map((d) => Wish.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<String?> sendWishRequest(String toUserId) async {
    final uid = _uid;
    if (uid == null || uid == toUserId) return null;
    final existing = await _wishRequests
        .where('fromUserId', isEqualTo: uid)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return null;
    final ref = await _wishRequests.add({
      'fromUserId': uid,
      'toUserId': toUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    return ref.id;
  }

  Stream<List<WishRequest>> watchIncomingWishRequests() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _wishRequests
        .where('toUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => WishRequest.fromFirestore(d)).toList());
  }

  Stream<List<WishRequest>> watchOutgoingWishRequests() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _wishRequests
        .where('fromUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => WishRequest.fromFirestore(d)).toList());
  }

  Future<void> markWishRequestAnswered(String requestId) async {
    await _wishRequests.doc(requestId).update({
      'status': 'answered',
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> _applyMatch(String firstWishId, String secondWishId) async {
    return _firestore.runTransaction((tx) async {
      final firstRef = _wishes.doc(firstWishId);
      final secondRef = _wishes.doc(secondWishId);
      final firstSnap = await tx.get(firstRef);
      final secondSnap = await tx.get(secondRef);
      if (!firstSnap.exists || !secondSnap.exists) return false;

      final firstData = firstSnap.data();
      final secondData = secondSnap.data();
      if (firstData == null || secondData == null) return false;

      final firstAlreadyMatched = (firstData['matchedWithWishId'] as String?)?.isNotEmpty ?? false;
      final secondAlreadyMatched = (secondData['matchedWithWishId'] as String?)?.isNotEmpty ?? false;
      if (firstAlreadyMatched || secondAlreadyMatched) return false;

      final firstVisibility = firstData['visibility'] as String?;
      final secondVisibility = secondData['visibility'] as String?;
      final firstStatus = firstData['status'] as String?;
      final secondStatus = secondData['status'] as String?;
      if ((firstVisibility != null && firstVisibility != 'secret_until_match') ||
          (secondVisibility != null && secondVisibility != 'secret_until_match')) {
        return false;
      }
      if ((firstStatus != null && firstStatus != 'new') || (secondStatus != null && secondStatus != 'new')) {
        return false;
      }

      final now = FieldValue.serverTimestamp();
      tx.update(firstRef, {
        'matchedWithWishId': secondWishId,
        'matchedAt': now,
        'visibility': 'shared',
      });
      tx.update(secondRef, {
        'matchedWithWishId': firstWishId,
        'matchedAt': now,
        'visibility': 'shared',
      });
      return true;
    });
  }

  Future<String?> _resolvePartnerId({
    required String connectionId,
    required String currentUserId,
  }) async {
    final doc = await _connections.doc(connectionId).get();
    final data = doc.data();
    if (data == null) return null;
    final fromUserId = data['fromUserId'] as String? ?? '';
    final toUserId = data['toUserId'] as String? ?? '';
    if (fromUserId == currentUserId) return toUserId;
    if (toUserId == currentUserId) return fromUserId;
    return null;
  }

  void _logFirestoreIndexLink(
    Object error, {
    required String streamName,
  }) {
    final message = error.toString();
    final indexUrl = _extractFirstUrl(message);
    if (indexUrl != null) {
      debugPrint('[Wishes] Firestore index link ($streamName): $indexUrl');
    }
  }

  String? _extractFirstUrl(String text) {
    return RegExp(r'(https?://[^\s\)]+)').firstMatch(text)?.group(1);
  }
}

List<String> _normalizeTags(List<String> tags) {
  final unique = <String>{};
  for (final rawTag in tags) {
    final normalized = rawTag.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      unique.add(normalized);
    }
  }
  return unique.toList();
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

bool _isMatchCandidate(Wish wish) {
  final hasMatch = (wish.matchedWithWishId?.isNotEmpty ?? false) || wish.matchedAt != null;
  return wish.visibility == WishVisibility.secretUntilMatch &&
      wish.status == WishStatus.newWish &&
      !hasMatch &&
      wish.normalizedTags.isNotEmpty;
}

String _authorId(Wish wish) {
  if (wish.authorUid.isNotEmpty) return wish.authorUid;
  return wish.userId;
}

bool _hasTagIntersection(List<String> left, List<String> right) {
  if (left.isEmpty || right.isEmpty) return false;
  final rightSet = right.toSet();
  for (final tag in left) {
    if (rightSet.contains(tag)) return true;
  }
  return false;
}
