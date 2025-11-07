import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focused,
          selectedDayPredicate: (d) => isSameDay(_selected, d),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selected = selectedDay;
              _focused = focusedDay;
            });
          },
        ),
        const SizedBox(height: 12),
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'You selected: ${_selected!.toLocal().toIso8601String().split('T').first}',
            ),
          ),
        const SizedBox(height: 12),
        const Text('Schedule outfits here (save scheduling API later)'),
      ],
    );
  }
}
