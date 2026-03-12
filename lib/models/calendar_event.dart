import 'package:cloud_firestore/cloud_firestore.dart';

/// Событие в календаре. Дата хранится как начало дня (без времени).
class CalendarEvent {
  final String id;
  final DateTime date;
  final String userId;
  final String? partnerId;
  final String? note;

  const CalendarEvent({
    required this.id,
    required this.date,
    required this.userId,
    this.partnerId,
    this.note,
  });

  /// Нормализует дату до начала дня (без времени) для группировки.
  static DateTime toDateOnly(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(toDateOnly(date)),
      'userId': userId,
      'partnerId': partnerId,
      'note': note,
    };
  }

  static CalendarEvent fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final date = (data['date'] as Timestamp).toDate();
    return CalendarEvent(
      id: doc.id,
      date: toDateOnly(date),
      userId: data['userId'] as String,
      partnerId: data['partnerId'] as String?,
      note: data['note'] as String?,
    );
  }

  CalendarEvent copyWith({
    String? id,
    DateTime? date,
    String? userId,
    String? partnerId,
    String? note,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      note: note ?? this.note,
    );
  }
}
