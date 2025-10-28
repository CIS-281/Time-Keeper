// lib/data/app_db.dart
// Tobias Cash — App DB (v2): adds company.manager_pin_* columns

import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;

  static Future<Database> open() async {
    if (_db != null) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'timekeeper.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, _) async {
        // --- core ---
        await db.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            val TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE company(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            company_code TEXT UNIQUE,
            created_utc INTEGER NOT NULL,
            manager_pin_hash TEXT,
            manager_pin_salt TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE device_profile(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id TEXT NOT NULL,
            role TEXT NOT NULL,
            created_utc INTEGER NOT NULL
          );
        ''');

        // --- jobs / sites / employees ---
        await db.execute('''
          CREATE TABLE job_site(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            radius_m INTEGER NOT NULL DEFAULT 100,
            company_id TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE employee(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            pay_rate_cents INTEGER NOT NULL,
            company_id TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE jobs(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            hourly_rate_cents INTEGER NOT NULL,
            late_grace_mins INTEGER NOT NULL,
            allow_auto_clock_in INTEGER NOT NULL,
            job_site_id INTEGER,
            company_id TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE shifts(
            id TEXT PRIMARY KEY,
            employee_id INTEGER NOT NULL,
            job_id TEXT NOT NULL,
            clock_in_utc INTEGER NOT NULL,
            clock_out_utc INTEGER,
            status TEXT NOT NULL,
            avg_accuracy_m REAL,
            company_id TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE clock_event(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employee_id INTEGER NOT NULL,
            job_site_id INTEGER,
            shift_id TEXT,
            clock_type TEXT NOT NULL,
            ts_utc INTEGER NOT NULL,
            lat REAL, lon REAL, source TEXT, accuracy_m REAL,
            company_id TEXT
          );
        ''');

        // A simple view you may already have in your project
        await db.execute('''
          CREATE VIEW IF NOT EXISTS vw_shift_summary AS
          SELECT
            s.id AS shift_id,
            s.employee_id,
            s.job_id,
            j.name AS job_name,
            j.hourly_rate_cents,
            s.clock_in_utc,
            s.clock_out_utc,
            s.status,
            COALESCE((s.clock_out_utc - s.clock_in_utc), 0) AS worked_seconds,
            COALESCE(((s.clock_out_utc - s.clock_in_utc) * j.hourly_rate_cents)/3600, 0) AS earnings_cents,
            s.company_id
          FROM shifts s
          LEFT JOIN jobs j ON j.id = s.job_id;
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          // Add manager PIN fields (best-effort)
          try { await db.execute('ALTER TABLE company ADD COLUMN manager_pin_hash TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE company ADD COLUMN manager_pin_salt TEXT'); } catch (_) {}
        }
      },
    );

    return _db!;
  }
}
