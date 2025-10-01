// Tobias Cash
// 09/30/2025
// Basic Navigation set-up
// This code can be a starting point for further dev.
// The Clock screen allows employees to manually clock IN/OUT.
// Later this will also record GPS coordinates and save events to SQLite.

import 'package:flutter/material.dart';

class ClockScreen extends StatelessWidget {
  const ClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time, size: 96),
          const SizedBox(height: 16),
          const Text('Clock In/Out', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () {/* TODO: call LocationService + save IN */},
                icon: const Icon(Icons.login),
                label: const Text('Clock IN'),
              ),
              ElevatedButton.icon(
                onPressed: () {/* TODO: call LocationService + save OUT */},
                icon: const Icon(Icons.logout),
                label: const Text('Clock OUT'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
