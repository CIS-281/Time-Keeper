// Tobias Cash
// 09/30/2025
// First setup for basic main file. This first setup generates a clean homescreen.

import 'package:flutter/material.dart';

void main() {
  runApp(const TimeKeeperApp());
}

class TimeKeeperApp extends StatelessWidget {
  const TimeKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Keeper',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⏱️ Time Keeper'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.access_time, size: 100, color: Colors.indigo),
            SizedBox(height: 20),
            Text(
              'Welcome to Time Keeper!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Track jobs, clock in/out, and view schedules here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
