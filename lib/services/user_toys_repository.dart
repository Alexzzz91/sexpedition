import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/models/user_toy.dart';

const String _collection = 'user_toys';

class UserToysRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  CollectionReference<Map<String, dynamic>> get _col => _firestore.collection(_collection);

  Stream<List<UserToy>> watchToys() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _col
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => UserToy.fromFirestore(d)).toList();
          list.sort((a, b) => a.name.compareTo(b.name));
          return list;
        });
  }

  Future<void> addToy(String name) async {
    final uid = _uid;
    if (uid == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _col.add(UserToy(id: '', userId: uid, name: trimmed).toMap());
  }

  Future<void> deleteToy(String toyId) async {
    await _col.doc(toyId).delete();
  }
}
