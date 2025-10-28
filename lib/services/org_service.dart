// lib/services/org_service.dart
//
// Company / org lifecycle helper.
// Stores the active company in the SQLite `settings` table.
// Provides create/join/switch/list helpers and ensures tables exist.

import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:time_keeper/data/app_db.dart';

class OrgService {
  // ---- public API ----------------------------------------------------------

  /// Returns the active company id, or null if not set yet.
  Future<String?> activeCompanyId() async {
    final db = await AppDb.open();
    await _ensureCoreTables(db);
    final rows = await db.query(
      'settings',
      where: 'key=?',
      whereArgs: ['active_company_id'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['val'] as String?;
  }

  /// Sets the active company id.
  Future<void> setActiveCompany(String companyId) async {
    final db = await AppDb.open();
    await _ensureCoreTables(db);
    await db.insert(
      'settings',
      {'key': 'active_company_id', 'val': companyId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Creates a new company and sets it active. Returns {company_id, company_code}.
  Future<Map<String, String>> createCompany(String name) async {
    final db = await AppDb.open();
    await _ensureCoreTables(db);
    await _ensureCompanyTables(db);

    final id = _uuid();
    final code = _genCompanyCode();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    await db.insert('company', {
      'id': id,
      'name': name,
      'company_code': code,
      'created_utc': now,
    });

    await db.insert('device_profile', {
      'company_id': id,
      'role': 'manager',
      'created_utc': now,
    });

    await setActiveCompany(id);
    return {'company_id': id, 'company_code': code};
  }

  /// Join an existing company by its code. Sets active and stores a local device role.
  /// Returns the company_id or null if not found.
  Future<String?> joinCompanyByCode(String code, {String role = 'employee'}) async {
    final db = await AppDb.open();
    await _ensureCoreTables(db);
    await _ensureCompanyTables(db);

    final rows =
    await db.query('company', where: 'company_code=?', whereArgs: [code], limit: 1);
    if (rows.isEmpty) return null;
    final id = rows.first['id'] as String;

    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    await db.insert(
      'device_profile',
      {'company_id': id, 'role': role, 'created_utc': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await setActiveCompany(id);
    return id;
  }

  /// NEW: Return all companies known on this device (id, name, code).
  Future<List<Map<String, String>>> listCompanies() async {
    final db = await AppDb.open();
    await _ensureCompanyTables(db);
    final rows = await db.query(
      'company',
      columns: ['id', 'name', 'company_code'],
      orderBy: 'name ASC',
    );
    return rows
        .map((r) => {
      'id': r['id'] as String,
      'name': r['name'] as String,
      'code': (r['company_code'] as String?) ?? '',
    })
        .toList();
  }

  /// NEW: Switch the active company by id (throws if not found).
  Future<void> switchCompany(String companyId) async {
    final db = await AppDb.open();
    await _ensureCompanyTables(db);
    final exists = await db.query(
      'company',
      where: 'id=?',
      whereArgs: [companyId],
      limit: 1,
    );
    if (exists.isEmpty) {
      throw StateError('Company not found: $companyId');
    }
    await setActiveCompany(companyId);
  }

  // ---- helpers -------------------------------------------------------------

  Future<void> _ensureCoreTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings(
        key TEXT PRIMARY KEY,
        val TEXT
      );
    ''');
  }

  Future<void> _ensureCompanyTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS company(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        company_code TEXT UNIQUE,
        created_utc INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS device_profile(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id TEXT NOT NULL,
        role TEXT NOT NULL,
        created_utc INTEGER NOT NULL
      );
    ''');
  }

  String _uuid() {
    const alphabet = '0123456789abcdef';
    final r = Random.secure();
    return List.generate(32, (_) => alphabet[r.nextInt(alphabet.length)]).join();
  }

  String _genCompanyCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXZY'; // avoid easily-confused chars
    final r = Random.secure();
    return List.generate(6, (_) => alphabet[r.nextInt(alphabet.length)]).join();
  }
}
