// Tobias Cash
// 09/30/2025
// First setup for basic main file. This first setup generates a clean homescreen.

import 'package:flutter/material.dart';
import 'ui/clock_screen.dart';
import 'ui/tasks_screen.dart';
import 'ui/calendar_screen.dart';
import 'ui/settings_screen.dart';

void main() => runApp(const TimeKeeperApp());

class TimeKeeperApp extends StatelessWidget {
  const TimeKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Keeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomeShell(),
    );
  }
}

/// Bottom-nav shell that hosts the four primary screens.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _titles = ['Clock', 'Tasks', 'Calendar', 'Settings'];
  static final _pages = <Widget>[
    const ClockScreen(),
    const TasksScreen(),
    const CalendarScreen(),
    const SettingsScreen(),
  ];

  void _onTap(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Time Keeper — ${_titles[_index]}'), centerTitle: true),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        selectedItemColor: Colors.indigo,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Clock'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
