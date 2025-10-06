// Tobias Cash
// 09/30/2025
// Basic Navigation set-up
// This code can be a starting point for further dev.
// The Clock screen allows employees to manually clock IN/OUT.
// Later this will also record GPS coordinates and save events to SQLite.

import 'package:flutter/material.dart';
import 'package:time_keeper/services/clock_service.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  final ClockService _clockService = ClockService();
  String _status = "No action yet";

  Future<void> _handleClockIn() async {
    final empId = await _clockService.ensureDefaultEmployee();
    await _clockService.clockIn(employeeId: empId);
    setState(() {
      _status = "Clocked IN at ${DateTime.now()}";
    });
  }

  Future<void> _handleClockOut() async {
    final empId = await _clockService.ensureDefaultEmployee();
    await _clockService.clockOut(employeeId: empId);
    setState(() {
      _status = "Clocked OUT at ${DateTime.now()}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, size: 96),
            const SizedBox(height: 16),
            const Text(
              'Clock In/Out',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _handleClockIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Clock IN'),
                ),
                ElevatedButton.icon(
                  onPressed: _handleClockOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Clock OUT'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(_status, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
