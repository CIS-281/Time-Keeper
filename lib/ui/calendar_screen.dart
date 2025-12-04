// lib/ui/calendar_screen.dart
// Simple calendar-like list: last 30 days with total hours from clock_event.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_keeper/services/clock_service.dart';
import 'package:time_keeper/data/repos.dart';
import 'package:time_keeper/data/models.dart';
import 'package:time_keeper/services/org_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ClockService _clockService = ClockService();
  final ClockRepo _clockRepo = ClockRepo();
  final OrgService _orgService = OrgService();

  bool _loading = true;
  final Map<DateTime, Duration> _perDay = {};
  final _dayFmt = DateFormat('EEE, MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final empId = await _clockService.ensureDefaultEmployee();
      final now = DateTime.now().toUtc();
      final startDate = now.subtract(const Duration(days: 30));
      final startMs = DateTime(startDate.year, startDate.month, startDate.day)
          .millisecondsSinceEpoch;
      final endMs = now.millisecondsSinceEpoch;
      final companyId = await _orgService.activeCompanyId() ?? 'local';

      // Your ClockRepo.inRangeUtc has required named param companyId
      final events = await _clockRepo.inRangeUtc(
        empId,
        startMs,
        endMs,
        companyId: companyId,
      );
      events.sort((a, b) => a.tsUtc.compareTo(b.tsUtc));

      final map = <DateTime, Duration>{};
      ClockEvent? lastIn;

      for (final e in events) {
        final type = e.clockType?.toString() ?? '';
        if (type == 'IN') {
          lastIn = e;
        } else if (type == 'OUT' && lastIn != null) {
          final start = DateTime.fromMillisecondsSinceEpoch(
              lastIn.tsUtc,
              isUtc: true);
          final end = DateTime.fromMillisecondsSinceEpoch(
              e.tsUtc,
              isUtc: true);
          final dur = end.difference(start);
          final dayKey = DateTime(start.year, start.month, start.day);
          map[dayKey] = (map[dayKey] ?? Duration.zero) + dur;
          lastIn = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _perDay
          ..clear()
          ..addAll(map);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final days = _perDay.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (days.isEmpty
          ? const Center(child: Text('No recorded time yet.'))
          : ListView.builder(
        itemCount: days.length,
        itemBuilder: (ctx, i) {
          final d = days[i];
          final dur = _perDay[d] ?? Duration.zero;
          return ListTile(
            leading: const Icon(Icons.today),
            title: Text(_dayFmt.format(d)),
            trailing: Text(_fmtDur(dur)),
          );
        },
      )),
    );
  }
}
