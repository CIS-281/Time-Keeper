import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:time_keeper/services/org_service.dart';
import 'package:time_keeper/services/manager_mode_service.dart';
import 'package:time_keeper/ui/settings/company_switcher_tile.dart';
import 'package:time_keeper/ui/onboarding/first_run_wizard.dart';

// ⬇️ NEW imports for profile integration
import 'package:time_keeper/data/repositories/device_profile_repository.dart';
import 'package:time_keeper/ui/settings/profile_settings_page.dart';

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

  // ⬇️ NEW: profile repo + cached fields for display
  final _profileRepo = DeviceProfileRepository();
  String? _profileName;
  String? _profileAvatarPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Load company/org data (unchanged)
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

    // ⬇️ NEW: load device profile for display
    final profile = await _profileRepo.get();

    setState(() {
      _companyId = id;
      _companyName = info?['name'] ?? '';
      _companyCode = info?['code'] ?? '';
      _mgr = mgr;
      _mgrEnabled = enabled;

      _profileName = profile?.fullName;
      _profileAvatarPath = profile?.avatarPath;
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
          // Company header (unchanged)
          ListTile(
            title: Text(
              _companyName.isEmpty ? 'No company' : _companyName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
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

          // ⬇️ NEW: User Profile tile
          ListTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundImage: (_profileAvatarPath != null && _profileAvatarPath!.isNotEmpty)
                  ? FileImage(File(_profileAvatarPath!))
                  : null,
              child: (_profileAvatarPath == null || _profileAvatarPath!.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(_profileName?.isNotEmpty == true ? _profileName! : 'User Profile'),
            subtitle: const Text('Edit name, role, device & avatar'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
              );
              if (!mounted) return;
              // Refresh the preview after returning from editor
              final profile = await _profileRepo.get();
              setState(() {
                _profileName = profile?.fullName;
                _profileAvatarPath = profile?.avatarPath;
              });
            },
          ),
          const Divider(),

          // Manager Mode (unchanged)
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

          // Company switch / create / join (unchanged)
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
