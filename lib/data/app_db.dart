// Tobias Cash
// 10/01/2025
// app_db.dart
// sql database singleton class to manage database connection
// uses sqflite (f for flutter?)
// all repositories (repos.dart) call AppDb.open()
//  get access to the same database connection.
// *IF CHANGES ARE NEEDED, CONTACT ME (TOBIAS)*


import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// Singleton wrapper around the app's SQLite database.
class AppDb {
  static Database? _db;

  static Future<Database> open() async {
    if (_db != null) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'timekeeper.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        // Job sites the business defines (for future auto clock-in)
        await db.execute('''
          CREATE TABLE job_site(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            radius_m INTEGER NOT NULL DEFAULT 100
          );
        ''');

        // Minimal employee table (single-employee is fine for class project)
        await db.execute('''
          CREATE TABLE employee(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            pay_rate_cents INTEGER NOT NULL
          );
        ''');

        // Clock events (append-only)
        await db.execute('''
          CREATE TABLE clock_event(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employee_id INTEGER NOT NULL,
            job_site_id INTEGER,
            clock_type TEXT NOT NULL CHECK(clock_type IN ('IN','OUT','AUTO_IN','AUTO_OUT')),
            ts_utc INTEGER NOT NULL,
            lat REAL, lon REAL, source TEXT,
            FOREIGN KEY(employee_id) REFERENCES employee(id),
            FOREIGN KEY(job_site_id) REFERENCES job_site(id)
          );
        ''');
      },
    );

    return _db!;
  }
}
// *IF CHANGES ARE NEEDED, CONTACT TOBIAS!!!)