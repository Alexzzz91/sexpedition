import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/models/wish.dart';
import 'package:sexpedition_application_1/models/wish_request.dart';

const String _wishesCol = 'wishes';
const String _wishRequestsCol = 'wish_requests';

class WishesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _wishes => _firestore.collection(_wishesCol);
  CollectionReference<Map<String, dynamic>> get _wishRequests => _firestore.collection(_wishRequestsCol);

  Stream<List<Wish>> watchMyWishes() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _wishes
        .where('userId', isEqualTo: uid)
        .snapshots()
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

  Future<void> updateWish(Wish wish) async {
    await _wishes.doc(wish.id).update(wish.toMap());
  }

  Future<void> deleteWish(String wishId) async {
    await _wishes.doc(wishId).delete();
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Wish.fromFirestore(d)).toList());
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
}
