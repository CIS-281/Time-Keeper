// lib/ui/settings/manager_mode_tile.dart
// Manager Mode toggle (per-company). Requires a PIN.
// Shows: Locked / Enabled. Tapping toggles with PIN prompts.

import 'package:flutter/material.dart';
import 'package:time_keeper/services/manager_mode_service.dart';

class ManagerModeTile extends StatefulWidget {
  final String companyId;
  const ManagerModeTile({super.key, required this.companyId});

  @override
  State<ManagerModeTile> createState() => _ManagerModeTileState();
}

class _ManagerModeTileState extends State<ManagerModeTile> {
  late final ManagerModeService service;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    service = ManagerModeService(widget.companyId);
    _load();
  }

  Future<void> _load() async {
    _enabled = await service.isEnabled();
    setState(() => _loading = false);
  }

  Future<void> _toggle() async {
    final has = await service.hasPin();
    if (!has) {
      // First setup: create PIN
      final pin = await _promptPin(context, title: 'Create Manager PIN');
      final pin2 = await _promptPin(context, title: 'Confirm PIN');
      if (pin == null || pin2 == null || pin != pin2) {
        _snack('PINs did not match.');
        return;
      }
      await service.setPin(pin);
      await service.setEnabled(true);
      setState(() => _enabled = true);
      _snack('Manager Mode enabled');
      return;
    }

    if (_enabled) {
      // Lock
      await service.setEnabled(false);
      setState(() => _enabled = false);
      _snack('Manager Mode locked');
    } else {
      // Unlock with PIN
      final pin = await _promptPin(context, title: 'Enter Manager PIN');
      if (pin != null && await service.verifyPin(pin)) {
        await service.setEnabled(true);
        setState(() => _enabled = true);
        _snack('Manager Mode enabled');
      } else {
        _snack('Invalid PIN');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ListTile(
        title: Text('Manager Mode'),
        trailing: SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
      );
    }
    return ListTile(
      leading: Icon(_enabled ? Icons.verified_user : Icons.lock_outline),
      title: const Text('Manager Mode'),
      subtitle: Text(_enabled ? 'Enabled' : 'Locked'),
      trailing: Switch(value: _enabled, onChanged: (_) => _toggle()),
      onTap: _toggle,
    );
  }

  Future<String?> _promptPin(BuildContext ctx, {required String title}) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(hintText: '6-digit PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}
