// lib/data/app_db.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class _DbCore {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'timekeeper.db');

    _db = await openDatabase(
      path,
      version: 5, // bump to force onUpgrade to run once
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, v) async {
        await _createCore(db);
        await _createCompanyTables(db);
        await _createDomainTables(db);
        await _createViews(db);
        await _createIndexes(db);
      },
      onUpgrade: (db, oldV, newV) async {
        // Create any missing tables/views without dropping user data
        await _createCore(db);
        await _createCompanyTables(db);
        await _createDomainTables(db);
        await _createViews(db);
        await _createIndexes(db);
      },
    );
    return _db!;
  }

  static Future<void> _createCore(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings(
        key TEXT PRIMARY KEY,
        val TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS device_profile(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        full_name   TEXT,
        email       TEXT,
        phone       TEXT,
        role        TEXT,
        avatar_path TEXT,
        device_label TEXT
      );
    ''');

    // Ensure 'created_at' column exists safely
    try {
      await db.execute('ALTER TABLE device_profile ADD COLUMN created_at INTEGER');
    } catch (_) {
      // Column already exists, ignore
    }

    // Ensure a single row exists
    await db.insert(
      'device_profile',
      {'id': 1, 'created_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<void> _createCompanyTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS company(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        company_code TEXT UNIQUE,
        created_utc INTEGER NOT NULL,
        manager_pin_hash TEXT,
        manager_pin_salt TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS device_company(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id TEXT NOT NULL UNIQUE,
        role TEXT NOT NULL,
        created_utc INTEGER NOT NULL
      );
    ''');
  }

  static Future<void> _createDomainTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS job_site(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_m INTEGER NOT NULL,
        company_id TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS employee(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        pay_rate_cents INTEGER NOT NULL DEFAULT 0,
        company_id TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS jobs(
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
      CREATE TABLE IF NOT EXISTS shifts(
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
      CREATE TABLE IF NOT EXISTS clock_event(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER NOT NULL,
        job_site_id INTEGER,
        clock_type TEXT NOT NULL,
        ts_utc INTEGER NOT NULL,
        lat REAL,
        lon REAL,
        source TEXT,
        shift_id TEXT,
        accuracy_m REAL,
        company_id TEXT
      );
    ''');

    // ===== TASKS & SUBTASKS =====
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT,
        client_job TEXT,
        recurrence TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS subtask(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(task_id) REFERENCES task(id) ON DELETE CASCADE
      );
    ''');
  }

  static Future<void> _createViews(Database db) async {
    await db.execute('DROP VIEW IF EXISTS vw_shift_summary');

    await db.execute('''
      CREATE VIEW vw_shift_summary AS
      SELECT 
        s.id AS shift_id,
        s.employee_id AS employee_id,
        s.job_id AS job_id,
        j.name AS job_name,
        j.hourly_rate_cents AS hourly_rate_cents,
        s.clock_in_utc AS clock_in_utc,
        s.clock_out_utc AS clock_out_utc,
        s.status AS status,
        s.company_id AS company_id,
        CASE 
          WHEN s.clock_out_utc IS NULL THEN 0
          ELSE (s.clock_out_utc - s.clock_in_utc)
        END AS worked_seconds,
        CASE 
          WHEN s.clock_out_utc IS NULL THEN 0
          ELSE CAST(ROUND(((s.clock_out_utc - s.clock_in_utc) / 3600.0) * j.hourly_rate_cents) AS INTEGER)
        END AS earnings_cents
      FROM shifts s
      JOIN jobs j ON j.id = s.job_id
    ''');
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_clock_event_emp_ts ON clock_event(employee_id, ts_utc)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_shifts_emp_in ON shifts(employee_id, clock_in_utc)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_jobs_company ON jobs(company_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_job_site_company ON job_site(company_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_employee_company ON employee(company_id)');
  }
}

/// New name used by newer code
class AppDatabase {
  static Future<Database> instance() => _DbCore.instance();
}

/// Backward-compat shim used across the codebase
class AppDb {
  static Future<Database> instance() => _DbCore.instance();
  static Future<Database> open() => _DbCore.instance(); // legacy alias
}