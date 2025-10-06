// Tobias Cash
// 10/01/2025
// No changes unless confirmed with team! Always test in work branch before!
// Can mess up GPS API!!!!

import 'package:geolocator/geolocator.dart';
import '../data/models.dart';
import '../data/repos.dart';

/// Service for manual clock IN/OUT with optional GPS capture.
class ClockService {
  final ClockRepo _clockRepo;
  final EmployeeRepo _empRepo;

  ClockService({ClockRepo? clockRepo, EmployeeRepo? empRepo})
      : _clockRepo = clockRepo ?? ClockRepo(),
        _empRepo = empRepo ?? EmployeeRepo();

  /// Creates a default employee if DB is empty. Return its id.
  Future<int> ensureDefaultEmployee() async {
    final list = await _empRepo.all();
    if (list.isEmpty) {
      final id = await _empRepo.upsert(
        Employee(fullName: 'Default Employee', payRateCents: 2000),
      );
      return id;
    }
    return list.first.id ?? 1;
  }

  /// Trys to get a GPS position. Returns null on denied/offline.
  Future<Position?> _tryGetPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> clockIn({required int employeeId}) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final pos = await _tryGetPosition();
    await _clockRepo.insert(ClockEvent(
      employeeId: employeeId,
      clockType: ClockType.inMan,
      tsUtc: now,
      lat: pos?.latitude,
      lon: pos?.longitude,
      source: pos == null ? 'manual' : 'manual+gps',
    ));
  }

  Future<void> clockOut({required int employeeId}) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final pos = await _tryGetPosition();
    await _clockRepo.insert(ClockEvent(
      employeeId: employeeId,
      clockType: ClockType.outMan,
      tsUtc: now,
      lat: pos?.latitude,
      lon: pos?.longitude,
      source: pos == null ? 'manual' : 'manual+gps',
    ));
  }
}
