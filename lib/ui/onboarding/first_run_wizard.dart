// lib/ui/onboarding/first_run_wizard.dart
import 'package:flutter/material.dart';
import 'package:time_keeper/services/org_service.dart';

class FirstRunWizard extends StatefulWidget {
  const FirstRunWizard({super.key});

  @override
  State<FirstRunWizard> createState() => _FirstRunWizardState();
}

class _FirstRunWizardState extends State<FirstRunWizard> {
  final _org = OrgService();
  final _name = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  final _join = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    _pin2.dispose();
    _join.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return _snack('Enter company name');
    if (_pin.text.length < 4) return _snack('PIN must be at least 4 digits');
    if (_pin.text != _pin2.text) return _snack('PINs do not match');

    setState(() => _busy = true);
    try {
      final res = await _org.createCompany(name, managerPin: _pin.text);
      if (!mounted) return;
      _snack('Company created. Join code: ${res['company_code']!}');
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Failed: $e');
      setState(() => _busy = false);
    }
  }

  Future<void> _joinCompany() async {
    final code = _join.text.trim().toUpperCase();
    if (code.length < 4) return _snack('Enter a valid code');
    setState(() => _busy = true);
    try {
      final id = await _org.joinCompanyByCode(code);
      if (!mounted) return;
      if (id == null) {
        _snack('Code not found on this device');
        setState(() => _busy = false);
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Failed: $e');
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Create Company', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Company name')),
            const SizedBox(height: 8),
            TextField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Manager PIN (shared for all managers)'),
            ),
            TextField(
              controller: _pin2,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Confirm PIN'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _create,
              icon: _busy ? const SizedBox(height:18,width:18,child:CircularProgressIndicator(strokeWidth:2))
                  : const Icon(Icons.factory_outlined),
              label: const Text('Create'),
            ),
            const Divider(height: 40),
            Text('Or join existing', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _join,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Company code'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _joinCompany,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}
