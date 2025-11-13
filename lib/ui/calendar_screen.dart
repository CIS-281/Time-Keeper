// Tobias Cash
// 09/30/2025
// Changed 11/07/2025
// Suong Tran + Team
// Calendar screen: Week View + Manager View
// Dark theme, no example data, includes hours worked field
// Suong Tran + Team
// Calendar screen: Week View + Manager View
// Dark theme, scrollable, no example data, includes hours worked field

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;

  // Placeholder for hours worked (connect to real data later)
  double _hoursWorked = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          backgroundColor: Colors.indigo[900],
          title: const Text('Calendar & Schedule'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Week View'),
              Tab(text: 'Manager'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildWeekViewTab(),
            _buildManagerTab(),
          ],
        ),
      ),
    );
  }

  // ============================
  // Week View Tab (scrollable to prevent overflow)
  // ============================
  Widget _buildWeekViewTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2026, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.indigo,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: Colors.redAccent),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.white70),
                weekendStyle: TextStyle(color: Colors.redAccent),
              ),
              headerStyle: const HeaderStyle(
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                formatButtonTextStyle: TextStyle(color: Colors.white),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon:
                Icon(Icons.chevron_right, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            // Selected day display
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _selectedDay == null
                      ? 'Select a day to view scheduled shifts.'
                      : 'Selected: ${DateFormat.yMMMMd().format(_selectedDay!)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Hours Worked display
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hours Worked:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    _hoursWorked.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // Manager Tab
  // ============================
  Widget _buildManagerTab() {
    return const Center(
      child: Text(
        'Manager scheduling view coming soon.',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}
