import 'package:flutter/material.dart';
import 'package:time_keeper/services/manager_mode_service.dart';
import 'package:time_keeper/services/org_service.dart';

/// Optional standalone tile. Uses the new API:
/// - ManagerModeService.isEnabled / setEnabled / unlockWithPin (company-wide PIN).
class ManagerModeTile extends StatefulWidget {
  const ManagerModeTile({super.key});

  @override
  State<ManagerModeTile> createState() => _ManagerModeTileState();
}

class _ManagerModeTileState extends State<ManagerModeTile> {
  final _org = OrgService();
  ManagerModeService? _mgr;
  String? _companyId;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await _org.activeCompanyId();
    if (id == null) return;
    final mgr = ManagerModeService(id);
    final en = await mgr.isEnabled();
    if (!mounted) return;
    setState(() {
      _companyId = id;
      _mgr = mgr;
      _enabled = en;
    });
  }

  Future<void> _toggle() async {
    if (_mgr == null) return;

    if (_enabled) {
      await _mgr!.setEnabled(false);
      if (!mounted) return;
      setState(() => _enabled = false);
      return;
    }

    final pin = await _promptPin('Enter Manager PIN');
    if (pin == null) return;
    final ok = await _mgr!.unlockWithPin(pin);
    if (!mounted) return;
    if (ok) {
      setState(() => _enabled = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Manager Mode enabled')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Wrong PIN')));
    }
  }

  Future<String?> _promptPin(String title) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Manager Mode'),
      subtitle: Text(_enabled ? 'Enabled' : 'Locked (enter PIN)'),
      value: _enabled,
      onChanged: (_) => _toggle(),
    );
  }
}
