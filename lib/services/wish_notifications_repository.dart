import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sexpedition_application_1/models/wish_notification.dart';
import 'package:sexpedition_application_1/models/wish_notification_comment.dart';

class WishNotificationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('wish_notifications');

  Stream<List<WishNotification>> watchMyNotifications() async* {
    final uid = _uid;
    if (uid == null) {
      yield [];
      return;
    }
    try {
      await for (final snapshot
          in _notifications
              .where('toUserId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .snapshots()) {
        yield snapshot.docs
            .map((d) => WishNotification.fromFirestore(d))
            .toList();
      }
    } catch (error) {
      _logFirestoreIndexLink(error);
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _uid;
    if (uid == null) return;
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  Stream<List<WishNotificationComment>> watchComments(
    String notificationId,
  ) async* {
    try {
      await for (final snapshot
          in _notifications
              .doc(notificationId)
              .collection('comments')
              .orderBy('createdAt')
              .snapshots()) {
        yield snapshot.docs
            .map(
              (d) => WishNotificationComment.fromFirestore(notificationId, d),
            )
            .toList();
      }
    } catch (error) {
      _logFirestoreIndexLink(error);
      rethrow;
    }
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

  void _logFirestoreIndexLink(Object error) {
    final message = error.toString();
    final indexUrl = _extractFirstUrl(message);
    if (indexUrl != null) {
      debugPrint('[WishNotifications] Firestore index link: $indexUrl');
    }
  }

  String? _extractFirstUrl(String text) {
    return RegExp(r'(https?://[^\s\)]+)').firstMatch(text)?.group(1);
  }
}
