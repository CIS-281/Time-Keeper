// lib/data/job_repo.dart
// Simple job table wrapper used by JobService and UI.

import 'package:time_keeper/data/app_db.dart';

class JobRow {
  final String id;
  final String? companyId;
  final String name;
  final int hourlyRateCents;

  JobRow({
    required this.id,
    required this.name,
    this.companyId,
    required this.hourlyRateCents,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'company_id': companyId,
    'name': name,
    'hourly_rate_cents': hourlyRateCents,
  };

  static JobRow fromMap(Map<String, Object?> m) => JobRow(
    id: m['id'] as String,
    companyId: m['company_id'] as String?,
    name: m['name'] as String,
    hourlyRateCents: (m['hourly_rate_cents'] as int?) ?? 0,
  );
}

class JobRepo {
  Future<List<JobRow>> forCompany(String? companyId) async {
    final db = await AppDb.instance();
    late List<Map<String, Object?>> rows;
    if (companyId == null) {
      rows = await db.query('job', orderBy: 'name');
    } else {
      rows = await db.query(
        'job',
        where: 'company_id = ?',
        whereArgs: [companyId],
        orderBy: 'name',
      );
    }
    return rows.map((e) => JobRow.fromMap(e)).toList();
  }

  Future<int> upsert(JobRow j) async {
    final db = await AppDb.instance();
    // if row exists, update; else insert
    final existing = await db.query(
      'job',
      where: 'id = ?',
      whereArgs: [j.id],
      limit: 1,
    );
    if (existing.isEmpty) {
      return db.insert('job', j.toMap());
    } else {
      return db.update(
        'job',
        j.toMap(),
        where: 'id = ?',
        whereArgs: [j.id],
      );
    }
  }

  Future<int> delete(String id) async {
    final db = await AppDb.instance();
    return db.delete('job', where: 'id = ?', whereArgs: [id]);
  }
}
