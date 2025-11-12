// lib/services/clock_service.dart
import 'package:time_keeper/data/models.dart';
import 'package:time_keeper/data/repos.dart';

const String kClockIn = 'IN';
const String kClockOut = 'OUT';
const String kClockAutoIn = 'AUTO_IN';
const String kClockAutoOut = 'AUTO_OUT';

class ClockService {
  final EmployeeRepo _employeeRepo = EmployeeRepo();
  final ClockRepo _clockRepo = ClockRepo();

  int _nowUtcSec() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

  Future<int> ensureDefaultEmployee({required String companyId}) async {
    final list = await _employeeRepo.all(companyId);
    if (list.isNotEmpty) return list.first.id!;
    final emp = Employee(fullName: 'Employee', payRateCents: 0);
    await _employeeRepo.upsert(emp, companyId: companyId);
    final created = await _employeeRepo.all(companyId);
    return created.first.id!;
  }

  Future<void> clockIn({
    required int employeeId,
    required String companyId,
    int? jobSiteId,
    String? shiftId,
    bool auto = false,
    double? accuracyM,
  }) async {
    final ev = ClockEvent(
      employeeId: employeeId,
      jobSiteId: jobSiteId,
      shiftId: shiftId,
      clockType: auto ? kClockAutoIn : kClockIn,
      tsUtc: _nowUtcSec(),
      source: 'app',
      accuracyM: accuracyM,
    );
    await _clockRepo.insert(ev, companyId: companyId);
  }

  Future<void> clockOut({
    required int employeeId,
    required String companyId,
    int? jobSiteId,
    String? shiftId,
    bool auto = false,
    double? accuracyM,
  }) async {
    final ev = ClockEvent(
      employeeId: employeeId,
      jobSiteId: jobSiteId,
      shiftId: shiftId,
      clockType: auto ? kClockAutoOut : kClockOut,
      tsUtc: _nowUtcSec(),
      source: 'app',
      accuracyM: accuracyM,
    );
    await _clockRepo.insert(ev, companyId: companyId);
  }

  Future<ClockEvent?> lastEvent(int employeeId, {required String companyId}) =>
      _clockRepo.lastForEmployee(employeeId, companyId: companyId);

  Future<List<ClockEvent>> eventsInRange({
    required int employeeId,
    required int startUtcSec,
    required int endUtcSec,
    required String companyId,
  }) =>
      _clockRepo.inRangeUtc(employeeId, startUtcSec, endUtcSec, companyId: companyId);
}
