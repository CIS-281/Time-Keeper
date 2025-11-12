// Tobias Cash
// 10/01/2025 (first created)
// if changes are needed, only on working-branch. If support or advice needed,
// contact Tobias!
// This is where we want to expand on. Whole payroll service possible!!

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models.dart';
import '../data/repos.dart';

/// Produces a CSV of daily totals for a given employee within a UTC date range.
class PayrollExportService {
  final ClockRepo _clockRepo;
  PayrollExportService({ClockRepo? repo}) : _clockRepo = repo ?? ClockRepo();

  Future<String> exportDailyTotals({
    required int employeeId,
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final fmt = DateFormat('yyyy-MM-dd');
    final start = fromUtc.millisecondsSinceEpoch;
    final end = toUtc.millisecondsSinceEpoch;
    final events = await _clockRepo.inRangeUtc(employeeId, start, end);

    // Pair IN/OUT in order, accumulate hours per day.
    final byDay = <String, double>{};
    int? openIn;
    for (final e in events) {
      if (e.clockType == ClockType.inMan || e.clockType == ClockType.inAuto) {
        openIn = e.tsUtc;
      } else if ((e.clockType == ClockType.outMan || e.clockType == ClockType.outAuto) && openIn != null) {
        final inDt = DateTime.fromMillisecondsSinceEpoch(openIn, isUtc: true);
        final outDt = DateTime.fromMillisecondsSinceEpoch(e.tsUtc, isUtc: true);
        final hrs = outDt.difference(inDt).inMinutes / 60.0;
        byDay.update(fmt.format(inDt), (v) => v + hrs, ifAbsent: () => hrs);
        openIn = null;
      }
    }

    final rows = <List<dynamic>>[
      ['Date', 'EmployeeId', 'Hours'],
      ...byDay.entries.map((e) => [e.key, employeeId, e.value.toStringAsFixed(2)]),
    ];
    final csv = const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/payroll_${employeeId}_${fmt.format(fromUtc)}_${fmt.format(toUtc)}.csv');
    await file.writeAsString(csv);
    return file.path;
  }
}
