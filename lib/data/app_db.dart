import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Internal singleton implementing the database open/migrations.
/// Exposed by both [AppDatabase] and [AppDb] to keep backward compatibility.
class _DbCore {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'timekeeper.db');
    _db = await openDatabase(
      path,
      version: 2, // v2 adds device_profile table
      onCreate: (db, v) async {
        // v1 tables
        await db.execute('''
          CREATE TABLE job_sites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            address TEXT,
            lat REAL,
            lng REAL
          );
        ''');
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_site_id INTEGER,
            title TEXT NOT NULL,
            notes TEXT,
            status TEXT NOT NULL DEFAULT 'open',
            due_at INTEGER,
            FOREIGN KEY(job_site_id) REFERENCES job_sites(id)
          );
        ''');
        await db.execute('''
          CREATE TABLE time_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER NOT NULL,
            started_at INTEGER NOT NULL,
            ended_at INTEGER,
            duration_sec INTEGER,
            FOREIGN KEY(task_id) REFERENCES tasks(id)
          );
        ''');

        // v2 profile table on brand new installs
        await _createProfileTable(db);
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await _createProfileTable(db);
        }
      },
    );
    return _db!;
  }

  static Future<void> _createProfileTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS device_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        full_name   TEXT,
        email       TEXT,
        phone       TEXT,
        role        TEXT,
        avatar_path TEXT,
        device_label TEXT,
        created_at  INTEGER
      );
    ''');
    await db.insert(
      'device_profile',
      {'id': 1, 'created_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}

/// New name used by the new code
class AppDatabase {
  static Future<Database> instance() => _DbCore.instance();
}

/// Old name preserved so existing imports keep working
class AppDb {
  static Future<Database> instance() => _DbCore.instance();
}
