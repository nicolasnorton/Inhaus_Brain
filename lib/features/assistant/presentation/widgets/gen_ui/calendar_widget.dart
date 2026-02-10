import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatefulWidget {
  final Map<String, dynamic> data;

  const CalendarWidget({super.key, required this.data});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] ?? 'Schedule';
    final events = widget.data['events'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 12),
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return events.where((e) {
                 final date = DateTime.tryParse(e['date'] ?? '');
                 return isSameDay(date, day);
              }).toList();
            },
            calendarStyle: const CalendarStyle(
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.white54),
              outsideTextStyle: TextStyle(color: Colors.white24),
              selectedDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.3), shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white70),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white70),
            ),
          ),
          if (_selectedDay != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Text('Events on ${_selectedDay.toString().split(' ')[0]}:', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...events.where((e) => isSameDay(DateTime.tryParse(e['date'] ?? ''), _selectedDay)).map((e) => 
               Padding(
                 padding: const EdgeInsets.only(bottom: 4.0),
                 child: Row(
                   children: [
                     const Icon(Icons.event_note, size: 14, color: Colors.blueAccent),
                     const SizedBox(width: 8),
                     Expanded(child: Text(e['title'] ?? 'Event', style: const TextStyle(color: Colors.white, fontSize: 13))),
                   ],
                 ),
               )
            ),
            if (events.where((e) => isSameDay(DateTime.tryParse(e['date'] ?? ''), _selectedDay)).isEmpty)
              const Text('No events.', style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
