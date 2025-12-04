// lib/data/app_db.dart
// Unified SQLite database helper with compatibility:
// - AppDatabase.instance() for older DAO-style code
// - AppDb.instance() and AppDb.open() for newer repos

import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'timekeeper.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        // Keep everything defensive with IF NOT EXISTS so we don't
        // crash if the file already has some tables.
        await db.execute('''
          CREATE TABLE IF NOT EXISTS company(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            join_code TEXT,
            created_utc INTEGER
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS device_profile(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id TEXT,
            role TEXT,
            display_name TEXT,
            employee_id INTEGER
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS employee(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            pay_rate_cents INTEGER NOT NULL DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS job(
            id TEXT PRIMARY KEY,
            company_id TEXT,
            name TEXT NOT NULL,
            hourly_rate_cents INTEGER NOT NULL DEFAULT 0
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS job_site(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            radius_m INTEGER
          );
        ''');

        // Basic clock_event table – matches what your models/repos expect:
        await db.execute('''
          CREATE TABLE IF NOT EXISTS clock_event(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employee_id INTEGER NOT NULL,
            company_id TEXT,
            job_site_id INTEGER,
            clock_type TEXT NOT NULL,
            ts_utc INTEGER NOT NULL,
            lat REAL,
            lon REAL,
            source TEXT
          );
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        // Just ensure tables exist for now
        await db.execute('''
          CREATE TABLE IF NOT EXISTS company(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            join_code TEXT,
            created_utc INTEGER
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS device_profile(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id TEXT,
            role TEXT,
            display_name TEXT,
            employee_id INTEGER
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS employee(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            full_name TEXT NOT NULL,
            pay_rate_cents INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS job(
            id TEXT PRIMARY KEY,
            company_id TEXT,
            name TEXT NOT NULL,
            hourly_rate_cents INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS job_site(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            radius_m INTEGER
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS clock_event(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employee_id INTEGER NOT NULL,
            company_id TEXT,
            job_site_id INTEGER,
            clock_type TEXT NOT NULL,
            ts_utc INTEGER NOT NULL,
            lat REAL,
            lon REAL,
            source TEXT
          );
        ''');
      },
    );

    return _db!;
  }
}

// Newer helper name used by repos + services
class AppDb {
  static Future<Database> instance() => AppDatabase.instance();
  static Future<Database> open() => AppDatabase.instance();
}
