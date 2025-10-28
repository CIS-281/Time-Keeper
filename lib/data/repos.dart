// lib/data/repos.dart
import 'package:sqflite/sqflite.dart';
import 'app_db.dart';
import 'models.dart';

/// ---------- job_site ----------
class JobSiteRepo {
  Future<int> upsert(JobSite s, {required String companyId}) async {
    final db = await AppDb.open();
    final data = s.toMap()..['company_id'] = companyId;
    if (s.id == null) return db.insert('job_site', data);
    return db.update('job_site', data, where: 'id=? AND company_id=?', whereArgs: [s.id, companyId]);
  }

  Future<List<JobSite>> all(String companyId) async {
    final db = await AppDb.open();
    final rows = await db.query('job_site', where: 'company_id=?', whereArgs: [companyId], orderBy: 'name');
    return rows.map((e) => JobSite.fromMap(e)).toList();
  }

  Future<int> delete(int id, {required String companyId}) async {
    final db = await AppDb.open();
    return db.delete('job_site', where: 'id=? AND company_id=?', whereArgs: [id, companyId]);
  }
}

/// ---------- employee ----------
class EmployeeRepo {
  Future<int> upsert(Employee e, {required String companyId}) async {
    final db = await AppDb.open();
    final data = e.toMap()..['company_id'] = companyId;
    if (e.id == null) return db.insert('employee', data);
    return db.update('employee', data, where: 'id=? AND company_id=?', whereArgs: [e.id, companyId]);
  }

  Future<List<Employee>> all(String companyId) async {
    final db = await AppDb.open();
    final rows = await db.query('employee', where: 'company_id=?', whereArgs: [companyId], orderBy: 'full_name');
    return rows.map((e) => Employee.fromMap(e)).toList();
  }
}

/// ---------- clock_event ----------
class ClockRepo {
  Future<int> insert(ClockEvent ev, {required String companyId}) async {
    final db = await AppDb.open();
    final data = ev.toMap()..['company_id'] = companyId;
    return db.insert('clock_event', data);
  }

  Future<ClockEvent?> lastForEmployee(int empId, {required String companyId}) async {
    final db = await AppDb.open();
    final rows = await db.query(
      'clock_event',
      where: 'employee_id=? AND company_id=?',
      whereArgs: [empId, companyId],
      orderBy: 'ts_utc DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ClockEvent.fromMap(rows.first);
  }

  Future<List<ClockEvent>> inRangeUtc(int empId, int startUtc, int endUtc, {required String companyId}) async {
    final db = await AppDb.open();
    final rows = await db.query(
      'clock_event',
      where: 'employee_id=? AND ts_utc BETWEEN ? AND ? AND company_id=?',
      whereArgs: [empId, startUtc, endUtc, companyId],
      orderBy: 'ts_utc ASC',
    );
    return rows.map((e) => ClockEvent.fromMap(e)).toList();
  }
}

/// ---------- jobs ----------
class JobRepo {
  Future<void> upsertJob(Job j, {required String companyId}) async {
    final db = await AppDb.open();
    final data = j.toMap()..['company_id'] = companyId;
    await db.insert('jobs', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Job>> getAllJobs(String companyId) async {
    final db = await AppDb.open();
    final rows = await db.query('jobs', where: 'company_id=?', whereArgs: [companyId], orderBy: 'name ASC');
    return rows.map((e) => Job.fromMap(e)).toList();
  }

  Future<Job?> getJob(String id, {required String companyId}) async {
    final db = await AppDb.open();
    final rows = await db.query('jobs', where: 'id=? AND company_id=?', whereArgs: [id, companyId], limit: 1);
    return rows.isEmpty ? null : Job.fromMap(rows.first);
  }

  Future<int> deleteJob(String id, {required String companyId}) async {
    final db = await AppDb.open();
    return db.delete('jobs', where: 'id=? AND company_id=?', whereArgs: [id, companyId]);
  }
}

/// ---------- shifts ----------
class ShiftRepo {
  Future<void> startShift({
    required String shiftId,
    required int employeeId,
    required String jobId,
    required String companyId,
    bool auto = false,
    double? accuracyM,
  }) async {
    final db = await AppDb.open();
    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    await db.insert('shifts', {
      'id': shiftId,
      'employee_id': employeeId,
      'job_id': jobId,
      'clock_in_utc': nowSec,
      'status': auto ? 'auto_clocked_in' : 'clocked_in',
      'avg_accuracy_m': accuracyM,
      'company_id': companyId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert('clock_event', {
      'employee_id': employeeId,
      'shift_id': shiftId,
      'clock_type': auto ? 'AUTO_IN' : 'IN',
      'ts_utc': nowSec,
      'source': 'app',
      'accuracy_m': accuracyM,
      'company_id': companyId,
    });
  }

  Future<void> endShift(String shiftId, {required String companyId, bool auto = false}) async {
    final db = await AppDb.open();
    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    await db.update('shifts', {'clock_out_utc': nowSec, 'status': 'clocked_out'},
        where: 'id=? AND company_id=?', whereArgs: [shiftId, companyId]);

    final s = await db.query('shifts', columns: ['employee_id'], where: 'id=? AND company_id=?', whereArgs: [shiftId, companyId], limit: 1);
    final empId = (s.first['employee_id'] as num).toInt();

    await db.insert('clock_event', {
      'employee_id': empId,
      'shift_id': shiftId,
      'clock_type': auto ? 'AUTO_OUT' : 'OUT',
      'ts_utc': nowSec,
      'source': 'app',
      'company_id': companyId,
    });
  }

  Future<Shift?> currentOpenShift(int employeeId, {required String companyId}) async {
    final db = await AppDb.open();
    final rows = await db.query('shifts',
        where: 'employee_id=? AND clock_out_utc IS NULL AND company_id=?',
        whereArgs: [employeeId, companyId],
        orderBy: 'clock_in_utc DESC',
        limit: 1);
    return rows.isEmpty ? null : Shift.fromMap(rows.first);
  }

  Future<List<Shift>> recentShifts(int employeeId, {required String companyId, int limit = 20}) async {
    final db = await AppDb.open();
    final rows = await db.query('shifts',
        where: 'employee_id=? AND company_id=?',
        whereArgs: [employeeId, companyId],
        orderBy: 'clock_in_utc DESC',
        limit: limit);
    return rows.map((e) => Shift.fromMap(e)).toList();
  }

  Future<List<ShiftSummary>> summariesForEmployee(int employeeId,
      {required String companyId, int? fromUtc, int? toUtc}) async {
    final db = await AppDb.open();
    final where = <String>['employee_id=?', 'company_id=?'];
    final args = <Object>[employeeId, companyId];
    if (fromUtc != null) { where.add('clock_in_utc >= ?'); args.add(fromUtc); }
    if (toUtc != null) { where.add('clock_in_utc <= ?'); args.add(toUtc); }
    final rows = await db.query('vw_shift_summary', where: where.join(' AND '), whereArgs: args, orderBy: 'clock_in_utc DESC');
    return rows.map((e) => ShiftSummary.fromMap(e)).toList();
  }
}
