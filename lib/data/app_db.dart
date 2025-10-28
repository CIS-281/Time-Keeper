// lib/data/app_db.dart
// v3: add company + device_profile, add company_id columns, indexes, backfill
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;
  static const _dbVersion = 3;

  static Future<Database> open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'timekeeper.db');

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON;'),
      onCreate: (db, _) async {
        // --- org layer ---
        await db.execute('''
          CREATE TABLE company(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            company_code TEXT NOT NULL UNIQUE,
            created_utc INTEGER NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE device_profile(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id TEXT NOT NULL,
            role TEXT NOT NULL CHECK(role IN ('manager','employee')),
            created_utc INTEGER NOT NULL,
            FOREIGN KEY(company_id) REFERENCES company(id)
          );
        ''');

        // ---original tables + v2 additions, already including company_id ---
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
            hourly_rate_cents INTEGER NOT NULL DEFAULT 0,
            late_grace_mins INTEGER NOT NULL DEFAULT 5,
            allow_auto_clock_in INTEGER NOT NULL DEFAULT 0,
            job_site_id INTEGER,
            company_id TEXT,
            FOREIGN KEY(job_site_id) REFERENCES job_site(id) ON DELETE SET NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE shifts(
            id TEXT PRIMARY KEY,
            employee_id INTEGER NOT NULL,
            job_id TEXT NOT NULL,
            clock_in_utc INTEGER NOT NULL,
            clock_out_utc INTEGER,
            status TEXT NOT NULL CHECK(status IN ('clocked_in','auto_clocked_in','on_break','clocked_out')),
            avg_accuracy_m REAL,
            company_id TEXT,
            FOREIGN KEY(employee_id) REFERENCES employee(id),
            FOREIGN KEY(job_id) REFERENCES jobs(id)
          );
        ''');

        await db.execute('''
          CREATE TABLE clock_event(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employee_id INTEGER NOT NULL,
            job_site_id INTEGER,
            clock_type TEXT NOT NULL CHECK(clock_type IN ('IN','OUT','AUTO_IN','AUTO_OUT')),
            ts_utc INTEGER NOT NULL,
            lat REAL, lon REAL, source TEXT,
            shift_id TEXT,
            accuracy_m REAL,
            company_id TEXT,
            FOREIGN KEY(employee_id) REFERENCES employee(id),
            FOREIGN KEY(job_site_id) REFERENCES job_site(id)
          );
        ''');

        // optional
        await db.execute('''
          CREATE TABLE IF NOT EXISTS task(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            assigned_to INTEGER,
            is_complete INTEGER NOT NULL DEFAULT 0,
            due_date INTEGER,
            created_utc INTEGER NOT NULL,
            company_id TEXT
          );
        ''');

        await _createIndexes(db);
        await _createViews(db);
      },
      onUpgrade: (db, oldV, _) async {
        if (oldV < 3) {
          // Org tables
          await db.execute('''
            CREATE TABLE IF NOT EXISTS company(
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              company_code TEXT NOT NULL UNIQUE,
              created_utc INTEGER NOT NULL
            );
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS device_profile(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              company_id TEXT NOT NULL,
              role TEXT NOT NULL CHECK(role IN ('manager','employee')),
              created_utc INTEGER NOT NULL,
              FOREIGN KEY(company_id) REFERENCES company(id)
            );
          ''');

          // Add company_id columns if missing
          for (final t in ['job_site','employee','jobs','shifts','clock_event','task']) {
            try { await db.execute('ALTER TABLE $t ADD COLUMN company_id TEXT;'); } catch (_) {}
          }

          await _createIndexes(db);
          await _createViews(db);
          // Backfill will be done by OrgService when first company is created.
        }
      },
    );

    return _db!;
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_company_code ON company(company_code);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_jobs_company ON jobs(company_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_shifts_company ON shifts(company_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_events_company ON clock_event(company_id);');
  }

  static Future<void> _createViews(Database db) async {
    await db.execute('DROP VIEW IF EXISTS vw_shift_summary;');
    await db.execute('''
      CREATE VIEW vw_shift_summary AS
      SELECT
        s.id AS shift_id,
        s.employee_id,
        s.job_id,
        j.name AS job_name,
        j.hourly_rate_cents,
        s.clock_in_utc,
        s.clock_out_utc,
        s.status,
        CAST((COALESCE(s.clock_out_utc, CAST(strftime('%s','now') AS INTEGER)) - s.clock_in_utc) AS INTEGER) AS worked_seconds,
        CAST(((COALESCE(s.clock_out_utc, CAST(strftime('%s','now') AS INTEGER)) - s.clock_in_utc) * j.hourly_rate_cents) / 3600 AS INTEGER) AS earnings_cents,
        s.company_id
      FROM shifts s
      JOIN jobs j ON j.id = s.job_id;
    ''');
  }
}
