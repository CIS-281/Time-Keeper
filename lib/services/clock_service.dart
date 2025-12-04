// lib/services/clock_service.dart
// Tobias Cash
// Simple clock service for manual IN/OUT and default employee handling.

import 'package:time_keeper/data/app_db.dart';
import 'package:time_keeper/data/models.dart';
import 'package:time_keeper/data/repos.dart';
import 'package:time_keeper/services/org_service.dart';

class ClockService {
  final ClockRepo _clockRepo = ClockRepo();
  final OrgService _orgService = OrgService();

  // Make sure an employee row exists and return its id
  Future<int> ensureDefaultEmployee() async {
    final db = await AppDb.instance();
    final rows = await db.query('employee', limit: 1);
    if (rows.isNotEmpty) {
      return rows.first['id'] as int;
    }
    return db.insert('employee', {
      'full_name': 'Default Employee',
      'pay_rate_cents': 0,
    });
  }

  Future<void> clockIn({
    required int employeeId,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final companyId = await _orgService.activeCompanyId() ?? 'local';

    await _clockRepo.insert(
      ClockEvent(
        employeeId: employeeId,
        companyId: companyId,
        jobSiteId: null,
        // use simple string for type; your table uses TEXT
        clockType: 'IN',
        tsUtc: now,
        lat: null,
        lon: null,
        source: 'manual',
      ),
      companyId: companyId,
    );
  }

  Future<void> clockOut({
    required int employeeId,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final companyId = await _orgService.activeCompanyId() ?? 'local';

    await _clockRepo.insert(
      ClockEvent(
        employeeId: employeeId,
        companyId: companyId,
        jobSiteId: null,
        clockType: 'OUT',
        tsUtc: now,
        lat: null,
        lon: null,
        source: 'manual',
      ),
      companyId: companyId,
    );
  }
}
