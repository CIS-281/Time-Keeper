// Tobias Cash
// 10/01/2025 (first created)
// if changes are needed, only on working-branch. If support or advice needed,
// contact Tobias!

import 'package:sqflite/sqflite.dart';
import 'app_db.dart';
import 'models.dart';

/// CRUD for job_site
class JobSiteRepo {
  Future<int> upsert(JobSite s) async {
    final db = await AppDb.open();
    if (s.id == null) return db.insert('job_site', s.toMap());
    return db.update('job_site', s.toMap(), where: 'id=?', whereArgs: [s.id]);
  }

  Future<List<JobSite>> all() async {
    final db = await AppDb.open();
    final rows = await db.query('job_site', orderBy: 'name');
    return rows.map((e) => JobSite.fromMap(e)).toList();
  }

  Future<int> delete(int id) async {
    final db = await AppDb.open();
    return db.delete('job_site', where: 'id=?', whereArgs: [id]);
  }
}

/// CRUD for employee
class EmployeeRepo {
  Future<int> upsert(Employee e) async {
    final db = await AppDb.open();
    if (e.id == null) return db.insert('employee', e.toMap());
    return db.update('employee', e.toMap(), where: 'id=?', whereArgs: [e.id]);
  }

  Future<List<Employee>> all() async {
    final db = await AppDb.open();
    final rows = await db.query('employee', orderBy: 'full_name');
    return rows.map((e) => Employee.fromMap(e)).toList();
  }
}

/// Append-only repo for clock_event
class ClockRepo {
  Future<int> insert(ClockEvent ev) async {
    final db = await AppDb.open();
    return db.insert('clock_event', ev.toMap());
  }

  Future<ClockEvent?> lastForEmployee(int empId) async {
    final db = await AppDb.open();
    final rows = await db.query(
      'clock_event',
      where: 'employee_id=?',
      whereArgs: [empId],
      orderBy: 'ts_utc DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ClockEvent.fromMap(rows.first);
  }

  Future<List<ClockEvent>> inRangeUtc(int empId, int startUtc, int endUtc) async {
    final db = await AppDb.open();
    final rows = await db.query(
      'clock_event',
      where: 'employee_id=? AND ts_utc BETWEEN ? AND ?',
      whereArgs: [empId, startUtc, endUtc],
      orderBy: 'ts_utc ASC',
    );
    return rows.map((e) => ClockEvent.fromMap(e)).toList();
  }
}
