// lib/ui/clock_screen.dart
// Clock screen with:
// - live timer
// - manual Clock IN / Break / Clock OUT
// - job picker (jobs from JobService)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:time_keeper/services/clock_service.dart';
import 'package:time_keeper/data/models.dart';
import 'package:time_keeper/data/repos.dart';
import 'package:time_keeper/services/job_service.dart';
import 'package:time_keeper/data/job_repo.dart';
import 'package:time_keeper/services/org_service.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  // Backend
  final ClockService _clockService = ClockService();
  final ClockRepo _clockRepo = ClockRepo();
  final JobService _jobService = JobService();
  final OrgService _orgService = OrgService();

  // Timer state
  Timer? _ticker;
  bool _isClockedIn = false;
  bool _onBreak = false;

  // UTC millisecond timestamps
  int? _clockStartMsUtc;      // when the shift started
  int? _lastResumeMsUtc;      // last resume moment (after break or at start)
  int _workedMs = 0;          // accumulated ms excluding current running segment

  // Recent events (for the list)
  List<ClockEvent> _recent = [];

  // UI status text
  String _statusText = 'Not clocked in';

  // Job selection
  List<JobRow> _jobs = [];
  JobRow? _selectedJob;

  // Notifications
  final FlutterLocalNotificationsPlugin _notifier =
  FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'clock_channel',
    'Clock Timer',
    description: 'Shows live elapsed time while clocked in.',
    importance: Importance.low, // low keeps it quiet but persistent
  );
  static const int _notifId = 101;

  // Formatting
  final DateFormat _listFmt = DateFormat('MMM d, y – h:mm a');
  String _fmtElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Duration get _elapsed {
    if (!_isClockedIn || _clockStartMsUtc == null) return Duration.zero;
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final runningMs =
    _onBreak ? 0 : nowMs - (_lastResumeMsUtc ?? nowMs);
    return Duration(milliseconds: _workedMs + runningMs);
  }

  // ---- Lifecycle ----
  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadRecentEvents(); // show history on open
    _loadJobs();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ---- Notifications ----
  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifier.initialize(initSettings);

    // Create channel (Android 8+)
    await _notifier
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _showOrUpdateNotification() async {
    final body = _onBreak
        ? 'On Break – ${_fmtElapsed(_elapsed)}'
        : 'Clocked In – ${_fmtElapsed(_elapsed)}';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        ongoing: true,
        showWhen: false,
        onlyAlertOnce: true,
        category: AndroidNotificationCategory.progress,
        styleInformation: const DefaultStyleInformation(true, true),
        importance: Importance.low,
        priority: Priority.low,
      ),
    );

    await _notifier.show(
      _notifId,
      'Time Keeper',
      body,
      details,
    );
  }

  Future<void> _cancelNotification() async {
    await _notifier.cancel(_notifId);
  }

  // ---- Data ----
  Future<void> _loadRecentEvents() async {
    try {
      final empId = await _clockService.ensureDefaultEmployee();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final companyId = await _orgService.activeCompanyId() ?? 'local';

      // Your ClockRepo.inRangeUtc has required named param companyId
      final events = await _clockRepo.inRangeUtc(
        empId,
        0,
        now,
        companyId: companyId,
      );

      // Most recent first, take 4
      events.sort((a, b) => b.tsUtc.compareTo(a.tsUtc));
      setState(() {
        _recent = events.take(4).toList();
      });
    } catch (_) {
      // ignore safely
    }
  }

  Future<void> _loadJobs() async {
    try {
      final jobs = await _jobService.visibleJobsForDevice();
      setState(() {
        _jobs = jobs;
        if (_jobs.isNotEmpty && _selectedJob == null) {
          _selectedJob = _jobs.first;
        }
      });
    } catch (_) {
      // ignore for now
    }
  }

  // ---- Actions ----
  Future<void> _handleClockIn() async {
    if (_isClockedIn) return;
    final empId = await _clockService.ensureDefaultEmployee();
    await _clockService.clockIn(employeeId: empId);

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    setState(() {
      _isClockedIn = true;
      _onBreak = false;
      _clockStartMsUtc = nowMs;
      _lastResumeMsUtc = nowMs;
      _workedMs = 0;
      _statusText = 'Clocked IN';
    });

    // Start ticker + first notification
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isClockedIn) return;
      setState(() {}); // refresh elapsed
      _showOrUpdateNotification();
    });
    await _showOrUpdateNotification();
    await _loadRecentEvents();
  }

  Future<void> _handleBreak() async {
    if (!_isClockedIn) return;

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (!_onBreak) {
      // Going ON break: freeze elapsed and mark break
      if (_lastResumeMsUtc != null) {
        _workedMs += nowMs - _lastResumeMsUtc!;
      }
      setState(() {
        _onBreak = true;
        _statusText = 'On Break';
      });
    } else {
      // Resuming FROM break
      setState(() {
        _onBreak = false;
        _lastResumeMsUtc = nowMs;
        _statusText = 'Resumed';
      });
    }

    await _showOrUpdateNotification();
    await _loadRecentEvents();
  }

  Future<void> _handleClockOut() async {
    if (!_isClockedIn) return;
    final empId = await _clockService.ensureDefaultEmployee();

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (!_onBreak && _lastResumeMsUtc != null) {
      _workedMs += nowMs - _lastResumeMsUtc!;
    }

    await _clockService.clockOut(employeeId: empId);

    setState(() {
      _isClockedIn = false;
      _onBreak = false;
      _statusText = 'Clocked OUT';
    });

    _ticker?.cancel();
    await _cancelNotification();
    await _loadRecentEvents();
  }

  void _selectJobDialog() async {
    if (_jobs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No jobs yet. Create one in Tasks.')),
      );
      return;
    }

    final choice = await showModalBottomSheet<JobRow>(
      context: context,
      builder: (ctx) => ListView(
        children: _jobs
            .map((j) => ListTile(
          title: Text(j.name),
          subtitle: Text(
              'Rate: \$${(j.hourlyRateCents / 100).toStringAsFixed(2)}'),
          onTap: () => Navigator.of(ctx).pop(j),
        ))
            .toList(),
      ),
    );

    if (choice != null) {
      setState(() {
        _selectedJob = choice;
      });
    }
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    final headline = Theme.of(context).textTheme.displaySmall;
    final sub = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 88),
                const SizedBox(height: 12),
                Text(
                  _fmtElapsed(_elapsed),
                  style: headline?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(_statusText, style: sub),
                const SizedBox(height: 18),

                // Job picker (for now just UI – logging per-job can be added later)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.work_outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedJob?.name ?? 'No job selected',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _selectJobDialog,
                      child: const Text('Select Job'),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isClockedIn ? null : _handleClockIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Clock IN'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isClockedIn ? _handleBreak : null,
                      icon: Icon(_onBreak ? Icons.play_arrow : Icons.pause),
                      label: Text(_onBreak ? 'Resume' : 'Break'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isClockedIn ? _handleClockOut : null,
                      icon: const Icon(Icons.logout),
                      label: const Text('Clock OUT'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Last 4 events',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),

                // Recent list
                Expanded(
                  child: ListView(
                    children: _recent.map((e) {
                      final dt = DateTime.fromMillisecondsSinceEpoch(
                          e.tsUtc,
                          isUtc: true)
                          .toLocal();
                      final when = _listFmt.format(dt);

                      // clockType is probably a String in your model
                      final type = e.clockType?.toString() ?? '';
                      String label;
                      if (type == 'IN') {
                        label = 'Clock IN';
                      } else if (type == 'OUT') {
                        label = 'Clock OUT';
                      } else {
                        label = type;
                      }

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.history),
                        title: Text(label),
                        subtitle: Text(when),
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
