import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sexpedition_application_1/models/calendar_event.dart';
import 'package:sexpedition_application_1/services/partners_repository.dart';

const String _collection = 'events';

class EventsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  CollectionReference<Map<String, dynamic>> get _col => _firestore.collection(_collection);

  /// Загружает события текущего пользователя.
  Stream<List<CalendarEvent>> watchEvents() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CalendarEvent.fromFirestore(d)).toList());
  }

  /// Загружает события указанного пользователя (для пожеланий партнёров).
  Stream<List<CalendarEvent>> watchEventsByUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CalendarEvent.fromFirestore(d)).toList());
  }

  /// Объединённый стрим: мои события + пожелания партнёров (только wish_today).
  Stream<List<CalendarEvent>> watchCalendarEvents(Stream<List<String>> partnerIdsStream) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    final controller = StreamController<List<CalendarEvent>>();
    List<CalendarEvent> myEvents = [];
    final partnerEvents = <String, List<CalendarEvent>>{};
    final partnerSubscriptions = <String, StreamSubscription<List<CalendarEvent>>>{};

    void emit() {
      final partnerWishes = partnerEvents.values.expand((list) => list.where((e) => e.isWishToday));
      controller.add([...myEvents, ...partnerWishes]);
    }

    final mySub = watchEvents().listen((list) {
      myEvents = list;
      emit();
    });

    final partnersSub = partnerIdsStream.listen((partnerIds) {
      for (final sub in partnerSubscriptions.values) {
        sub.cancel();
      }
      partnerSubscriptions.clear();
      partnerEvents.clear();

      for (final partnerId in partnerIds) {
        partnerSubscriptions[partnerId] = watchEventsByUser(partnerId).listen((list) {
          partnerEvents[partnerId] = list;
          emit();
        });
      }
      emit();
    });

    controller.onCancel = () {
      mySub.cancel();
      partnersSub.cancel();
      for (final sub in partnerSubscriptions.values) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  /// Объединённый стрим для календаря: мои события + пожелания принятых партнёров.
  Stream<List<CalendarEvent>> watchCalendarEventsWithPartners(PartnersRepository partnersRepo) {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    final partnerIdsStream = partnersRepo.watchAcceptedPartners().map((connections) {
      return connections.map((c) => c.partnerUserId(uid)).toList();
    });
    return watchCalendarEvents(partnerIdsStream);
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
