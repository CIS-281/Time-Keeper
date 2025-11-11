import '../dao/device_profile_dao.dart';
import '../models/device_profile.dart';

class DeviceProfileRepository {
  final _dao = DeviceProfileDao();

  Future<DeviceProfile?> get() => _dao.getProfile();
  Future<void> save(DeviceProfile p) => _dao.upsert(p);
  Future<bool> exists() => _dao.hasMinimum();
}
