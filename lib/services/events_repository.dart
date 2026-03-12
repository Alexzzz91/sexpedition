import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/models/calendar_event.dart';

const String _collection = 'events';

class EventsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  CollectionReference<Map<String, dynamic>> get _col => _firestore.collection(_collection);

  /// Загружает события текущего пользователя (где userId или partnerId равен текущему).
  Stream<List<CalendarEvent>> watchEvents() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CalendarEvent.fromFirestore(d)).toList());
  }

  Future<void> addEvent(CalendarEvent event) async {
    final uid = _uid;
    if (uid == null) return;
    await _col.add(event.copyWith(userId: uid).toMap());
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _col.doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _col.doc(eventId).delete();
  }
}
