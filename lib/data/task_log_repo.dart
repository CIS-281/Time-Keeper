// lib/data/task_log_repo.dart
// Tobias Cash
// Tracks per-job "task" sessions (start/end) for each employee.

import 'app_db.dart';

class TaskLogEntry {
  final int? id;
  final int employeeId;
  final String jobId;
  final String taskId;
  final int startUtc;
  final int? endUtc;

  TaskLogEntry({
    this.id,
    required this.employeeId,
    required this.jobId,
    required this.taskId,
    required this.startUtc,
    this.endUtc,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'employee_id': employeeId,
    'job_id': jobId,
    'task_id': taskId,
    'start_utc': startUtc,
    'end_utc': endUtc,
  };

  static TaskLogEntry fromMap(Map<String, Object?> m) => TaskLogEntry(
    id: m['id'] as int?,
    employeeId: m['employee_id'] as int,
    jobId: m['job_id'] as String,
    taskId: m['task_id'] as String,
    startUtc: m['start_utc'] as int,
    endUtc: m['end_utc'] as int?,
  );
}

// simple summary per job / task
class TaskLogSummary {
  final String taskId;
  final Duration total;

  TaskLogSummary({
    required this.taskId,
    required this.total,
  });
}

class TaskLogRepo {
  // Start a new "task" (here: the job itself or a subtask id)
  Future<int> start({
    required int employeeId,
    required String jobId,
    required String taskId,
    int? startUtc,
  }) async {
    final db = await AppDb.open();
    final now = startUtc ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    return db.insert('task_log', {
      'employee_id': employeeId,
      'job_id': jobId,
      'task_id': taskId,
      'start_utc': now,
      'end_utc': null,
    });
  }

  // Close any open task for this employee
  Future<void> closeOpenForEmployee(int employeeId, {int? endUtc}) async {
    final db = await AppDb.open();
    final now = endUtc ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    await db.update(
      'task_log',
      {'end_utc': now},
      where: 'employee_id = ? AND end_utc IS NULL',
      whereArgs: [employeeId],
    );
  }

  // Summaries per job for today (or between startUtc/endUtc)
  Future<List<TaskLogSummary>> summariesForJob({
    required int employeeId,
    required String jobId,
    int? startUtc,
    int? endUtc,
  }) async {
    final db = await AppDb.open();
    final where = StringBuffer(
        'employee_id = ? AND job_id = ? AND end_utc IS NOT NULL');
    final args = <Object>[employeeId, jobId];

    if (startUtc != null) {
      where.write(' AND start_utc >= ?');
      args.add(startUtc);
    }
    if (endUtc != null) {
      where.write(' AND start_utc < ?');
      args.add(endUtc);
    }

    final rows = await db.rawQuery('''
      SELECT task_id,
             SUM(end_utc - start_utc) AS total_ms
      FROM task_log
      WHERE ${where.toString()}
      GROUP BY task_id
    ''', args);

    return rows
        .map((m) => TaskLogSummary(
      taskId: m['task_id'] as String,
      total: Duration(
          milliseconds: (m['total_ms'] as num?)?.toInt() ?? 0),
    ))
        .toList();
  }
}
