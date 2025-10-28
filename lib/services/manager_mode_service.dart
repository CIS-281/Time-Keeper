// lib/services/manager_mode_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:time_keeper/data/app_db.dart';
import 'package:time_keeper/services/org_service.dart';

/// Manager Mode state per device (enabled/disabled),
/// while the PIN itself is company-wide (stored in company table).
class ManagerModeService {
  final String companyId;
  ManagerModeService(this.companyId);

  final _org = OrgService();

  String get _key => 'mgr_enabled::$companyId';

  Future<void> setEnabled(bool v) async {
    final db = await AppDb.open();
    await db.insert('settings', {'key': _key, 'val': v ? '1' : '0'},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isEnabled() async {
    final db = await AppDb.open();
    final r = await db.query('settings', where: 'key=?', whereArgs: [_key], limit: 1);
    return r.isNotEmpty && r.first['val'] == '1';
  }

  /// Checks the company-wide PIN and enables if valid.
  Future<bool> unlockWithPin(String pin) async {
    final ok = await _org.verifyManagerPin(companyId, pin);
    if (ok) await setEnabled(true);
    return ok;
  }
}
