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

  bool _isPartnerEvent(CalendarEvent e) {
    final myId = _partnersRepo.currentUserId;
    return myId != null && e.userId != myId;
  }

  Widget? _buildEventSubtitle(CalendarEvent e) {
    final parts = <String>[];
    final sub = _eventSubtitle(e);
    if (sub != null) parts.add(sub);
    if (_isPartnerEvent(e)) {
      return FutureBuilder<String>(
        future: _partnersRepo.getProfile(e.userId).then((p) => p?.displayLabel ?? 'Партнёр'),
        builder: (context, snap) {
          final from = snap.hasData ? 'от ${snap.data}' : 'от партнёра';
          return Text(
            parts.isEmpty ? from : '${parts.join(' · ')}\n$from',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        },
      );
    }
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis);
  }

  /// Маркер на ячейке календаря: цвет и количество (1–3 точки).
  Widget _buildMarkerDot(Color color, int count) {
    final n = count.clamp(1, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(n, (_) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        width: 5,
        height: 5,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      )),
    );
  }

  /// Результат диалога просмотра пожелания партнёра: закрыть, записать как секс, добавить своё пожелание.
  static const _partnerWishClose = 0;
  static const _partnerWishSexRecord = 1;
  static const _partnerWishAddMyWish = 2;

  Future<void> _showPartnerWishView(DateTime day, CalendarEvent e) async {
    if (!e.isWishToday) return;
    final endDate = day.add(const Duration(days: 2));
    final profile = await _partnersRepo.getProfile(e.userId);
    final fromLabel = profile?.displayLabel ?? 'Партнёр';
    if (!mounted) return;
    final action = await showDialog<int>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.card_giftcard, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Пожелание от $fromLabel')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Период
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Период', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}.${day.month}.${day.year} — ${endDate.day}.${endDate.month}.${endDate.year}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                if (e.sexTypes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Тип секса', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: e.sexTypes.map((t) => Chip(label: Text(t), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (e.contentLink?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ссылка', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                          const SizedBox(height: 4),
                          SelectableText(e.contentLink!, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ],
                if (e.contentText?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Текст', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                          const SizedBox(height: 4),
                          SelectableText(e.contentText!, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ],
                if (e.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          child: Text('Фото', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                        ),
                        Image.network(e.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_partnerWishClose),
              child: const Text('Закрыть'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(_partnerWishAddMyWish),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Добавить своё пожелание'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_partnerWishSexRecord),
              icon: const Icon(Icons.favorite),
              label: const Text('Записать как секс'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (action == _partnerWishSexRecord) {
      _showEventDialog(day, prefillFromWish: e, dayEvents: _eventsMap[CalendarEvent.toDateOnly(day)] ?? []);
    } else if (action == _partnerWishAddMyWish) {
      final complementLabel = fromLabel;
      _showEventDialog(
        day,
        startAtWishToday: true,
        complementToPartnerLabel: complementLabel,
        dayEvents: _eventsMap[CalendarEvent.toDateOnly(day)] ?? [],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Календарь 1')),
      body: StreamBuilder<List<CalendarEvent>>(
        stream: _eventsRepo.watchCalendarEventsWithPartners(_partnersRepo),
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
                    final ev = dayEvents.first;
                    if (_isPartnerEvent(ev)) {
                      _showPartnerWishView(selectedDay, ev);
                    } else {
                      _showEventDialog(selectedDay, existing: ev, dayEvents: dayEvents);
                    }
                  } else if (dayEvents.isNotEmpty) {
                    _showDayEventsChoice(selectedDay, dayEvents);
                  } else {
                    _showEventDialog(selectedDay, dayEvents: dayEvents);
                  }
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) =>
                    setState(() => _focusedDay = focusedDay),
                eventLoader: (day) => _eventsMap[_normalize(day)] ?? [],
                calendarBuilders: CalendarBuilders<CalendarEvent>(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final myId = _partnersRepo.currentUserId;
                    final myEvents = events.where((e) => e.userId == myId).toList();
                    final partnerWishes = events.where((e) => e.isWishToday && e.userId != myId).toList();
                    final theme = Theme.of(context);
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (myEvents.isNotEmpty)
                            _buildMarkerDot(theme.colorScheme.primary, myEvents.length),
                          if (myEvents.isNotEmpty && partnerWishes.isNotEmpty) const SizedBox(width: 4),
                          if (partnerWishes.isNotEmpty)
                            _buildMarkerDot(theme.colorScheme.secondary, partnerWishes.length),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Легенда: свои события / пожелания партнёра
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMarkerDot(Theme.of(context).colorScheme.primary, 1),
                        const SizedBox(width: 6),
                        Text('мои', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMarkerDot(Theme.of(context).colorScheme.secondary, 1),
                        const SizedBox(width: 6),
                        Text('пожелания партнёра', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
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
                    (e) {
                      final isPartner = _isPartnerEvent(e);
                      final color = isPartner
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary;
                      return ListTile(
                        leading: Icon(
                          e.isSexRecord
                              ? Icons.favorite
                              : (e.isWishToday
                                    ? Icons.card_giftcard
                                    : Icons.event_note),
                          color: color,
                        ),
                        title: Text(_eventTitle(e)),
                        subtitle: _buildEventSubtitle(e),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          if (isPartner) {
                            _showPartnerWishView(_selectedDay!, e);
                          } else {
                            _showEventDialog(_selectedDay!, existing: e, dayEvents: selectedDayEvents);
                          }
                        },
                      );
                    },
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

  Future<void> _showEventDialog(DateTime day, {
    CalendarEvent? existing,
    CalendarEvent? prefillFromWish,
    List<CalendarEvent>? dayEvents,
    bool startAtWishToday = false,
    String? complementToPartnerLabel,
  }) async {
    final date = _normalize(day);
    final partnersList = await _loadPartnersForDialog();
    if (!mounted) return;

    final myId = _partnersRepo.currentUserId;
    final partnerWishesForDay = (dayEvents ?? []).where((ev) => ev.isWishToday && myId != null && ev.userId != myId).toList();

    final result = await showDialog<AddEventDialogResult>(
      context: context,
      builder: (context) => CalendarAddEventDialog(
        date: date,
        existing: existing,
        prefillFromWish: prefillFromWish,
        partnerWishesForDay: partnerWishesForDay,
        partnersList: partnersList,
        toysRepository: _toysRepo,
        uploadImage: (file) => uploadWishImage(file),
        startAtWishToday: startAtWishToday,
        complementToPartnerLabel: complementToPartnerLabel,
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
      if (_isPartnerEvent(choice.event!)) {
        _showPartnerWishView(day, choice.event!);
      } else {
        _showEventDialog(day, existing: choice.event, dayEvents: dayEvents);
      }
    } else {
      _showEventDialog(day, dayEvents: dayEvents);
    }
  }
}

class _DayEventChoice {
  const _DayEventChoice(this.event);
  final CalendarEvent? event;
  static _DayEventChoice edit(CalendarEvent e) => _DayEventChoice(e);
  static _DayEventChoice addNew() => const _DayEventChoice(null);
}
