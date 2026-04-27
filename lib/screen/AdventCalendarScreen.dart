import 'package:flutter/material.dart';
import 'package:sexpedition_application_1/models/advent_day.dart';
import 'package:sexpedition_application_1/services/advent_calendar_repository.dart';
import 'package:table_calendar/table_calendar.dart';

class AdventCalendarScreen extends StatefulWidget {
  const AdventCalendarScreen({super.key});

  @override
  State<AdventCalendarScreen> createState() => _AdventCalendarScreenState();
}

class _AdventCalendarScreenState extends State<AdventCalendarScreen> {
  final AdventCalendarRepository _repo = AdventCalendarRepository();
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Future<AdventDay?>? _selectedFuture;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _focusedDay = DateTime(today.year, today.month, today.day);
    _selectedDay = _focusedDay;
    _selectedFuture = _repo.ensureDay(_selectedDay);
  }

  void _selectDay(DateTime day, DateTime focusedDay) {
    final normalized = DateTime(day.year, day.month, day.day);
    setState(() {
      _selectedDay = normalized;
      _focusedDay = focusedDay;
      _selectedFuture = _repo.ensureDay(normalized);
    });
  }

  Future<void> _respond(AdventDay day, AdventDayStatus status) async {
    await _repo.respond(day.id, status);
    if (!mounted) return;
    setState(() => _selectedFuture = _repo.ensureDay(_selectedDay));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Адвент заданий')),
      body: StreamBuilder<List<AdventDay>>(
        stream: _repo.watchMonth(_focusedDay),
        builder: (context, snapshot) {
          final byDate = <DateTime, AdventDay>{};
          for (final day in snapshot.data ?? const <AdventDay>[]) {
            byDate[DateTime(day.date.year, day.date.month, day.date.day)] = day;
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Каждый день открывается новое интимное задание. Можно принять его или отказаться.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TableCalendar<AdventDay>(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: _selectDay,
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
                eventLoader: (day) {
                  final item = byDate[DateTime(day.year, day.month, day.day)];
                  return item == null ? const <AdventDay>[] : [item];
                },
                calendarBuilders: CalendarBuilders<AdventDay>(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    final item = events.first;
                    final color = item.isAccepted
                        ? Colors.green
                        : item.isSkipped
                        ? theme.colorScheme.outline
                        : theme.colorScheme.primary;
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Icon(Icons.circle, size: 7, color: color),
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<AdventDay?>(
                  future: _selectedFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final day = snapshot.data;
                    if (day == null) {
                      return const _AdventEmptyState();
                    }
                    return _AdventDayCard(
                      day: day,
                      onAccept: () => _respond(day, AdventDayStatus.accepted),
                      onSkip: () => _respond(day, AdventDayStatus.skipped),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdventDayCard extends StatelessWidget {
  const _AdventDayCard({
    required this.day,
    required this.onAccept,
    required this.onSkip,
  });

  final AdventDay day;
  final VoidCallback onAccept;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = day.isAccepted
        ? 'Принято'
        : day.isSkipped
        ? 'Отказ'
        : 'Ожидает решения';
    final statusColor = day.isAccepted
        ? Colors.green
        : day.isSkipped
        ? theme.colorScheme.outline
        : theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${day.date.day}.${day.date.month}.${day.date.year}',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Chip(
                  label: Text(statusLabel),
                  side: BorderSide(color: statusColor),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(day.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(day.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(day.category)),
                Chip(label: Text('Интенсивность ${day.intensity}/3')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: day.isPending ? onSkip : null,
                    child: const Text('Отказываюсь'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: day.isPending ? onAccept : null,
                    child: const Text('Принимаю'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdventEmptyState extends StatelessWidget {
  const _AdventEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Войдите в аккаунт, чтобы открыть задание дня.'),
      ),
    );
  }
}
