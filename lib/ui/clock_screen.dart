// lib/ui/clock_screen.dart
// Tobias Cash
// 09/30/2025 (company-aware v4)
// Clock screen: live timer, notifications, recent events,
// + Jobs/Shifts with correct employee + company context.
// - Auto-selects job if there's only one
// - Prompts if no job selected
// - Boots into FirstRunWizard if no company is active

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

import 'package:time_keeper/data/repos.dart';
import 'package:time_keeper/data/models.dart';
import 'package:time_keeper/services/clock_service.dart';
import 'package:time_keeper/services/org_service.dart';
import 'package:time_keeper/ui/onboarding/first_run_wizard.dart';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  // Services / repos
  final _org = OrgService();
  final ClockService _clockService = ClockService();
  final ClockRepo _clockRepo = ClockRepo();
  final JobRepo _jobRepo = JobRepo();
  final ShiftRepo _shiftRepo = ShiftRepo();

  // Context
  String? _companyId;
  int? _employeeId;

  // Timer state
  Timer? _ticker;
  bool _isClockedIn = false;
  bool _onBreak = false;

  // UTC ms timestamps for UI timer
  int? _clockStartMsUtc;
  int? _lastResumeMsUtc;
  int _workedMs = 0;

  // Data
  List<Job> _jobs = [];
  Job? _selectedJob;
  Shift? _activeShift;
  List<ClockEvent> _recent = [];

  // UI
  String _statusText = 'Not clocked in';
  bool _loading = true;

  // Notifications
  final FlutterLocalNotificationsPlugin _notifier =
  FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'clock_channel',
    'Clock Timer',
    description: 'Shows live elapsed time while clocked in.',
    importance: Importance.low,
  );
  static const int _notifId = 101;

  // Formatting helpers
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
    final runningMs = _onBreak ? 0 : nowMs - (_lastResumeMsUtc ?? nowMs);
    return Duration(milliseconds: _workedMs + runningMs);
  }

  // ---------------- lifecycle ----------------
  @override
  void initState() {
    super.initState();
    _initNotifications();
    // defer _loadState until after first frame so we can navigate if needed
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadState());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ---------------- init helpers ----------------
  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifier.initialize(initSettings);
    await _notifier
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _loadState() async {
    setState(() => _loading = true);

    // 1) Company context
    final comp = await _org.activeCompanyId();
    if (comp == null) {
      if (!mounted) return;
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const FirstRunWizard()),
      );
      if (!mounted) return;
      // After wizard, try again
      if (ok == true) {
        await _loadState();
        return;
      }
      setState(() => _loading = false);
      return;
    }
    _companyId = comp;

    // 2) Employee + jobs + open shift
    final empId =
    await _clockService.ensureDefaultEmployee(companyId: _companyId!);
    _employeeId = empId;

    final jobs = await _jobRepo.getAllJobs(_companyId!);
    final open = await _shiftRepo.currentOpenShift(empId, companyId: _companyId!);

    // 3) Timer state from open shift (if any)
    if (open != null) {
      final startMs = open.clockInUtc * 1000;
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      _isClockedIn = true;
      _onBreak = false;
      _clockStartMsUtc = startMs;
      _lastResumeMsUtc = nowMs; // resume now for timer
      _workedMs = nowMs - startMs;
      _statusText = 'Clocked IN';
      _startTicker();
      await _showOrUpdateNotification();
    } else {
      _isClockedIn = false;
      _onBreak = false;
      _clockStartMsUtc = null;
      _lastResumeMsUtc = null;
      _workedMs = 0;
      _statusText = 'Not clocked in';
      _ticker?.cancel();
      await _cancelNotification();
    }

    await _loadRecentEvents();

    setState(() {
      _jobs = jobs;
      _activeShift = open;
      _loading = false;
    });

    // 4) Auto-select job if only one
    await _ensureJobAvailableAndSelect();
  }

  Future<void> _ensureJobAvailableAndSelect() async {
    if (_jobs.isEmpty) return; // manager can create one; we don't auto-create here
    if (_selectedJob == null && _jobs.length == 1) {
      setState(() => _selectedJob = _jobs.first);
    }
  }

  void _requireJobOrToast() {
    if (_selectedJob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job to Clock IN.')),
      );
    }
  }

  // ---------------- actions ----------------
  Future<void> _handleClockIn() async {
    if (_isClockedIn) return;
    if (_employeeId == null || _companyId == null) return;
    if (_selectedJob == null) {
      _requireJobOrToast();
      return;
    }

    final shiftId = const Uuid().v4();
    await _shiftRepo.startShift(
      shiftId: shiftId,
      employeeId: _employeeId!,
      jobId: _selectedJob!.id,
      companyId: _companyId!,
    );

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    setState(() {
      _isClockedIn = true;
      _onBreak = false;
      _clockStartMsUtc = nowMs;
      _lastResumeMsUtc = nowMs;
      _workedMs = 0;
      _statusText = 'Clocked IN to ${_selectedJob!.name}';
      _activeShift = Shift(
        id: shiftId,
        employeeId: _employeeId!,
        jobId: _selectedJob!.id,
        clockInUtc: nowMs ~/ 1000,
        status: 'clocked_in',
        avgAccuracyM: null,
        companyId: _companyId!,
      );
    });

    _startTicker();
    await _showOrUpdateNotification();
    await _loadRecentEvents();
  }

  Future<void> _handleClockOut() async {
    if (!_isClockedIn || _activeShift == null || _companyId == null) return;

    await _shiftRepo.endShift(_activeShift!.id, companyId: _companyId!);

    setState(() {
      _isClockedIn = false;
      _onBreak = false;
      _statusText = 'Clocked OUT';
      _activeShift = null;
    });

    _ticker?.cancel();
    await _cancelNotification();
    await _loadRecentEvents();
  }

  Future<void> _handleBreak() async {
    if (!_isClockedIn) return;

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    if (!_onBreak) {
      if (_lastResumeMsUtc != null) _workedMs += nowMs - _lastResumeMsUtc!;
      setState(() {
        _onBreak = true;
        _statusText = 'On Break';
      });
    } else {
      setState(() {
        _onBreak = false;
        _lastResumeMsUtc = nowMs;
        _statusText = 'Resumed';
      });
    }

    await _showOrUpdateNotification();
    await _loadRecentEvents();
  }

  // ---------------- notifications/timer ----------------
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isClockedIn) return;
      setState(() {});
      _showOrUpdateNotification();
    });
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
        importance: Importance.low,
        priority: Priority.low,
      ),
    );
    await _notifier.show(_notifId, 'Time Keeper', body, details);
  }

  Future<void> _cancelNotification() async {
    await _notifier.cancel(_notifId);
  }

  // ---------------- history ----------------
  Future<void> _loadRecentEvents() async {
    if (_employeeId == null || _companyId == null) return;
    try {
      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final events = await _clockRepo.inRangeUtc(
        _employeeId!,
        0,
        nowSec,
        companyId: _companyId!,
      );
      events.sort((a, b) => b.tsUtc.compareTo(a.tsUtc));
      setState(() => _recent = events.take(12).toList());
    } catch (_) {}
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (_loading || _employeeId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final headline =
        Theme.of(context).textTheme.displaySmall ?? const TextStyle(fontSize: 40);
    final sub = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('Clock In / Out')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Icon(Icons.access_time, size: 88),
                const SizedBox(height: 12),
                Text(
                  _fmtElapsed(_elapsed),
                  style: headline.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(_statusText, style: sub),
                const SizedBox(height: 18),

                // Job selector (only show when not clocked in)
                if (!_isClockedIn) ...[
                  DropdownButtonFormField<Job>(
                    value: _selectedJob,
                    hint: const Text('Select Job'),
                    items: _jobs
                        .map((j) =>
                        DropdownMenuItem(value: j, child: Text(j.name)))
                        .toList(),
                    onChanged: (job) => setState(() => _selectedJob = job),
                  ),
                  const SizedBox(height: 12),
                ],

                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isClockedIn
                          ? null
                          : () async {
                        if (_selectedJob == null) {
                          _requireJobOrToast();
                          return;
                        }
                        await _handleClockIn();
                      },
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
                    'Recent events',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView(
                    children: _recent.map((e) {
                      final dt = DateTime.fromMillisecondsSinceEpoch(
                        e.tsUtc * 1000,
                        isUtc: true,
                      ).toLocal();
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.history),
                        title: Text(e.clockType),
                        subtitle: Text(_listFmt.format(dt)),
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
