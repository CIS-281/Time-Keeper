// lib/ui/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:time_keeper/services/org_service.dart';
import 'package:time_keeper/services/manager_mode_service.dart';
import 'package:time_keeper/ui/settings/company_switcher_tile.dart';
import 'package:time_keeper/ui/onboarding/first_run_wizard.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _org = OrgService();
  String? _companyId;
  String _companyName = '';
  String _companyCode = '';
  bool _mgrEnabled = false;
  ManagerModeService? _mgr;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await _org.activeCompanyId();
    if (id == null) {
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const FirstRunWizard()));
      if (!mounted) return;
      return _load();
    }
    final info = await _org.companyInfo(id);
    final mgr = ManagerModeService(id);
    final enabled = await mgr.isEnabled();
    setState(() {
      _companyId = id;
      _companyName = info?['name'] ?? '';
      _companyCode = info?['code'] ?? '';
      _mgr = mgr;
      _mgrEnabled = enabled;
    });
  }

  Future<void> _toggleManager() async {
    if (_mgr == null || _companyId == null) return;
    if (_mgrEnabled) {
      await _mgr!.setEnabled(false);
      setState(() => _mgrEnabled = false);
      return;
    }
    final pin = await _promptPin('Enter Manager PIN');
    if (pin == null) return;
    final ok = await _mgr!.unlockWithPin(pin);
    if (!ok) {
      _snack('Wrong PIN');
    } else {
      setState(() => _mgrEnabled = true);
      _snack('Manager Mode enabled');
    }
  }

  Future<void> _createOrJoin() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const FirstRunWizard()));
    if (!mounted) return;
    await _load();
  }

  Future<void> _rotatePin() async {
    if (!_mgrEnabled || _companyId == null) return;
    final oldPin = await _promptPin('Current Manager PIN');
    if (oldPin == null) return;
    final newPin = await _promptPin('New Manager PIN');
    if (newPin == null) return;
    final confirm = await _promptPin('Confirm New PIN');
    if (confirm != newPin) {
      _snack('PINs do not match');
      return;
    }
    try {
      await _org.setManagerPin(_companyId!, oldPin: oldPin, newPin: newPin);
      _snack('Manager PIN updated');
    } catch (e) {
      _snack('Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _companyCode.isEmpty ? '—' : _companyCode;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: Text(_companyName.isEmpty ? 'No company' : _companyName,
                style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text('Join code: $code'),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy join code',
              onPressed: _companyCode.isEmpty
                  ? null
                  : () {
                Clipboard.setData(ClipboardData(text: _companyCode));
                _snack('Code copied');
              },
            ),
          ),
          const Divider(),

          // Manager Mode
          SwitchListTile(
            title: const Text('Manager Mode'),
            subtitle: Text(_mgrEnabled ? 'Enabled' : 'Locked (enter PIN)'),
            value: _mgrEnabled,
            onChanged: (_) => _toggleManager(),
          ),
          ListTile(
            title: const Text('Rotate Manager PIN'),
            subtitle: const Text('Requires Manager Mode'),
            enabled: _mgrEnabled,
            leading: const Icon(Icons.password),
            onTap: _rotatePin,
          ),
          const Divider(),

          // Company switch / create / join
          const CompanySwitcherTile(),
          ListTile(
            leading: const Icon(Icons.factory_outlined),
            title: const Text('Create / Join Company'),
            onTap: _createOrJoin,
          ),
        ],
      ),
    );
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

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}
