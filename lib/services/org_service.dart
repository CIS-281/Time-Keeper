// lib/services/org_service.dart
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:time_keeper/data/app_db.dart';

class OrgService {
  // --- public ---------------------------------------------------------------

  Future<String?> activeCompanyId() async {
    final db = await AppDb.open();
    await _ensureCore(db);
    final r = await db.query('settings', where: 'key=?', whereArgs: ['active_company_id'], limit: 1);
    return r.isEmpty ? null : r.first['val'] as String?;
  }

  Future<void> setActiveCompany(String id) async {
    final db = await AppDb.open();
    await _ensureCore(db);
    await db.insert('settings', {'key': 'active_company_id', 'val': id},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Create a company; creator sets the **company-wide Manager PIN**.
  Future<Map<String, String>> createCompany(String name, {required String managerPin}) async {
    final db = await AppDb.open();
    await _ensureCore(db);
    await _ensureCompany(db);

    final id = _uuid();
    final code = _genCode();
    final now = _now();

    final salt = _salt();
    final hash = _hash(managerPin, salt);

    await db.insert('company', {
      'id': id,
      'name': name,
      'company_code': code,
      'created_utc': now,
      'manager_pin_hash': hash,
      'manager_pin_salt': base64Encode(salt),
    });

    // Creator device profile marked as manager
    await db.insert('device_profile', {
      'company_id': id,
      'role': 'manager',
      'created_utc': now,
    });

    await setActiveCompany(id);
    return {'company_id': id, 'company_code': code};
  }

  /// Join by code; role stored locally (default employee). Returns company_id or null.
  Future<String?> joinCompanyByCode(String code, {String role = 'employee'}) async {
    final db = await AppDb.open();
    await _ensureCore(db);
    await _ensureCompany(db);

    final rows = await db.query('company', where: 'company_code=?', whereArgs: [code], limit: 1);
    if (rows.isEmpty) return null;
    final id = rows.first['id'] as String;

    await db.insert('device_profile', {
      'company_id': id,
      'role': role,
      'created_utc': _now(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await setActiveCompany(id);
    return id;
  }

  /// For Settings list/switch UI
  Future<List<Map<String, String>>> listCompanies() async {
    final db = await AppDb.open();
    await _ensureCompany(db);
    final rows = await db.query('company', orderBy: 'name ASC');
    return rows
        .map((r) => {
      'id': r['id'] as String,
      'name': r['name'] as String,
      'code': (r['company_code'] as String?) ?? '',
    })
        .toList();
  }

  Future<void> switchCompany(String companyId) async {
    final db = await AppDb.open();
    await _ensureCompany(db);
    final x = await db.query('company', where: 'id=?', whereArgs: [companyId], limit: 1);
    if (x.isEmpty) throw StateError('Company not found');
    await setActiveCompany(companyId);
  }

  /// Info for Settings header
  Future<Map<String, String>?> companyInfo(String companyId) async {
    final db = await AppDb.open();
    await _ensureCompany(db);
    final r = await db.query('company', where: 'id=?', whereArgs: [companyId], limit: 1);
    if (r.isEmpty) return null;
    final row = r.first;
    return {
      'id': row['id'] as String,
      'name': row['name'] as String,
      'code': (row['company_code'] as String?) ?? '',
    };
  }

  // --- Manager PIN (company-wide) ------------------------------------------

  Future<bool> verifyManagerPin(String companyId, String pin) async {
    final db = await AppDb.open();
    final r = await db.query('company',
        columns: ['manager_pin_hash', 'manager_pin_salt'],
        where: 'id=?',
        whereArgs: [companyId],
        limit: 1);
    if (r.isEmpty) return false;
    final saltB64 = r.first['manager_pin_salt'] as String?;
    final hash = r.first['manager_pin_hash'] as String?;
    if (saltB64 == null || hash == null) return false;
    final salt = base64Decode(saltB64);
    return _hash(pin, salt) == hash;
  }

  /// Rotate company Manager PIN (requires old PIN).
  Future<void> setManagerPin(String companyId, {required String oldPin, required String newPin}) async {
    if (!await verifyManagerPin(companyId, oldPin)) {
      throw StateError('Old PIN invalid');
    }
    final db = await AppDb.open();
    final salt = _salt();
    final hash = _hash(newPin, salt);
    await db.update(
      'company',
      {'manager_pin_hash': hash, 'manager_pin_salt': base64Encode(salt)},
      where: 'id=?',
      whereArgs: [companyId],
    );
  }

  // --- helpers --------------------------------------------------------------

  Future<void> _ensureCore(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings(
        key TEXT PRIMARY KEY,
        val TEXT
      );
    ''');
  }

  Future<void> _ensureCompany(Database db) async {
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
      CREATE TABLE IF NOT EXISTS device_profile(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id TEXT NOT NULL,
        role TEXT NOT NULL,
        created_utc INTEGER NOT NULL
      );
    ''');
  }

  int _now() => DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

  String _uuid() {
    const a = '0123456789abcdef';
    final r = Random.secure();
    return List.generate(32, (_) => a[r.nextInt(a.length)]).join();
  }

  String _genCode() {
    const a = 'ABCDEFGHJKLMNPQRSTUVWXZY'; // no easily confused chars
    final r = Random.secure();
    return List.generate(6, (_) => a[r.nextInt(a.length)]).join();
  }

  List<int> _salt() => List<int>.generate(16, (_) => Random.secure().nextInt(256));
  String _hash(String pin, List<int> salt) {
    final bytes = <int>[];
    bytes..addAll(utf8.encode(pin))..addAll(salt);
    return sha256.convert(bytes).toString();
  }
}
