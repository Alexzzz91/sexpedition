import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/models/partner_connection.dart';
import 'package:sexpedition_application_1/models/user_profile.dart';

const String _usersCol = 'users';
const String _connectionsCol = 'connections';

class PartnersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  String? get currentUserId => _uid;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection(_usersCol);
  CollectionReference<Map<String, dynamic>> get _connections => _firestore.collection(_connectionsCol);

  Future<void> ensureMyProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _users.doc(user.uid).set({
      'email': user.email ?? '',
      'displayName': user.displayName,
    }, SetOptions(merge: true));
  }

  Future<UserProfile?> getUserByEmail(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    final snap = await _users.where('email', isEqualTo: trimmed).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return UserProfile.fromFirestore(snap.docs.first);
  }

  Future<String?> sendRequest(String toUserId) async {
    final uid = _uid;
    if (uid == null || uid == toUserId) return null;
    final existing = await _connections
        .where('fromUserId', isEqualTo: uid)
        .where('toUserId', isEqualTo: toUserId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return null;
    final ref = await _connections.add({
      'fromUserId': uid,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> acceptConnection(String connectionId) async {
    await _connections.doc(connectionId).update({'status': 'accepted'});
  }

  Future<void> rejectConnection(String connectionId) async {
    await _connections.doc(connectionId).delete();
  }

  Future<void> removePartner(String connectionId) async {
    await _connections.doc(connectionId).delete();
  }

  Stream<List<PartnerConnection>> watchIncomingRequests() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _connections
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => PartnerConnection.fromFirestore(d)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<PartnerConnection>> watchAcceptedPartners() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    final fromStream = _connections
        .where('fromUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
    final toStream = _connections
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
    List<PartnerConnection> fromList = [];
    List<PartnerConnection> toList = [];
    final controller = StreamController<List<PartnerConnection>>();
    void emit() {
      final ids = <String>{};
      final merged = <PartnerConnection>[];
      for (final c in fromList) {
        if (ids.add(c.id)) merged.add(c);
      }
      for (final c in toList) {
        if (ids.add(c.id)) merged.add(c);
      }
      controller.add(merged);
    }
    fromStream.listen((s) {
      fromList = s.docs.map((d) => PartnerConnection.fromFirestore(d)).toList();
      emit();
    });
    toStream.listen((s) {
      toList = s.docs.map((d) => PartnerConnection.fromFirestore(d)).toList();
      emit();
    });
    return controller.stream;
  }

  Future<UserProfile?> getProfile(String userId) async {
    final doc = await _users.doc(userId).get();
    if (doc.data() == null) return null;
    return UserProfile.fromFirestore(doc);
  }

  /// Обновляет отображаемое имя текущего пользователя в Firestore и в Auth.
  Future<void> updateMyDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final name = displayName.trim().isEmpty ? null : displayName.trim();
    await _users.doc(user.uid).set({
      'email': user.email ?? '',
      'displayName': name,
    }, SetOptions(merge: true));
    await user.updateDisplayName(name ?? '');
    await user.reload();
  }
}