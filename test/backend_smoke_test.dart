import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Use FFI-backed SQLite for tests (no Android/iOS needed)
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory, databaseFactoryFfi;

import 'package:time_keeper/data/app_db.dart';
import 'package:time_keeper/data/models.dart';
import 'package:time_keeper/data/repos.dart';
import 'package:time_keeper/services/clock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // 1) Initialize sqflite_common_ffi and route sqflite to it.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // 2) Mock the path_provider channel so AppDb can resolve a folder.
    const MethodChannel pathChannel =
    MethodChannel('plugins.flutter.io/path_provider');

    final tempRoot = await Directory.systemTemp.createTemp('tk_tests_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall call) async {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
          return tempRoot.path;
        case 'getTemporaryDirectory':
          return tempRoot.path;
        default:
          return tempRoot.path;
      }
    });
  });

  test('DB + repos + clock service basic flow', () async {
    await AppDb.open(); // creates schema in a temp directory

    final empRepo = EmployeeRepo();
    final clockRepo = ClockRepo();
    final service = ClockService(clockRepo: clockRepo, empRepo: empRepo);

    final empId = await service.ensureDefaultEmployee();

    await service.clockIn(employeeId: empId);
    await Future.delayed(const Duration(milliseconds: 50));
    await service.clockOut(employeeId: empId);

    final last = await clockRepo.lastForEmployee(empId);
    expect(last, isNotNull);
    expect(last!.clockType, ClockType.outMan);
  });
}
