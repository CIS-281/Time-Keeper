// lib/services/manager_mode_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ManagerModeService {
  final _sec = const FlutterSecureStorage();
  final String companyId;
  ManagerModeService(this.companyId);

  String get _hKey => 'mgr_pin_hash::$companyId';
  String get _sKey => 'mgr_pin_salt::$companyId';
  String get _eKey => 'mgr_mode_enabled::$companyId';

  Future<bool> hasPin() async => (await _sec.read(key: _hKey))?.isNotEmpty == true;

  Future<void> setPin(String pin) async {
    final salt = _rand(16);
    final hash = _hash(pin, salt);
    await _sec.write(key: _hKey, value: hash);
    await _sec.write(key: _sKey, value: base64Encode(salt));
  }

  Future<bool> verifyPin(String pin) async {
    final h = await _sec.read(key: _hKey);
    final s = await _sec.read(key: _sKey);
    if (h == null || s == null) return false;
    return _hash(pin, base64Decode(s)) == h;
  }

  Future<void> setEnabled(bool v) async => _sec.write(key: _eKey, value: v ? '1' : '0');
  Future<bool> isEnabled() async => (await _sec.read(key: _eKey)) == '1';

  // helpers
  List<int> _rand(int n) { final r = Random.secure(); return List.generate(n, (_) => r.nextInt(256)); }
  String _hash(String pin, List<int> salt) {
    final b = <int>[];
    b..addAll(utf8.encode(pin))..addAll(salt);
    return sha256.convert(b).toString();
  }
}
