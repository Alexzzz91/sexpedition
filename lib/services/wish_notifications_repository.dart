import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/models/wish_notification.dart';
import 'package:sexpedition_application_1/models/wish_notification_comment.dart';

class WishNotificationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('wish_notifications');

  Stream<List<WishNotification>> watchMyNotifications() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _notifications
        .where('toUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => WishNotification.fromFirestore(d)).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _uid;
    if (uid == null) return;
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  Stream<List<WishNotificationComment>> watchComments(String notificationId) {
    return _notifications
        .doc(notificationId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map((d) => WishNotificationComment.fromFirestore(notificationId, d)).toList());
  }

  Future<void> addComment(String notificationId, String text) async {
    final uid = _uid;
    final normalized = text.trim();
    if (uid == null || normalized.isEmpty) return;
    await _notifications.doc(notificationId).collection('comments').add({
      'authorUserId': uid,
      'text': normalized,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
