import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<EventChannel>> _events = {};

  @override
  void initState() {
    super.initState();
    // Загружаем события из Firestore для текущего пользователя
    _loadEvents();
  }

  _loadEvents() async {
    // Запрос к Firestore: events where userId == currentUser.uid OR partnerId == currentUser.uid
    // Преобразуем в Map<DateTime, List<Event>>, где DateTime - это день без времени.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Календарь'),
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2010, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _showAddEventDialog(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        eventLoader: (day) {
          return _events[day] ?? [];
        },
      ),
    );
  }

  _showAddEventDialog(DateTime day) {
    // Диалог с выбором партнера (из принятых связей) и полем для заметок.
  }
}