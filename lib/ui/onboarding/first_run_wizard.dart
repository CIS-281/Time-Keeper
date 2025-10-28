// lib/ui/onboarding/first_run_wizard.dart
//
// Simple first-run screen to create or join a company with proper error handling.

import 'package:flutter/material.dart';
import 'package:time_keeper/services/org_service.dart';

class FirstRunWizard extends StatefulWidget {
  const FirstRunWizard({super.key});

  @override
  State<FirstRunWizard> createState() => _FirstRunWizardState();
}

class _FirstRunWizardState extends State<FirstRunWizard> {
  final _org = OrgService();
  final _nameC = TextEditingController();
  final _codeC = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameC.dispose();
    _codeC.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameC.text.trim();
    if (name.isEmpty) {
      _snack('Please enter a company name.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _org.createCompany(name);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Failed to create company: $e');
      setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _codeC.text.trim().toUpperCase();
    if (code.length < 4) {
      _snack('Enter a valid code.');
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await _org.joinCompanyByCode(code);
      if (id == null) {
        _snack('Company code not found.');
        setState(() => _busy = false);
        return;
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack('Failed to join company: $e');
      setState(() => _busy = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Set up your company',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameC,
                decoration: const InputDecoration(
                  labelText: 'Company name',
                  hintText: 'e.g., Old Pueblo Cellars',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.factory_outlined),
                label: _busy
                    ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create Company'),
              ),
              const Divider(height: 40),
              Text(
                'Or join an existing company',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeC,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Company code',
                  hintText: 'Enter 6-letter code',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _join,
                icon: const Icon(Icons.group_add_outlined),
                label: _busy
                    ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Join Company'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
