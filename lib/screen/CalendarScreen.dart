import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sexpedition_application_1/models/calendar_event.dart';
import 'package:sexpedition_application_1/services/events_repository.dart';
import 'package:sexpedition_application_1/services/partners_repository.dart';

sealed class _EventDialogResult {}
class _EventDialogSave extends _EventDialogResult {
  _EventDialogSave(this.note, this.date, this.partnerId);
  final String note;
  final DateTime date;
  final String? partnerId;
}
class _EventDialogDelete extends _EventDialogResult {}
class _EventDialogCancel extends _EventDialogResult {}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EventsRepository _eventsRepo = EventsRepository();
  final PartnersRepository _partnersRepo = PartnersRepository();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<CalendarEvent>> _eventsMap = {};

  static DateTime _normalize(DateTime d) => CalendarEvent.toDateOnly(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
      ),
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
                onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                eventLoader: (day) => _eventsMap[_normalize(day)] ?? [],
              ),
              if (_selectedDay != null) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  ...selectedDayEvents.map((e) => ListTile(
                        title: Text(e.note?.isNotEmpty == true ? e.note! : 'Без заметки'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showEventDialog(_selectedDay!, existing: e),
                      )),
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
    final isEdit = existing != null;
    final noteController = TextEditingController(text: existing?.note ?? '');
    final date = _normalize(day);
    final partnersList = await _loadPartnersForDialog();
    String? selectedPartnerId = existing?.partnerId;

    final result = await showDialog<_EventDialogResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Редактировать событие' : 'Добавить событие'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Дата: ${date.day}.${date.month}.${date.year}'),
                    const SizedBox(height: 16),
                    if (partnersList.isNotEmpty) ...[
                      DropdownButtonFormField<String?>(
                        value: selectedPartnerId,
                        decoration: const InputDecoration(
                          labelText: 'Партнёр',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Не выбран')),
                          ...partnersList.map((p) => DropdownMenuItem(value: p.userId, child: Text(p.label))),
                        ],
                        onChanged: (v) => setState(() => selectedPartnerId = v),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Заметка',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEdit)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_EventDialogDelete()),
                    child: Text('Удалить', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_EventDialogCancel()),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_EventDialogSave(noteController.text.trim(), date, selectedPartnerId)),
                  child: Text(isEdit ? 'Сохранить' : 'Добавить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result is _EventDialogCancel) return;
    if (result is _EventDialogDelete && existing != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Удалить событие?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Нет')),
            FilledButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Да')),
          ],
        ),
      );
      if (confirm == true) await _eventsRepo.deleteEvent(existing.id);
      return;
    }
    if (result is _EventDialogSave) {
      if (isEdit) {
        await _eventsRepo.updateEvent(existing.copyWith(
          note: result.note.isEmpty ? null : result.note,
          partnerId: result.partnerId,
        ));
      } else {
        await _eventsRepo.addEvent(CalendarEvent(
          id: '',
          date: result.date,
          userId: '',
          partnerId: result.partnerId,
          note: result.note.isEmpty ? null : result.note,
        ));
      }
    }
  }

  Future<void> _showDayEventsChoice(DateTime day, List<CalendarEvent> dayEvents) async {
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
              ...dayEvents.map((e) => ListTile(
                    title: Text(e.note?.isNotEmpty == true ? e.note! : 'Без заметки'),
                    onTap: () => Navigator.of(context).pop(_DayEventChoice.edit(e)),
                  )),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Добавить событие'),
                onTap: () => Navigator.of(context).pop(_DayEventChoice.addNew()),
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
