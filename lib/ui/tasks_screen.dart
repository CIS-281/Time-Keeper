// lib/ui/tasks_screen.dart
// Tasks / Jobs screen
// - Lists jobs visible for this device (via JobService)
// - Big "Create Job / Task" button at the top
// - Uses JobRepo to write to the DB

import 'package:flutter/material.dart';
import 'package:time_keeper/services/job_service.dart';
import 'package:time_keeper/data/job_repo.dart';
import 'package:time_keeper/services/org_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final JobService _jobs = JobService();
  final JobRepo _repo = JobRepo();
  final OrgService _org = OrgService();

  bool _loading = true;
  List<JobRow> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _jobs.visibleJobsForDevice();
      if (!mounted) return;
      setState(() {
        _items = rows;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateJobDialog() async {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Job / Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Job name',
              ),
            ),
            TextField(
              controller: rateCtrl,
              decoration: const InputDecoration(
                labelText: 'Hourly rate (e.g. 25.50)',
              ),
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    final rateStr = rateCtrl.text.trim();
    double rate = 0;
    if (rateStr.isNotEmpty) {
      rate = double.tryParse(rateStr) ?? 0;
    }
    final rateCents = (rate * 100).round();

    final companyId = await _org.activeCompanyId() ?? 'local';

    final job = JobRow(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}', // simple unique id
      companyId: companyId,
      name: name,
      hourlyRateCents: rateCents,
    );

    await _repo.upsert(job);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks / Jobs'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Top create button (like before)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openCreateJobDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Job / Task'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('No jobs yet.'))
                  : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final j = _items[i];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading:
                      const Icon(Icons.work_outline),
                      title: Text(j.name),
                      subtitle: Text(
                        'Rate: \$${(j.hourlyRateCents / 100).toStringAsFixed(2)}',
                      ),
                      // trailing: IconButton(
                      //   icon: const Icon(Icons.more_vert),
                      //   onPressed: () {
                      //     // later: edit/delete per job
                      //   },
                      // ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // If you liked the FAB as well, you can keep it:
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _openCreateJobDialog,
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
