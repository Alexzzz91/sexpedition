import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sexpedition_application_1/models/calendar_event.dart';
import 'package:sexpedition_application_1/screen/calendar_add_event_dialog.dart';
import 'package:sexpedition_application_1/services/events_repository.dart';
import 'package:sexpedition_application_1/services/partners_repository.dart';
import 'package:sexpedition_application_1/services/user_toys_repository.dart';
import 'package:sexpedition_application_1/services/wish_image_storage.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EventsRepository _eventsRepo = EventsRepository();
  final PartnersRepository _partnersRepo = PartnersRepository();
  final UserToysRepository _toysRepo = UserToysRepository();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<CalendarEvent>> _eventsMap = {};

  static DateTime _normalize(DateTime d) => CalendarEvent.toDateOnly(d);

  String _eventTitle(CalendarEvent e) {
    if (e.isSexRecord) {
      if (e.sexTypes.isNotEmpty)
        return 'Запись о сексе: ${e.sexTypes.join(", ")}';
      return 'Запись о сексе';
    }
    if (e.isWishToday) {
      if (e.contentText?.isNotEmpty == true) return e.contentText!;
      if (e.contentLink?.isNotEmpty == true) return 'Пожелание (ссылка)';
      if (e.imageUrl != null) return 'Пожелание (фото)';
      return 'Пожелание на сегодня';
    }
    return e.note?.isNotEmpty == true ? e.note! : 'Без заметки';
  }

  String? _eventSubtitle(CalendarEvent e) {
    if (e.isSexRecord && e.note?.isNotEmpty == true) return e.note;
    if (e.isWishToday && e.sexTypes.isNotEmpty) return e.sexTypes.join(', ');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Календарь 1')),
      body: StreamBuilder<List<CalendarEvent>>(
        stream: _eventsRepo.watchEvents(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final list = snapshot.data!;
            _eventsMap = {};
            for (final e in list) {
              final key = _normalize(e.date);
              _eventsMap[key] ??= [];
              _eventsMap[key]!.add(e);
            }
          }
          final selectedDayEvents = _selectedDay == null
              ? <CalendarEvent>[]
              : (_eventsMap[_normalize(_selectedDay!)] ?? []);

          return Column(
            children: [
              TableCalendar<CalendarEvent>(
                firstDay: DateTime.utc(2010, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  final dayEvents = _eventsMap[_normalize(selectedDay)] ?? [];
                  if (dayEvents.length == 1) {
                    _showEventDialog(selectedDay, existing: dayEvents.first);
                  } else if (dayEvents.isNotEmpty) {
                    _showDayEventsChoice(selectedDay, dayEvents);
                  } else {
                    _showEventDialog(selectedDay);
                  }
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) =>
                    setState(() => _focusedDay = focusedDay),
                eventLoader: (day) => _eventsMap[_normalize(day)] ?? [],
              ),
              if (_selectedDay != null) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'События на ${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                if (selectedDayEvents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Нет событий',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  ...selectedDayEvents.map(
                    (e) => ListTile(
                      leading: Icon(
                        e.isSexRecord
                            ? Icons.favorite
                            : (e.isWishToday
                                  ? Icons.card_giftcard
                                  : Icons.event_note),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(_eventTitle(e)),
                      subtitle: _eventSubtitle(e) != null
                          ? Text(
                              _eventSubtitle(e)!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showEventDialog(_selectedDay!, existing: e),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<List<({String userId, String label})>> _loadPartnersForDialog() async {
    final connections = await _partnersRepo.watchAcceptedPartners().first;
    final myId = _partnersRepo.currentUserId;
    if (myId == null) return [];
    final list = <({String userId, String label})>[];
    for (final c in connections) {
      final partnerId = c.partnerUserId(myId);
      final profile = await _partnersRepo.getProfile(partnerId);
      list.add((userId: partnerId, label: profile?.displayLabel ?? partnerId));
    }
    return list;
  }

  Future<void> _showEventDialog(DateTime day, {CalendarEvent? existing}) async {
    final date = _normalize(day);
    final partnersList = await _loadPartnersForDialog();
    if (!mounted) return;

    final result = await showDialog<AddEventDialogResult>(
      context: context,
      builder: (context) => CalendarAddEventDialog(
        date: date,
        existing: existing,
        partnersList: partnersList,
        toysRepository: _toysRepo,
        uploadImage: (file) => uploadWishImage(file),
      ),
    );

    if (result == null || result is AddEventDialogCancel) return;
    if (result is AddEventDialogDelete && existing != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Удалить событие?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Нет'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Да'),
            ),
          ],
        ),
      );
      if (confirm == true && mounted)
        await _eventsRepo.deleteEvent(existing.id);
      return;
    }
    if (!mounted) return;
    if (result is AddEventDialogSaveSexRecord) {
      final event = CalendarEvent(
        id: existing?.id ?? '',
        date: result.date,
        userId: existing?.userId ?? '',
        partnerId: result.partnerId,
        kind: CalendarEventKind.sexRecord,
        sexTypes: result.sexTypes,
        poseIds: result.poseIds,
        toyIds: result.toyIds,
        durationMinutes: result.durationMinutes,
        satisfactionRating: result.satisfactionRating,
        note: result.note,
      );
      if (existing != null) {
        await _eventsRepo.updateEvent(event);
      } else {
        await _eventsRepo.addEvent(event);
      }
    }
    if (result is AddEventDialogSaveWish) {
      final event = CalendarEvent(
        id: existing?.id ?? '',
        date: result.date,
        userId: existing?.userId ?? '',
        kind: CalendarEventKind.wishToday,
        sexTypes: result.sexTypes,
        contentLink: result.contentLink,
        contentText: result.contentText,
        imageUrl: result.imageUrl,
        visibleToPartners: result.visibleToPartners,
      );
      if (existing != null) {
        await _eventsRepo.updateEvent(event);
      } else {
        await _eventsRepo.addEvent(event);
      }
    }
  }

  Future<void> _showDayEventsChoice(
    DateTime day,
    List<CalendarEvent> dayEvents,
  ) async {
    final choice = await showModalBottomSheet<_DayEventChoice>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${day.day}.${day.month}.${day.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...dayEvents.map(
                (e) => ListTile(
                  leading: Icon(
                    e.isSexRecord
                        ? Icons.favorite
                        : (e.isWishToday
                              ? Icons.card_giftcard
                              : Icons.event_note),
                  ),
                  title: Text(_eventTitle(e)),
                  onTap: () =>
                      Navigator.of(context).pop(_DayEventChoice.edit(e)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Добавить событие'),
                onTap: () =>
                    Navigator.of(context).pop(_DayEventChoice.addNew()),
              ),
            ],
          ),
        );
      },
    );
    if (choice == null || !mounted) return;
    if (choice.event != null) {
      _showEventDialog(day, existing: choice.event);
    } else {
      _showEventDialog(day);
    }
  }
}

class _DayEventChoice {
  const _DayEventChoice(this.event);
  final CalendarEvent? event;
  static _DayEventChoice edit(CalendarEvent e) => _DayEventChoice(e);
  static _DayEventChoice addNew() => const _DayEventChoice(null);
}
