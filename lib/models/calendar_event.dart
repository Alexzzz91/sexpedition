import 'package:cloud_firestore/cloud_firestore.dart';

/// Тип события в календаре.
enum CalendarEventKind {
  /// Запись о сексе (типы, позы, игрушки, длительность, оценка).
  sexRecord,
  /// Пожелание на ближайшие 2 дня (видно партнёрам).
  wishToday,
  /// Старая запись без типа (только заметка).
  legacy,
}

/// Константы типов секса для выбора в формах.
const List<String> sexTypeLabels = [
  'Оральный',
  'Анальный',
  'Классический',
  'Мастурбация',
  'Совместная мастурбация',
  'Групповой секс',
];

/// Событие в календаре. Дата хранится как начало дня (без времени).
class CalendarEvent {
  final String id;
  final DateTime date;
  final String userId;
  final String? partnerId;
  final String? note;

  final CalendarEventKind kind;

  /// Для sex_record: типы секса (индексы или id из sexTypeLabels).
  final List<String> sexTypes;
  /// Для sex_record: id поз из справочника камасутры.
  final List<String> poseIds;
  /// Для sex_record: id или названия игрушек.
  final List<String> toyIds;
  /// Для sex_record: длительность в минутах.
  final int? durationMinutes;
  /// Для sex_record: оценка удовлетворённости 1–5.
  final int? satisfactionRating;

  /// Для wish_today: ссылка на фильм/игрушку.
  final String? contentLink;
  /// Для wish_today: произвольный текст.
  final String? contentText;
  /// Для wish_today: URL загруженного изображения.
  final String? imageUrl;
  /// Для wish_today: видно партнёрам.
  final bool visibleToPartners;

  const CalendarEvent({
    required this.id,
    required this.date,
    required this.userId,
    this.partnerId,
    this.note,
    this.kind = CalendarEventKind.legacy,
    this.sexTypes = const [],
    this.poseIds = const [],
    this.toyIds = const [],
    this.durationMinutes,
    this.satisfactionRating,
    this.contentLink,
    this.contentText,
    this.imageUrl,
    this.visibleToPartners = true,
  });

  bool get isSexRecord => kind == CalendarEventKind.sexRecord;
  bool get isWishToday => kind == CalendarEventKind.wishToday;
  bool get isLegacy => kind == CalendarEventKind.legacy;

  /// Конечная дата пожелания (date + 2 дня).
  DateTime get dateEnd => DateTime(date.year, date.month, date.day + 2);

  /// Нормализует дату до начала дня (без времени) для группировки.
  static DateTime toDateOnly(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  static String _kindToStorage(CalendarEventKind k) {
    switch (k) {
      case CalendarEventKind.sexRecord:
        return 'sex_record';
      case CalendarEventKind.wishToday:
        return 'wish_today';
      case CalendarEventKind.legacy:
        return 'legacy';
    }
  }

  static CalendarEventKind _kindFromStorage(String? v) {
    switch (v) {
      case 'sex_record':
        return CalendarEventKind.sexRecord;
      case 'wish_today':
        return CalendarEventKind.wishToday;
      default:
        return CalendarEventKind.legacy;
    }
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': Timestamp.fromDate(toDateOnly(date)),
      'userId': userId,
      'partnerId': partnerId,
      'note': note,
      'kind': _kindToStorage(kind),
    };
    if (kind == CalendarEventKind.sexRecord) {
      map['sexTypes'] = sexTypes;
      map['poseIds'] = poseIds;
      map['toyIds'] = toyIds;
      if (durationMinutes != null) map['durationMinutes'] = durationMinutes;
      if (satisfactionRating != null) map['satisfactionRating'] = satisfactionRating;
    }
    if (kind == CalendarEventKind.wishToday) {
      if (contentLink != null) map['contentLink'] = contentLink;
      if (contentText != null) map['contentText'] = contentText;
      if (imageUrl != null) map['imageUrl'] = imageUrl;
      map['visibleToPartners'] = visibleToPartners;
    }
    return map;
  }

  static CalendarEvent fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final date = (data['date'] as Timestamp).toDate();
    final kind = _kindFromStorage(data['kind'] as String?);

    List<String> listFrom(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return CalendarEvent(
      id: doc.id,
      date: toDateOnly(date),
      userId: data['userId'] as String,
      partnerId: data['partnerId'] as String?,
      note: data['note'] as String?,
      kind: kind,
      sexTypes: listFrom(data['sexTypes']),
      poseIds: listFrom(data['poseIds']),
      toyIds: listFrom(data['toyIds']),
      durationMinutes: data['durationMinutes'] as int?,
      satisfactionRating: data['satisfactionRating'] as int?,
      contentLink: data['contentLink'] as String?,
      contentText: data['contentText'] as String?,
      imageUrl: data['imageUrl'] as String?,
      visibleToPartners: data['visibleToPartners'] as bool? ?? true,
    );
  }

  CalendarEvent copyWith({
    String? id,
    DateTime? date,
    String? userId,
    String? partnerId,
    String? note,
    CalendarEventKind? kind,
    List<String>? sexTypes,
    List<String>? poseIds,
    List<String>? toyIds,
    int? durationMinutes,
    int? satisfactionRating,
    String? contentLink,
    String? contentText,
    String? imageUrl,
    bool? visibleToPartners,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      note: note ?? this.note,
      kind: kind ?? this.kind,
      sexTypes: sexTypes ?? this.sexTypes,
      poseIds: poseIds ?? this.poseIds,
      toyIds: toyIds ?? this.toyIds,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      satisfactionRating: satisfactionRating ?? this.satisfactionRating,
      contentLink: contentLink ?? this.contentLink,
      contentText: contentText ?? this.contentText,
      imageUrl: imageUrl ?? this.imageUrl,
      visibleToPartners: visibleToPartners ?? this.visibleToPartners,
    );
  }
}
