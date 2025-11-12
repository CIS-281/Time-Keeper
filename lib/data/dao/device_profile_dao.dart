import 'package:sqflite/sqflite.dart';
import '../app_db.dart';
import '../models/device_profile.dart';

class DeviceProfileDao {
  Future<DeviceProfile?> getProfile() async {
    final db = await AppDatabase.instance();
    final rows = await db.query('device_profile', where: 'id=1', limit: 1);
    if (rows.isEmpty) return null;
    return DeviceProfile.fromMap(rows.first);
  }

  Future<void> upsert(DeviceProfile p) async {
    final db = await AppDatabase.instance();
    await db.update('device_profile', p.toMap(), where: 'id=1');
  }

  Future<bool> hasMinimum() async {
    final p = await getProfile();
    return p?.isComplete ?? false;
  }
}
