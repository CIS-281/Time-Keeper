// Tobias Cash
// 09/30/2025
// Basic entry template for the program. this is only the main.dart so please keep
// this file simple and use OOP.

import 'package:flutter/material.dart';

// UI screens
import 'ui/clock_screen.dart';
import 'ui/tasks_screen.dart';
import 'ui/calendar_screen.dart';
import 'ui/settings_screen.dart';

/// App entrypoint
void main() => runApp(const TimeKeeperApp());

/// Root widget: sets theme + home shell
class TimeKeeperApp extends StatelessWidget {
  const TimeKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Keeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}

/// Bottom-navigation container for the main sections.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Titles for the AppBar
  static const _titles = ['Clock', 'Tasks', 'Calendar', 'Settings'];

  // Pages shown for each tab
  final List<Widget> _pages = const [
    ClockScreen(),
    TasksScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  void _onTap(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Time Keeper — ${_titles[_index]}'),
        centerTitle: true,
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Clock',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
