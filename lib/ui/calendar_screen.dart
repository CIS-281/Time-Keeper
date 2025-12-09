import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:time_keeper/data/models/task.dart';
import 'package:time_keeper/data/repositories/tasks_repo.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repo = TasksRepository();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Map of day -> list of tasks on that day
  Map<DateTime, List<TaskModel>> _events = {};
  List<TaskModel> _selectedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _repo.getAllTasks();

    final Map<DateTime, List<TaskModel>> eventMap = {};

    for (final t in tasks) {
      // We only put tasks on the calendar if they have a start time
      if (t.startUtc == null) continue;

      final dt = DateTime.fromMillisecondsSinceEpoch(t.startUtc!);
      final day = DateTime(dt.year, dt.month, dt.day);

      eventMap.putIfAbsent(day, () => []);
      eventMap[day]!.add(t);
    }

    setState(() {
      _events = eventMap;
      if (_selectedDay != null) {
        _selectedTasks = _getTasksForDay(_selectedDay!);
      }
    });
  }

  List<TaskModel> _getTasksForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _events[normalized] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar<TaskModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 1, 1),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

            calendarFormat: CalendarFormat.month,
            eventLoader: _getTasksForDay,

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedTasks = _getTasksForDay(selectedDay);
              });
            },

            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _selectedTasks.isEmpty
                ? const Center(
              child: Text(
                'No tasks for this day',
                style: TextStyle(fontSize: 18),
              ),
            )
                : ListView.builder(
              itemCount: _selectedTasks.length,
              itemBuilder: (context, index) {
                final task = _selectedTasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(task.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.category != null &&
                            task.category!.isNotEmpty)
                          Text('Category: ${task.category}'),
                        if (task.clientJob != null &&
                            task.clientJob!.isNotEmpty)
                          Text('Client/Job: ${task.clientJob}'),
                        if (task.startUtc != null)
                          Text(
                            'Start: ${DateTime.fromMillisecondsSinceEpoch(task.startUtc!)}',
                          ),
                        if (task.endUtc != null)
                          Text(
                            'End: ${DateTime.fromMillisecondsSinceEpoch(task.endUtc!)}',
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
